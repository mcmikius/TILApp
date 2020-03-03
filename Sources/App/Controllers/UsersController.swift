//
//  UsersController.swift
//  App
//
//  Created by Mykhailo Bondarenko on 29.02.2020.
//

import Foundation
import Vapor
import Crypto


struct UsersController: RouteCollection {
    
    func boot(router: Router) throws {
        let usersRoutes = router.grouped("api", "users")
        usersRoutes.get(use: getAllHandler)
        usersRoutes.post(User.self, use: createHandler)
        usersRoutes.get(User.parameter, use: getHandler)
        usersRoutes.get(User.parameter, "acronyms", use: getAcronymsHandler)
        
        let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
        let basicAuthGroup = usersRoutes.grouped(basicAuthMiddleware)
        basicAuthGroup.post("login", use: loginHandler)
    }
    
    func getAllHandler(_ req: Request) throws -> Future<[User.Public]> {
        return User.query(on: req).decode(data: User.Public.self).all()
    }
    
    func createHandler(_ req: Request, user: User) throws -> Future<User.Public> {
        user.password = try BCrypt.hash(user.password)
        return user.save(on: req).convertToPublic()
    }
    
    func getHandler(_ req: Request) throws -> Future<User.Public> {
        return try req.parameters.next(User.self).convertToPublic()
    }
    
    func getAcronymsHandler(_ req: Request) throws -> Future<[Acronym]> {
        return try req.parameters.next(User.self).flatMap(to: [Acronym].self, { (user) in
            return try user.acronyms.query(on: req).all()
        })
    }
    
    func loginHandler(_ req: Request) throws -> Future<Token> {
        let user = try req.requireAuthenticated(User.self)
        let token = try Token.generate(for: user)
        return token.save(on: req)
    }
}
