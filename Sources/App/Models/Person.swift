import FluentSQLite
import FluentMySQL

public struct PersonSQLite: SQLiteModel, Migration, Equatable {
    public static let entity = "persons"
    
    public var id: Int?
    public var name: String
    
    public init(id: Int? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

public struct PersonMySQL: MySQLModel, Migration, Equatable {
    public static let entity = "persons"
    
    public var id: Int?
    public var name: String
    
    public init(id: Int? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
