//
//  WebSocketService.swift
//  WebSocketPractice
//
//  Created by User on 26/11/2021.
//

import Foundation
import Combine

class WebSocketService {
    static let shared = WebSocketService(
        urlPath: "wss://stream.yshyqxx.com/stream?streams=btcusdt@trade"
    )
    
    private var url: URL?
    
    private var delegate: SocketDelegate?
    
    private var workingQueue: OperationQueue?
    
    private weak var webSocket: URLSessionWebSocketTask?
    
    var isConnecting: Bool {
        return webSocket != nil
    }
    
    var errorPassSubject = PassthroughSubject<Error, Never>()
    var errorHandler: AnyPublisher<Error, Never> {
        return errorPassSubject.eraseToAnyPublisher()
    }
    
    private var messagePassSubject = PassthroughSubject<URLSessionWebSocketTask.Message, Never>()
    var messagePublisher: AnyPublisher<URLSessionWebSocketTask.Message, Never> {
        return messagePassSubject.eraseToAnyPublisher()
    }
    
    private var pingTimerSubscription: AnyCancellable?
    
    private init(urlPath: String) {
        guard let url = URL(string: urlPath) else { return }
        
        let delegate = SocketDelegate().then {
            $0.setOpenHandler { session, task, `protocol` in
                print("OPEN")
            }
            
            $0.setCloseHandler { session, task, closeCode, reason in
                print("CLOSE")
            }
        }
        let workingQueue = OperationQueue().then{ $0.maxConcurrentOperationCount = 1 }
        
        self.url = url
        self.delegate = delegate
        self.workingQueue = workingQueue
    }
    
    //MARK: Public Method
    func connect() {
        self.workingQueue?.addOperation {
            guard !self.isConnecting else { return }
            
            self.webSocket = self.createWebSocket()?.then{ $0.resume() }
            
                //setup timer ping every 5 minutes.
            DispatchQueue.global().async {
                self.pingTimerSubscription = Timer.publish(every: 300, tolerance: nil, on: RunLoop.main, in: .default, options: nil)
                    .autoconnect()
                    .sink { [weak self] _ in
                        self?.ping()
                    }
            }
            
            self.receive()
        }
    }
    
    func disConnect() {
        workingQueue?.addOperation {
            self.webSocket?.cancel(with: .goingAway, reason: nil)
        }
    }
    
    //MARK: Private Method
    private func receive() {
        self.workingQueue?.addOperation {
            self.webSocket?.receive(completionHandler: { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let msg):
                    self.messagePassSubject.send(msg)
                case .failure(let err):
                    self.errorPassSubject.send(err)
                    self.webSocket?.cancel(with: .invalidFramePayloadData, reason: nil)
                }
                self.receive()
            })
        }
    }
    
    private func ping() {
        self.workingQueue?.addOperation {
            print("PING")
            self.webSocket?.sendPing(pongReceiveHandler: { [weak self] error in
                if let self = self, let error = error {
                    self.errorPassSubject.send(error)
                }
            })
        }
    }
    
    private func createWebSocket() -> URLSessionWebSocketTask? {
        guard let url = url,
              let delegate = delegate,
              let workingQueue = workingQueue else {
                  return nil
              }
        
        return URLSession(
            configuration: .default,
            delegate: delegate,
            delegateQueue: workingQueue).webSocketTask(with: url)
    }
}

private class SocketDelegate: NSObject, URLSessionWebSocketDelegate {
    typealias WebSocketOpenHandler = (_ session: URLSession, _ task: URLSessionWebSocketTask, _ `protocol`: String?) -> Void
    typealias WebSocketCloseHandler = (_ session: URLSession, _ task: URLSessionWebSocketTask, _ closeCode: URLSessionWebSocketTask.CloseCode, _ reason: Data?) -> Void
    
    private var openHandler: WebSocketOpenHandler?
    private var closeHandler: WebSocketCloseHandler?
    
    func setOpenHandler(_ handler: WebSocketOpenHandler?) {
        openHandler = handler
    }
    func setCloseHandler(_ handler: WebSocketCloseHandler?) {
        closeHandler = handler
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        openHandler?(session, webSocketTask, `protocol`)
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        closeHandler?(session, webSocketTask, closeCode, reason)
    }
}
