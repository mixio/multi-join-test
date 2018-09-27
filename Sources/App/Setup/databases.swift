//
//  databases.swift
//  App
//
//  Created by jj on 26/09/2018.
//

import FluentSQLite
import FluentMySQL
import FluentPostgreSQL

public func setupDatabases(config: inout DatabasesConfig, env: inout Environment) throws {
    
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

    let mysql = MySQLDatabase(
        config: MySQLDatabaseConfig(
            hostname: "localhost",
            port: 3306,
            username: "vapor",
            password: "password",
            database: "vapor_test"
        )
    )

    let psql = PostgreSQLDatabase(
        config: PostgreSQLDatabaseConfig(
            hostname: "localhost",
            port: 5432,
            username: "jj",
            database: "vapor_test",
            password: "jkljojojo"
        )
    )

    config.add(database: sqlite, as: .sqlite)
    config.add(database: mysql, as: .mysql)
    config.add(database: psql, as: .psql)

    config.enableLogging(on: .sqlite)
    config.enableLogging(on: .mysql)
    config.enableLogging(on: .psql)

}
