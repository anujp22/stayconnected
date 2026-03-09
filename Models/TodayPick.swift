import Foundation

// MARK: - TodayPick Model
struct TodayPick: Identifiable, Equatable {
    // MARK: - Properties
    let id: UUID
    var displayName: String
    var phoneNumber: String?
    var lastConnectedText: String

    // MARK: - Initialization
    init(
        id: UUID = UUID(),
        displayName: String,
        phoneNumber: String? = nil,
        lastConnectedText: String = "Not contacted yet"
    ) {
        self.id = id
        self.displayName = displayName
        self.phoneNumber = phoneNumber
        self.lastConnectedText = lastConnectedText
    }
}
