//
//  Model.swift
//  WebSocketPractice
//
//  Created by User on 26/11/2021.
//

import Foundation
import Combine
import UIKit

class PayloadModel {
    
    private var subscripions = Set<AnyCancellable>()
    
    var latestTimeStamp: Date?
    
    lazy var payloadPublisher: AnyPublisher<Payload, Never> = {
        let subject = PassthroughSubject<Payload, Never>()
        self.addNotificationObservers()
        
        WebSocketService.shared.messagePublisher
            .compactMap{ msg -> Data? in
                switch msg {
                case .data(let data):
                    return data
                case .string(let text):
                    return text.data(using: .utf8)
                @unknown default:
                    return nil
                }
            }
            .decode(type: Response<Payload>.self, decoder: JSONDecoder())
            .sink { error in
                print(error)
            } receiveValue: { [weak self, weak subject] response in
                self?.latestTimeStamp = Date()
                subject?.send(response.data)
            }
            .store(in: &subscripions)
        
        WebSocketService.shared.connect()
        return subject.eraseToAnyPublisher()
    }()
    
    private func addNotificationObservers() {
        
        NotificationCenter.default.publisher(for: UIScene.willEnterForegroundNotification, object: nil)
            .sink { _ in
                WebSocketService.shared.connect()
            }
            .store(in: &subscripions)
        
        NotificationCenter.default.publisher(for: UIScene.didEnterBackgroundNotification, object: nil)
            .sink { _ in
                WebSocketService.shared.disConnect()
            }
            .store(in: &subscripions)
        
        NotificationCenter.default.publisher(for: UIScene.didDisconnectNotification, object: nil)
            .sink { _ in
                WebSocketService.shared.disConnect()
            }
            .store(in: &subscripions)
    }
}
