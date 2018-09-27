//
//  migrate.swift
//  App
//
//  Created by jj on 26/09/2018.
//

import Vapor
import FluentSQLite
import FluentMySQL
import FluentPostgreSQL

public func setupMigrations(config: inout MigrationConfig) throws {
    config.add(model: PersonSQLite.self, database: .sqlite)
    config.add(model: MessageSQLite.self, database: .sqlite)
    config.add(model: PersonMySQL.self, database: .mysql)
    config.add(model: MessageMySQL.self, database: .mysql)
    config.add(model: PersonPostgreSQL.self, database: .psql)
    config.add(model: MessagePostgreSQL.self, database: .psql)
}
