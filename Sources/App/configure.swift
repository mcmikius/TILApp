import FluentMySQL
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    // Register providers first
    try services.register(FluentMySQLProvider())
//    try services.register(FluentSQLiteProvider())

    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    // middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    // Configure a SQLite database
    let databaseConfig = MySQLDatabaseConfig(hostname: "localhost", username: "til", password: "password", database: "vapor")
    let database = MySQLDatabase(config: databaseConfig)
//    let sqlite = try SQLiteDatabase(storage: .memory)

    // Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: database, as: .mysql)
//    databases.add(database: sqlite, as: .sqlite)
    services.register(databases)

    // Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: Acronym.self, database: .mysql)
    migrations.add(model: User.self, database: .mysql)
    migrations.add(model: Category.self, database: .mysql)
    migrations.add(model: AcronymCategoryPivot.self, database: .mysql)
    services.register(migrations)
}
