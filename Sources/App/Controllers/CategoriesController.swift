//
//  CategoriesController.swift
//  App
//
//  Created by Mykhailo Bondarenko on 29.02.2020.
//

import Foundation
import Vapor

struct CategoriesController: RouteCollection {
    func boot(router: Router) throws {
        let acronymsRoute = router.grouped("api", "categories")
        acronymsRoute.get(use: getAllHandler)
        acronymsRoute.post(use: createHandler)
        acronymsRoute.get(Category.parameter, use: getHandler)
        acronymsRoute.get(Category.parameter, "acronyms", use: getAcronymsHandler)
    }
    
    func getAllHandler(_ req: Request) throws -> Future<[Category]> {
        return Category.query(on: req).all()
    }
    
    func createHandler(_ req: Request) throws -> Future<Category> {
        return try req.content.decode(Category.self).save(on: req)
    }
    
    func getHandler(_ req: Request) throws -> Future<Category> {
        return try req.parameters.next(Category.self)
    }
    
    func getAcronymsHandler(_ req: Request) throws -> Future<[Acronym]> {
        return try req.parameters.next(Category.self).flatMap(to: [Acronym].self, { (category) in
            return try category.acronyms.query(on: req).all()
        })
    }
}
