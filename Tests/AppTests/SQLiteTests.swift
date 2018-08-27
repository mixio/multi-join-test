@testable import App
import Vapor
import FluentSQLite
import FluentMySQL
import XCTest
import JJTools

final class SQLiteTests: XCTestCase {

    var app: Application!
    var sqliteConn: SQLiteConnection!
    var req: Request!

    override func setUp() {
        try! Application.reset()
        app = try! Application.testable()
        req = Request(using: app)
        sqliteConn = try! app.newConnection(to: .sqlite).wait()
    }

    override func tearDown() {
        sqliteConn.close()
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
        do {
            let _ = try conn.query("PRAGMA short_column_names = OFF;").wait()
            let result = try conn.raw(
                """
                SELECT * FROM messages
                JOIN persons AS from_persons ON messages.from_person_id = from_persons.id
                JOIN persons AS to_persons ON messages.to_person_id = to_persons.id
                WHERE messages.id=?
                """
            )
            .bind(message.requireID())
.           all()
            .map { [conn] rows in
                try rows.map { [conn] row -> (Message, Person, Person) in
                    // Using table names.
//                    let message = row.filter { $0.key.table == "messages" && $0.key.occurrence == 1 }
//                    let person_from = row.filter { $0.key.table == "persons" && $0.key.occurrence == 1 }
//                    let person_to = row.filter { $0.key.table == "persons" && $0.key.occurrence == 2 }
                    let msg = try conn.decode(Message.self, from: row, table: "messages")
                    let from = try conn.decode(Person.self, from: row, table: "persons", occurrence: 1)
                    let to = try conn.decode(Person.self, from: row, table: "persons", occurrence: 2)
                    jjprint(msg, from, to)
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
        do {
            let _ = try conn.query("PRAGMA short_column_names = OFF;").wait()
            let result = try conn.raw(
                """
                SELECT messages.*, from_persons.id, from_persons.name, to_persons.id, to_persons.name
                FROM messages
                JOIN persons AS from_persons ON messages.from_person_id = from_persons.id
                JOIN persons AS to_persons ON messages.to_person_id = to_persons.id
                WHERE messages.id=?
                """
            )
            .bind(message.requireID())
            .all()
            .map { [conn] rows in
                try rows.map { [conn] row -> (Message, Person, Person) in
                    // Using table aliases.
                    let msg = try conn.decode(Message.self, from: row, table: "messages")
                    let from = try conn.decode(Person.self, from: row, table: "from_persons")
                    let to = try conn.decode(Person.self, from: row, table: "to_persons")
                    return (msg, from, to)
                }
            }
            .wait()
            XCTAssertEqual(result[0].0, message)
            XCTAssertEqual(result[0].1, person1)
            XCTAssertEqual(result[0].2, person2)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    func testSQLiteWithVaporSQL() throws {
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
        do {
            typealias FromPerson = Person
            typealias ToPerson = Person
            let result = try conn.select()
                .all()
//                .column(SQLiteSelectExpression.keyPath(\Message.id, as: .identifier("Message.id")))
//                .column(SQLiteSelectExpression.keyPath(\Message.from_person_id, as: .identifier("Message.from_person_id")))
//                .column(SQLiteSelectExpression.keyPath(\Message.to_person_id, as: .identifier("Message.to_person_id")))
//                .column(SQLiteSelectExpression.keyPath(\Message.body, as: .identifier("Message.body")))
//                .column(SQLiteSelectExpression.keyPath(\Person.id, as: .identifier("from_person.id")))
//                .column(SQLiteSelectExpression.keyPath(\Person.id, as: .identifier("to_person.id")))
                .from(Message.self)
                .join(\Message.from_person_id, to:\FromPerson.id, alias: "F")
                .join(\Message.to_person_id, to:\ToPerson.id, alias: "T")
                .where(\Message.id == message.requireID())
                .all()
                .map { [conn] rows in
                    try rows.map { [conn] row -> (Message, Person, Person) in
                        // Using table aliases.
                        let msg = try conn.decode(Message.self, from: row, table: "messages")
                        let from = try conn.decode(Person.self, from: row, table: "persons", occurrence: 1)
                        let to = try conn.decode(Person.self, from: row, table: "persons", occurrence: 2)
                        return (msg, from, to)
                    }
                }
                .wait()

            jjprint(result)
            XCTAssertEqual(result[0].0, message)
            XCTAssertEqual(result[0].1, person1)
            XCTAssertEqual(result[0].2, person2)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
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

}
