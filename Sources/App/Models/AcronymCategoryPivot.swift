//
//  AcronymCategoryPivot.swift
//  App
//
//  Created by Mykhailo Bondarenko on 29.02.2020.
//

import Foundation
//import FluentSQLite
import FluentMySQL
import Vapor

final class AcronymCategoryPivot: MySQLUUIDPivot {
    var id: UUID?
    var acronymID: Acronym.ID
    var categoryID: Category.ID
    
    typealias Left = Acronym
    typealias Right = Category
    
    static var leftIDKey: LeftIDKey = \AcronymCategoryPivot.acronymID
    static var rightIDKey: RightIDKey = \AcronymCategoryPivot.categoryID
    
    init(_ acronymID: Acronym.ID, _ categoryID: Category.ID) {
        self.acronymID = acronymID
        self.categoryID = categoryID
    }
}

extension AcronymCategoryPivot: Migration {}
