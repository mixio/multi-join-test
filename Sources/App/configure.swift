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

    // Commands.
    var commandConfig = CommandConfig.default()
    commandConfig.useFluentCommands()
    services.register(commandConfig)

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    /// middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    // Configure a SQLite database
    //let sqlite = try SQLiteDatabase(storage: .memory)
    let databaseFilepath: String
    let dirConfig = DirectoryConfig.detect()
    if env == .testing {
        databaseFilepath = dirConfig.workDir + "db_test.sqlite"
    } else {
        databaseFilepath = dirConfig.workDir + "db.sqlite"
    }

    let sqlite = try SQLiteDatabase(storage: .file(path: databaseFilepath))

    // $ docker container run --rm -d \
    //       -e MYSQL_ROOT_PASSWORD=root_password \
    //       -e MYSQL_DATABASE=vapor \
    //       -p 43306:3306 \
    //       --name mysql \
    //       mysql:5.7
    
    let mysql = MySQLDatabase(config: MySQLDatabaseConfig(hostname: "localhost",
                                                          port: 3306,
                                                          username: "vapor",
                                                          password: "password",
                                                          database: "vapor"))

    /// Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: sqlite, as: .sqlite)
    databases.add(database: mysql, as: .mysql)
    databases.enableLogging(on: .sqlite)
    databases.enableLogging(on: .mysql)
    services.register(databases)

    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: PersonSQLite.self, database: .sqlite)
    migrations.add(model: MessageSQLite.self, database: .sqlite)
    migrations.add(model: PersonMySQL.self, database: .mysql)
    migrations.add(model: MessageMySQL.self, database: .mysql)
    services.register(migrations)

}
