import SwiftUI
import MapKit
import CoreLocation

struct DriveSessionView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var locationManager = DriveLocationManager()
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var route: [CLLocationCoordinate2D] = []

    @AppStorage("activeDriveStart") private var activeStartTimestamp: Double = 0
    @AppStorage("activeDriveIsRunning") private var activeIsRunning: Bool = false
    @AppStorage("activeDriveAccumulated") private var activeAccumulated: Double = 0

    @State private var startDate: Date = Date()
    @State private var accumulated: TimeInterval = 0

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                header
                timerCard
                driveMap
                stopButton
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 24)
            .padding(.top, 24)
        }
        .onAppear {
            configureSessionState()
            locationManager.onUpdate = { newCoordinate in
                coordinate = newCoordinate
                appendToRoute(newCoordinate)
                withAnimation(.easeInOut(duration: 0.5)) {
                    mapPosition = .region(
                        MKCoordinateRegion(
                            center: newCoordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    )
                }
            }
            locationManager.requestAuthorization()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Drive in progress")
                .font(.custom("Montserrat-ExtraBold", size: 28))
                .foregroundStyle(.black)
            Text("Timer keeps running even if your phone is locked.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.black.opacity(0.7))
        }
    }

    private var timerCard: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
            )
            .frame(height: 120)
            .overlay(
                VStack(alignment: .leading, spacing: 8) {
                    Text("Elapsed")
                        .font(.subheadline)
                        .foregroundStyle(.black.opacity(0.7))
                    TimelineView(.periodic(from: Date(), by: 1)) { _ in
                        Text(formattedElapsed)
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(.black)
                    }
                    Text("Tap stop to save this drive")
                        .font(.caption)
                        .foregroundStyle(.black.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
            )
    }

    private var driveMap: some View {
        Map(position: $mapPosition) {
            if route.count > 1 {
                MapPolyline(coordinates: route)
                    .stroke(Color.black, lineWidth: 4)
            }
            if let coordinate {
                Marker("You", coordinate: coordinate)
            }
        }
        .mapStyle(.standard)
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.black.opacity(0.12), lineWidth: 1)
        )
    }

    private var stopButton: some View {
        Button {
            saveSessionAndStop()
        } label: {
            Text("Stop & Save")
                .font(.custom("Montserrat-ExtraBold", size: 14))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var formattedElapsed: String {
        let total = accumulated + Date().timeIntervalSince(startDate)
        let hours = Int(total) / 3600
        let minutes = (Int(total) % 3600) / 60
        let seconds = Int(total) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func configureSessionState() {
        if activeIsRunning, activeStartTimestamp > 0 {
            startDate = Date(timeIntervalSince1970: activeStartTimestamp)
            accumulated = activeAccumulated
        } else {
            startDate = Date()
            accumulated = 0
            activeStartTimestamp = startDate.timeIntervalSince1970
            activeAccumulated = accumulated
            activeIsRunning = true
        }
    }

    private func appendToRoute(_ newCoordinate: CLLocationCoordinate2D) {
        if let last = route.last {
            let lastLocation = CLLocation(latitude: last.latitude, longitude: last.longitude)
            let newLocation = CLLocation(latitude: newCoordinate.latitude, longitude: newCoordinate.longitude)
            if newLocation.distance(from: lastLocation) < 8 { return }
        }
        route.append(newCoordinate)
    }

    private func saveSessionAndStop() {
        let endDate = Date()
        let duration = accumulated + endDate.timeIntervalSince(startDate)
        let session = DriveSession(
            id: UUID(),
            startDate: startDate,
            endDate: endDate,
            duration: duration,
            dayPeriod: dayPeriod(for: startDate),
            route: route.map { RouteCoordinate($0) }
        )
        DriveSessionStore.shared.add(session)

        activeStartTimestamp = 0
        activeAccumulated = 0
        activeIsRunning = false
        dismiss()
    }
}

final class DriveLocationManager: NSObject, CLLocationManagerDelegate {
    var onUpdate: ((CLLocationCoordinate2D) -> Void)?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
        manager.pausesLocationUpdatesAutomatically = false
    }

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last?.coordinate else { return }
        onUpdate?(latest)
    }
}
