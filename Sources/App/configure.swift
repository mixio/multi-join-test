import FluentSQLite
import FluentMySQL
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// Register providers first
    try services.register(FluentSQLiteProvider())
    try services.register(FluentMySQLProvider())

    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    /// middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    // Configure a SQLite database
    let sqlite = try SQLiteDatabase(storage: .memory)
    
    
    // $ docker container run --rm -d \
    //       -e MYSQL_ROOT_PASSWORD=root_password \
    //       -e MYSQL_DATABASE=vapor \
    //       -p 43306:3306 \
    //       --name mysql \
    //       mysql:5.7
    
    let mysql = MySQLDatabase(config: MySQLDatabaseConfig(hostname: "localhost",
                                                          port: 43306,
                                                          username: "root",
                                                          password: "root_password",
                                                          database: "vapor"))

    /// Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: sqlite, as: .sqlite)
    databases.add(database: mysql, as: .mysql)
    services.register(databases)

    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: Person.self, database: .sqlite)
    migrations.add(model: Message.self, database: .sqlite)
    migrations.add(model: PersonMySQL.self, database: .mysql)
    migrations.add(model: MessageMySQL.self, database: .mysql)
    services.register(migrations)

}
