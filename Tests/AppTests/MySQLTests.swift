@testable import App
import Vapor
import FluentSQLite
import FluentMySQL
import XCTest
import JJTools

final class MySQLTests: XCTestCase {

    var app: Application!
    var mysqlConn: MySQLConnection!
    var req: Request!

    override func setUp() {
        try! Application.reset()
        app = try! Application.testable()
        req = Request(using: app)
        mysqlConn = try! app.newConnection(to: .mysql).wait()
    }

    override func tearDown() {
        mysqlConn.close()
    }


    func testMySQL() throws {
        typealias Message = MessageMySQL
        typealias Person = PersonMySQL
        let conn = mysqlConn!

        // Insert data
        let person1 = try Person(name: "Person 1").save(on: conn).wait()
        let person2 = try Person(name: "Person 2").save(on: conn).wait()
        let message = try Message(
            from_person_id: person1.requireID(),
            to_person_id: person2.requireID(),
            body: "Bla bla bla"
            ).save(on: conn).wait()

        // Fetch
        let result = try conn.raw(
            """
            SELECT * FROM messages
            JOIN persons AS from_persons ON messages.from_person_id = from_persons.id
            JOIN persons AS to_persons ON messages.to_person_id = to_persons.id
            WHERE messages.id=\(message.requireID())
            """
        ).all().map { rows in
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
    }
}
