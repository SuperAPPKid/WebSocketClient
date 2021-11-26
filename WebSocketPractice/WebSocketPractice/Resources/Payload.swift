//
//  Payload.swift
//  WebSocketPractice
//
//  Created by User on 26/11/2021.
//

import Foundation

struct Response<D: Decodable>: Decodable {
    let data: D
}

struct Payload: Decodable {
    enum CodingKeys: String, CodingKey {
        case tradeType = "e"
        case tradePair = "s"
        case tradeID = "t"
        case tradePrice = "p"
        case tradeQuantity = "q"
        case buyerID = "b"
        case sellerID = "a"
        case tradeStartTime = "E"
        case tradeFinishTime = "T"
        case isBuyerPower = "m"
    }
    
    let tradeType: String
    let tradePair: String
    let tradeID: Int
    let tradePrice: String
    let tradeQuantity: String
    let buyerID: Int
    let sellerID: Int
    let tradeStartTime: TimeInterval
    let tradeFinishTime: TimeInterval
    let isBuyerPower: Bool
}
