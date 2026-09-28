import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID
    var name: String
    var order: Int
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date

    init(name: String, order: Int) {
        self.id = UUID()
        self.name = name
        self.order = order
        self.isActive = true
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    static let defaultNames: [(name: String, order: Int)] = [
        ("運動", 1),
        ("食事", 2),
        ("睡眠", 3),
        ("仕事", 4),
    ]
}
