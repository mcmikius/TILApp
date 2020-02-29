//
//  Acronym+Model.swift
//  App
//
//  Created by Mykhailo Bondarenko on 29.02.2020.
//

import FluentSQLite

extension Acronym: Model {
    typealias Database = SQLiteDatabase
    
    typealias ID = Int
    
    static let idKey: IDKey = \Acronym.id
    
    
}
