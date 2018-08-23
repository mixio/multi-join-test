//
//  Array+toDictionary.swift
//  AppTests
//
//  Created by jj on 23/08/2018.
//

import Foundation

extension Array {
    func toDictionary<K,V>() -> [K:V] where Iterator.Element == (K,V) {
        return self.reduce([:]) {
            var dict:[K:V] = $0
            dict[$1.0] = $1.1
            return dict
        }
    }
}
