import Vapor
import FluentSQLite
import FluentMySQL
import FluentPostgreSQL

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {

    /// Register providers first
    try services.register(FluentSQLiteProvider())
    try services.register(FluentMySQLProvider())
    try services.register(FluentPostgreSQLProvider())

    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    // Register commands.
    var commandConfig = CommandConfig.default()
    try setupCommands(config: &commandConfig)
    services.register(commandConfig)

    /// Register middlewares.
    var middlewareConfig = MiddlewareConfig()
    try setupMiddlewares(config: &middlewareConfig)
    services.register(middlewareConfig)

    /// Register databases.
    var databasesConfig = DatabasesConfig()
    try setupDatabases(config: &databasesConfig, env: &env)
    services.register(databasesConfig)


    /// Configure migrations
    var migrationConfig = MigrationConfig()
    try setupMigrations(config: &migrationConfig)
    services.register(migrationConfig)

}
