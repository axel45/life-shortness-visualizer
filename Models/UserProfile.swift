import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var birthDate: Date
    var lifeExpectancy: Int
    var createdAt: Date
    var updatedAt: Date

    init(birthDate: Date, lifeExpectancy: Int = 85) {
        self.id = UUID()
        self.birthDate = birthDate
        self.lifeExpectancy = lifeExpectancy
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
