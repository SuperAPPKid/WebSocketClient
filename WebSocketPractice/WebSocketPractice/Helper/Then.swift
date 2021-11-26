//
//  Then.swift
//  WebSocketPractice
//
//  Created by User on 26/11/2021.
//

import Foundation

protocol Then {}

extension Then where Self: AnyObject {
    func then(_ block: (Self) -> Void) -> Self {
        block(self)
        return self
    }
}

extension Then where Self: Any {
    func reform(_ block: (inout Self) -> Void) -> Self {
        var copy = self
        block(&copy)
        return copy
    }
}

extension NSObject: Then {}
