//
//  WebsiteController.swift
//  App
//
//  Created by Mykhailo Bondarenko on 02.03.2020.
//

import Foundation
import Vapor
import Authentication

struct WebsiteController: RouteCollection {
    func boot(router: Router) throws {
        let authSessionRoutes = router.grouped(User.authSessionsMiddleware())
        authSessionRoutes.get(use: indexHandler)
        authSessionRoutes.get("acronyms", Acronym.parameter, use: acronymHandler)
        authSessionRoutes.get("users", User.parameter, use: userHandler)
        authSessionRoutes.get("users", use: allUsersHandler)
        authSessionRoutes.get("categories", Category.parameter, use: categoryHandler)
        authSessionRoutes.get("categories", use: allCategoriesHandler)
        authSessionRoutes.get("login", use: loginHandler)
        authSessionRoutes.post("login", use: loginPostHandler)
        
        let protectedRoutes = authSessionRoutes.grouped(RedirectMiddleware<User>(path: "/login"))
        protectedRoutes.get("acronyms", "create", use: createAcronymHandler)
        protectedRoutes.post(CreateAcronymData.self, at: "acronyms", "create", use: createAcronymPostHandler)
        protectedRoutes.get("acronyms", Acronym.parameter, "edit", use: editAcronymHandler)
        protectedRoutes.post("acronyms", Acronym.parameter, "edit", use: editAcronymPostHandler)
        protectedRoutes.post("acronyms", Acronym.parameter, "delete", use: deleteHandler)
    }
    
    func indexHandler(_ req: Request) throws -> Future<View> {
        return Acronym.query(on: req).all().flatMap(to: View.self) { (acronyms) in
            let context = IndexContext(title: "Homepage", acronyms: acronyms)
            return try req.view().render("index", context)
        }
    }
    
    func acronymHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(Acronym.self).flatMap(to: View.self, { acronym in
            return acronym.user.get(on: req).flatMap(to: View.self) { (user) in
                let context = try AcronymContext(title: acronym.long, acronym: acronym, user: user, categories: acronym.categories.query(on: req).all())
                return try req.view().render("acronym", context)
            }
        })
    }
    
    func userHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(User.self).flatMap(to: View.self, { user in
            let context = try UserContext(title: user.name, user: user, acronyms: user.acronyms.query(on: req).all())
            return try req.view().render("user", context)
        })
    }
    
    func allUsersHandler(_ req: Request) throws -> Future<View> {
        let context = AllUsersContext(users: User.query(on: req).all())
        return try req.view().render("allUsers", context)
    }
    
    func categoryHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(Category.self).flatMap(to: View.self, { category in
            let context = try CategoryContext(title: category.name, category: category, acronyms: category.acronyms.query(on: req).all())
            return try req.view().render("category", context)
        })
    }
    
    func allCategoriesHandler(_ req: Request) throws -> Future<View> {
        let context = AllCategoriesContext(categories: Category.query(on: req).all())
        return try req.view().render("allCategories", context)
    }
    
    func createAcronymHandler(_ req: Request) throws -> Future<View> {
        let context = CreateAcronymContext()
        return try req.view().render("createAcronym", context)
    }
    
    func createAcronymPostHandler(_ req: Request, acronym: CreateAcronymData) throws -> Future<Response> {
        let user = try req.requireAuthenticated(User.self)
        let acronym = Acronym(short: acronym.short, long: acronym.long, userID: try user.requireID())
        return acronym.save(on: req).map(to: Response.self) { acronym in
          guard let id = acronym.id else {
            return req.redirect(to: "/")
          }
          return req.redirect(to: "/acronyms/\(id)")
        }
    }
    
    func editAcronymHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(Acronym.self).flatMap(to: View.self) { acronym in
            let context = EditAcronymContext(title: "Edit Acronym", acronym: acronym)
            return try req.view().render("createAcronym", context)
        }
    }
    
    func editAcronymPostHandler(_ req: Request) throws -> Future<Response> {
        return try req.parameters.next(Acronym.self).flatMap(to: Response.self, { (acronym) in
            let updateAcronym = try req.content.syncDecode(CreateAcronymData.self)
            acronym.short = updateAcronym.short
            acronym.long = updateAcronym.long
            let user = try req.requireAuthenticated(User.self)
            acronym.userID = try user.requireID()
            
            return acronym.save(on: req).map(to: Response.self, { (savedAcronym) in
                guard let id = acronym.id else {
                  return req.redirect(to: "/")
                }
                return req.redirect(to: "/acronyms/\(id)")
            })
        })
    }
    
    func deleteHandler(_ req: Request) throws -> Future<Response> {
        return try req.parameters.next(Acronym.self).flatMap(to: Response.self, { (acronym) in
            return acronym.delete(on: req).transform(to: req.redirect(to: "/"))
        })
    }
    
    func loginHandler(_ req: Request) throws -> Future<View> {
        let context = LoginContext()
        return try req.view().render("login", context)
    }
    
    func loginPostHandler(_ req: Request) throws -> Future<Response> {
        let loginData = try req.content.syncDecode(LoginPostData.self)
        return User.authenticate(username: loginData.username, password: loginData.password, using: BCryptDigest(), on: req).map(to: Response.self) { (user) in
            guard let user = user else {
                return req.redirect(to: "/login")
            }
            try req.authenticateSession(user)
            return req.redirect(to: "/")
        }
    }
}

struct IndexContext: Encodable {
    let title: String
    let acronyms: [Acronym]?
}

struct AcronymContext: Encodable {
    let title: String
    let acronym: Acronym
    let user: User
    let categories: Future<[Category]>
}

struct UserContext: Encodable {
    let title: String
    let user: User
    let acronyms: Future<[Acronym]>
}

struct AllUsersContext: Encodable {
    let title: String = "All Users"
    let users: Future<[User]>
}

struct CategoryContext: Encodable {
    let title: String
    let category: Category
    let acronyms: Future<[Acronym]>
}

struct AllCategoriesContext: Encodable {
    let title: String = "All Categories"
    let categories: Future<[Category]>
}

struct CreateAcronymContext: Encodable {
    let title: String = "Create An Acronym"
    
}

struct EditAcronymContext: Encodable {
    let title: String
    let acronym: Acronym
    let editing: Bool = true
}

struct CreateAcronymData: Content {
    let short: String
    let long: String
}

struct LoginContext: Encodable {
    let title = "Log In"
}

struct LoginPostData: Content {
    let username: String
    let password: String
}
