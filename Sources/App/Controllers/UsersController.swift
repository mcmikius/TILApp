//
//  UsersController.swift
//  App
//
//  Created by Mykhailo Bondarenko on 29.02.2020.
//

import Foundation
import Vapor

struct UsersController: RouteCollection {
    func boot(router: Router) throws {
        let acronymsRoute = router.grouped("api", "users")
        acronymsRoute.get(use: getAllHandler)
        acronymsRoute.post(User.self, use: createHandler)
        acronymsRoute.get(User.parameter, use: getHandler)
        acronymsRoute.get(User.parameter, "acronyms", use: getAcronymsHandler)
    }
    
    func getAllHandler(_ req: Request) throws -> Future<[User]> {
        return User.query(on: req).all()
    }
    
    func createHandler(_ req: Request, user: User) throws -> Future<User> {
        return user.save(on: req)
    }
    
    func getHandler(_ req: Request) throws -> Future<User> {
        return try req.parameters.next(User.self)
    }
    
    func getAcronymsHandler(_ req: Request) throws -> Future<[Acronym]> {
        return try req.parameters.next(User.self).flatMap(to: [Acronym].self, { (user) in
            return try user.acronyms.query(on: req).all()
        })
    }
}
