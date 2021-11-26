//
//  ViewController.swift
//  WebSocketPractice
//
//  Created by User on 26/11/2021.
//

import UIKit
import Combine
import SnapKit

private let timeFormatter = DateFormatter().then {
    $0.dateFormat = "HH:mm:ss"
}

class MainViewController: UIViewController {
    
    private var subscriptions = Set<AnyCancellable>()
    
    private let header = Header()
    
    private let tableView = UITableView(frame: .zero, style: .plain).then{ $0.allowsSelection = false }
    
    private let refreshTimeLabel = UILabel().then {
        $0.font = .boldSystemFont(ofSize: 14)
        $0.textAlignment = .center
        $0.numberOfLines = 1
    }
    
    private let model = PayloadModel()
    
    private var payloads = [Payload]()
    private let payloadProcessQueue = OperationQueue().then{ $0.maxConcurrentOperationCount = 1 }
    
    private let refreshTime = TimeInterval(5)
    private let maxRows = 40
    
    private var uiUsedTimeStamp: Date?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        tableView.delegate = self
        tableView.dataSource = self
        
        let vStack = UIStackView(arrangedSubviews: [header, tableView, refreshTimeLabel])
            .then {
                $0.spacing = 0
                $0.axis = .vertical
            }
        
        view.addSubview(vStack)
        vStack.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        addSubscriptions()
    }
    
    private func addSubscriptions() {
        model.payloadPublisher
            .receive(on: payloadProcessQueue, options: nil)
            .sink { [weak self] payload in
                guard let self = self else { return }
                
                if self.payloads.count < self.maxRows {
                    let dataTimeStamp = self.model.latestTimeStamp
                    self.payloads.insert(payload, at: 0)
                    
                    DispatchQueue.main.async {
                        self.uiUsedTimeStamp = dataTimeStamp
                        self.updateUI()
                    }
                } else {
                    self.payloads = [payload] + self.payloads[0 ..< (self.maxRows - 1)]
                }
            }
            .store(in: &subscriptions)
        
        Timer.publish(every: refreshTime, tolerance: nil, on: .main, in: .default, options: nil)
            .autoconnect()
            .sink { [weak self] date in
                guard let self = self else { return }
                guard self.model.latestTimeStamp != self.uiUsedTimeStamp else { return }
                
                self.uiUsedTimeStamp = self.model.latestTimeStamp
                self.updateUI()
            }
            .store(in: &subscriptions)
    }
    
    private func updateUI() {
        if let uiUsedTimeStamp = uiUsedTimeStamp {
            self.refreshTimeLabel.text = "last update: " + timeFormatter.string(from: uiUsedTimeStamp)
        } else {
            self.refreshTimeLabel.text = "last update: ???"
        }
        self.tableView.reloadData()
    }
}

//MARK: UITableViewDataSource & UITableViewDelegate
extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return payloads.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: Cell
        
        if let dequedCell = tableView.dequeueReusableCell(withIdentifier: "cell") as? Cell {
            cell = dequedCell
        } else {
            cell = .init(style: .default, reuseIdentifier: "cell")
        }
        
        cell.updateUI(usingPayload: payloads[indexPath.row])
        
        return cell
    }
}


//MARK: Child Views
private class Header: UIView {
    
    private let timeLabel = UILabel().then {
        $0.minimumScaleFactor = 0.1
        $0.adjustsFontSizeToFitWidth = true
        $0.numberOfLines = 1
        $0.textAlignment = .left
        $0.text = "時間"
    }
    
    private let priceLabel = UILabel().then {
        $0.minimumScaleFactor = 0.1
        $0.adjustsFontSizeToFitWidth = true
        $0.numberOfLines = 1
        $0.textAlignment = .center
        $0.text = "價格"
    }
    
    private let quantityLabel = UILabel().then {
        $0.minimumScaleFactor = 0.1
        $0.adjustsFontSizeToFitWidth = true
        $0.numberOfLines = 1
        $0.textAlignment = .right
        $0.text = "數量"
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor(white: 0.98, alpha: 1)
        
        let hStack = UIStackView(arrangedSubviews: [timeLabel, priceLabel, quantityLabel])
            .then {
                $0.axis = .horizontal
                $0.distribution = .fillEqually
                $0.spacing = 5
            }
        
        addSubview(hStack)
        hStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class Cell: UITableViewCell {
    override var textLabel: UILabel? { return nil }
    override var imageView: UIImageView? { return nil }
    
    private let timeLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12)
        $0.numberOfLines = 1
        $0.textAlignment = .left
    }
    
    private let priceLabel = UILabel().then {
        $0.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .medium)
        $0.numberOfLines = 1
        $0.textAlignment = .center
    }
    
    private let quantityLabel = UILabel().then {
        $0.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .medium)
        $0.numberOfLines = 1
        $0.textAlignment = .right
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        separatorInset = .zero
        
        let hStack = UIStackView(arrangedSubviews: [timeLabel, priceLabel, quantityLabel])
            .then {
                $0.axis = .horizontal
                $0.distribution = .fillEqually
                $0.spacing = 5
            }
        
        contentView.addSubview(hStack)
        hStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateUI(usingPayload payload: Payload) {
        timeLabel.text = timeFormatter.string(from: .init(timeIntervalSince1970: payload.tradeFinishTime / 1000))
        priceLabel.text = payload.tradePrice
        quantityLabel.text = payload.tradeQuantity
    }
}

