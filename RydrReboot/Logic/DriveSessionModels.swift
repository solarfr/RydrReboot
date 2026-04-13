import Foundation
import CoreLocation
import Observation

struct DriveSession: Identifiable, Codable {
    let id: UUID
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval
    let dayPeriod: DayPeriod
    let route: [RouteCoordinate]
}

enum DayPeriod: String, Codable {
    case day
    case night
}

struct RouteCoordinate: Codable {
    let latitude: Double
    let longitude: Double

    init(_ coordinate: CLLocationCoordinate2D) {
        latitude = coordinate.latitude
        longitude = coordinate.longitude
    }

    var clLocationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

@Observable
final class DriveSessionStore {
    static let shared = DriveSessionStore()

    private(set) var sessions: [DriveSession] = []

    private let fileURL: URL

    private init() {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        fileURL = (directory ?? URL(fileURLWithPath: "/tmp")).appendingPathComponent("drive_sessions.json")
        load()
    }

    var totalLoggedHours: Double {
        sessions.reduce(0) { $0 + $1.duration } / 3600
    }

    func add(_ session: DriveSession) {
        sessions.insert(session, at: 0)
        save()
    }

    func remove(_ session: DriveSession) {
        sessions.removeAll { $0.id == session.id }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        guard let decoded = try? JSONDecoder().decode([DriveSession].self, from: data) else { return }
        sessions = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
}

func dayPeriod(for date: Date) -> DayPeriod {
    let hour = Calendar.current.component(.hour, from: date)
    return (6..<18).contains(hour) ? .day : .night
}
