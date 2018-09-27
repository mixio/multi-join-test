//
//  PostgreSQLTests.swift
//  App
//
//  Created by jj on 28/08/2018.
//

@testable import App
import Vapor
import FluentPostgreSQL
import XCTest
import JJTools

final class PostgreSQLTests: XCTestCase {

    var app: Application!
    var psqlConn: PostgreSQLConnection!
    var req: Request!

    override func setUp() {
        try! Application.reset()
        app = try! Application.testable()
        req = Request(using: app)
        psqlConn = try! app.newConnection(to: .psql).wait()
    }

    override func tearDown() {
        psqlConn.close()
    }


    func testPostgreSQLWithTableAliases() throws {
        typealias Message = MessagePostgreSQL
        typealias Person = PersonPostgreSQL
        let conn = psqlConn!

        // Insert data
        let person1 = try Person(name: "Person 1").save(on: conn).wait()
        let person2 = try Person(name: "Person 2").save(on: conn).wait()
        let message = try Message(
            from_person_id: person1.requireID(),
            to_person_id: person2.requireID(),
            body: "Bla bla bla"
            ).save(on: conn).wait()

        // Fetch
        do {
            let result = try conn.raw(
                """
                SELECT * FROM messages
                JOIN persons AS from_persons ON messages.from_person_id = from_persons.id
                JOIN persons AS to_persons ON messages.to_person_id = to_persons.id
                WHERE messages.id=$1
                """
                )
                .bind(message.requireID())
                .all()
                .map { rows in
                    try rows.map { row -> (Message, Person, Person) in
                        // Using table aliases.
                        let msg = try conn.decode(Message.self, from: row, table: "messages")
                        let from = try conn.decode(Person.self, from: row, table: "from_persons")
                        let to = try conn.decode(Person.self, from: row, table: "to_persons")
                        return (msg, from, to)
                    }
                }.wait()
            XCTAssertEqual(result[0].0, message)
            XCTAssertEqual(result[0].1, person1)
            XCTAssertEqual(result[0].2, person2)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }
}
