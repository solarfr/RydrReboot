import SwiftUI
import MapKit
import CoreLocation

struct DriveSessionView: View {
    @Environment(\.dismiss) var dismiss

    @State var location = DriveLocationManager()
    @State var position: MapCameraPosition = .automatic
    @State var currentLocation: CLLocationCoordinate2D?
    @State var route: [CLLocationCoordinate2D] = []

    @AppStorage("activeDriveStart") var activeStart: Double = 0
    @AppStorage("activeDriveIsRunning") var activeRunning: Bool = false
    @AppStorage("activeDriveAccumulated") var activeTime: Double = 0

    @State var startedAt = Date()
    @State var addedTime: TimeInterval = 0

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Drive in progress")
                        .font(.custom("Montserrat-ExtraBold", size: 28))
                        .foregroundStyle(.black)

                    Text("Timer keeps running even if your phone is locked.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.black.opacity(0.7))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Elapsed")
                        .font(.subheadline)
                        .foregroundStyle(.black.opacity(0.7))

                    TimelineView(.periodic(from: Date(), by: 1)) { _ in
                        Text(timerText())
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(.black)
                    }

                    Text("Tap stop to save this drive")
                        .font(.caption)
                        .foregroundStyle(.black.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 120)
                .padding(.horizontal, 18)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                }

                Map(position: $position) {
                    if route.count > 1 {
                        MapPolyline(coordinates: route)
                            .stroke(.black, lineWidth: 4)
                    }

                    if let currentLocation {
                        Marker("You", coordinate: currentLocation)
                    }
                }
                .mapStyle(.standard)
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                }

                Button {
                    stopDrive()
                } label: {
                    Text("Stop & Save")
                        .font(.custom("Montserrat-ExtraBold", size: 14))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
        }
        .onAppear {
            setupDrive()

            location.onUpdate = { coordinate in
                currentLocation = coordinate
                addRoutePoint(coordinate)

                withAnimation(.easeInOut(duration: 0.5)) {
                    position = .region(
                        MKCoordinateRegion(
                            center: coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    )
                }
            }

            location.requestLocation()
        }
    }

    func setupDrive() {
        if activeRunning && activeStart > 0 {
            startedAt = Date(timeIntervalSince1970: activeStart)
            addedTime = activeTime
        } else {
            startedAt = Date()
            addedTime = 0
            activeStart = startedAt.timeIntervalSince1970
            activeTime = addedTime
            activeRunning = true
        }
    }

    func timerText() -> String {
        let total = Int(addedTime + Date().timeIntervalSince(startedAt))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60

        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    func addRoutePoint(_ coordinate: CLLocationCoordinate2D) {
        if let last = route.last {
            let oldLocation = CLLocation(latitude: last.latitude, longitude: last.longitude)
            let newLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

            if newLocation.distance(from: oldLocation) < 8 {
                return
            }
        }

        route.append(coordinate)
    }

    func stopDrive() {
        let endedAt = Date()
        let duration = addedTime + endedAt.timeIntervalSince(startedAt)

        let session = DriveSession(
            id: UUID(),
            startDate: startedAt,
            endDate: endedAt,
            duration: duration,
            dayPeriod: getDayPeriod(startedAt),
            route: route.map { RouteCoordinate($0) }
        )

        DriveSessionStore.shared.addDrive(session)

        activeStart = 0
        activeTime = 0
        activeRunning = false

        dismiss()
    }
}

final class DriveLocationManager: NSObject, CLLocationManagerDelegate {
    let manager = CLLocationManager()
    var onUpdate: ((CLLocationCoordinate2D) -> Void)?

    override init() {
        super.init()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
        manager.pausesLocationUpdatesAutomatically = false
    }

    func requestLocation() {
        manager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        onUpdate?(coordinate)
    }
}
