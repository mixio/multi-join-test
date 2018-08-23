import FluentSQLite

public struct Person: SQLiteModel, Migration {
    public static let entity = "persons"
    
    
    public var id: Int?
    public var name: String
    
    public init(id: Int? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
