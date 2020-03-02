//
//  WebsiteController.swift
//  App
//
//  Created by Mykhailo Bondarenko on 02.03.2020.
//

import Foundation
import Vapor

struct WebsiteController: RouteCollection {
    func boot(router: Router) throws {
        router.get(use: indexHandler)
        router.get("acronyms", Acronym.parameter, use: acronymHandler)
        router.get("users", User.parameter, use: userHandler)
        router.get("users", use: allUsersHandler)
        router.get("categories", Category.parameter, use: categoryHandler)
        router.get("categories", use: allCategoriesHandler)
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
