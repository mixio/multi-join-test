@testable import App
import Vapor
import FluentSQLite
import FluentMySQL
import XCTest
import JJTools

final class AppTests: XCTestCase {

    var app: Application!
    var sqliteConn: SQLiteConnection!
    var mysqlConn: MySQLConnection!
    var req: Request!

    override func setUp() {
        try! Application.reset()
        app = try! Application.testable()
        req = Request(using: app)
        sqliteConn = try! app.newConnection(to: .sqlite).wait()
        mysqlConn = try! app.newConnection(to: .mysql).wait()
    }

    override func tearDown() {
        sqliteConn.close()
        mysqlConn.close()
    }

    func testSQLiteWithTableNames() throws {
        typealias Message = MessageSQLite
        typealias Person = PersonSQLite

        let conn = sqliteConn!

        // Insert data.
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
        ).all().map { [conn] rows in
            try rows.map { [conn] row -> (Message, Person, Person) in
                // Using table names.
                let msg = try conn.decode(Message.self, from: row, table: "messages")
                let from = try conn.decode(Person.self, from: row, table: "persons")
                let to = try conn.decode(Person.self, from: row, table: "persons")
                return (msg, from, to)
            }
        }.wait()
        XCTAssertEqual(result[0].0, message)
        XCTAssertEqual(result[0].1, person1)
        XCTAssertEqual(result[0].2, person2)
    }

    func testSQLiteWithTableAliases() throws {
        typealias Message = MessageSQLite
        typealias Person = PersonSQLite

        let conn = sqliteConn!

        // Insert data.
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
            ).all().map { [conn] rows in
                try rows.map { [conn] row -> (Message, Person, Person) in
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

    func testSQLiteWithColunmAliases() throws {
        typealias Message = MessageSQLite
        typealias Person = PersonSQLite

        let conn = sqliteConn!

        // Insert data.
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
            SELECT messages.*,
            from_persons.id AS "from_id",
            from_persons.name AS "from_name",
            to_persons.*
            FROM messages
            JOIN persons AS from_persons ON messages.from_person_id = from_persons.id
            JOIN persons AS to_persons ON messages.to_person_id = to_persons.id
            WHERE messages.id=\(message.requireID())
            """
            ).all().map { [conn] rows in
                try rows.map { [conn] row -> (Message, Person, Person) in
                    // Using table names.
                    let msg = try conn.decode(Message.self, from: row, table: "messages")
                    struct FromPerson: Decodable {
                        var from_id: Int
                        var from_name: String
                    }
                    let from = try conn.decode(FromPerson.self, from: row, table: "persons")
                    let to = try conn.decode(Person.self, from: row, table: "persons")
                    return (msg, Person(id: from.from_id, name: from.from_name), to)
                }
            }.wait()
        XCTAssertEqual(result[0].0, message)
        XCTAssertEqual(result[0].1, person1)
        XCTAssertEqual(result[0].2, person2)
    }

    func testSQLiteWith2Queries() throws {
        typealias Message = MessageSQLite
        typealias Person = PersonSQLite

        let conn = sqliteConn!

        // Insert data.
        let person1 = try Person(name: "Person 1").save(on: conn).wait()
        let person2 = try Person(name: "Person 2").save(on: conn).wait()
        let message = try Message(
            from_person_id: person1.requireID(),
            to_person_id: person2.requireID(),
            body: "Bla bla bla"
        ).save(on: conn).wait()

        // Fetch
        let result = try map(
            to: [(Message, Person, Person)].self,
            Message.query(on: req).join(\Person.id, to: \Message.from_person_id).alsoDecode(Person.self).all(),
            Message.query(on: req).join(\Person.id, to: \Message.to_person_id).alsoDecode(Person.self).all()
        ) { fromTuples, toTuples in
            let fromDictionary = fromTuples.toDictionary()
            let toDictionary = toTuples.toDictionary()
            var tuplesArray: [(Message, Person, Person)] = []
            tuplesArray.reserveCapacity(fromDictionary.count)
            for (message, from) in fromDictionary {
                let to = toDictionary[message]!
                tuplesArray.append((message, from, to))
            }
            return tuplesArray
        }.wait()
        XCTAssertEqual(result[0].0, message)
        XCTAssertEqual(result[0].1, person1)
        XCTAssertEqual(result[0].2, person2)
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
