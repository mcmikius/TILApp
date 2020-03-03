//
//  Token.swift
//  App
//
//  Created by Mykhailo Bondarenko on 03.03.2020.
//

import Foundation
import Vapor
import FluentMySQL
import Crypto

final class Token: Codable {
    var id: UUID?
    var token: String
    var userID: User.ID
    
    init(token: String, userID: User.ID) {
        self.token = token
        self.userID = userID
    }
}

extension Token: MySQLUUIDModel {}
extension Token: Content {}
extension Token: Migration {}

extension Token {
    var user: Parent<Token, User> {
        return parent(\.userID)
    }
}

extension Token {
    static func generate(for user: User) throws -> Token {
        let random = try CryptoRandom().generateData(count: 16)
        return try Token(token: random.base64EncodedString(), userID: user.requireID())
    }
}
