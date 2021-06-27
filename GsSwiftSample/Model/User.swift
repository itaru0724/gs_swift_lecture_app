//
//  User.swift
//  GsSwiftSample
//
//  Created by Yuki Shinohara on 2021/06/19.
//

import Foundation
import UIKit

struct User: Equatable {
    let id: String
    let name: String
    let photoURL: String?
    
    static func ==(lhs: User, rhs: User) -> Bool{
        return lhs.id == rhs.id
    }
}
