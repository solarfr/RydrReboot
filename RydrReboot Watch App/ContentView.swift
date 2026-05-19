import SwiftUI
import CoreLocation
import Combine

struct ContentView: View {
    @StateObject var location = WatchLocationManager()
    @State var isDriving = false
    @State var startedAt = Date()
    @State var endedAt: Date?
    @State var route: [CLLocationCoordinate2D] = []

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 10) {
                Text("Rydr")
                    .font(.custom("Montserrat-ExtraBold", size: 22))
                    .foregroundStyle(.white)

                if isDriving {
                    TimelineView(.periodic(from: Date(), by: 1)) { _ in
                        Text(timerText())
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    VStack(spacing: 3) {
                        Text("Location")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))

                        if let coordinate = location.coordinate {
                            Text(String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude))
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                        } else {
                            Text("Finding you...")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.9))
                        }

                        Text("\(route.count) points")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.55))
                    }

                    Button {
                        endDrive()
                    } label: {
                        Text("End")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                } else {
                    if let endedAt {
                        Text("Ended \(formatTime(endedAt))")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.65))
                    } else {
                        Text("Ready to track")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.65))
                    }

                    Button {
                        startDrive()
                    } label: {
                        Text("Start")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white)
                }
            }
            .padding(.horizontal, 12)
        }
        .onAppear {
            location.onUpdate = { coordinate in
                if isDriving {
                    addRoutePoint(coordinate)
                }
            }

            location.requestLocation()
        }
    }

    func startDrive() {
        startedAt = Date()
        endedAt = nil
        route = []
        isDriving = true
        location.startLocation()

        if let coordinate = location.coordinate {
            addRoutePoint(coordinate)
        }
    }

    func endDrive() {
        endedAt = Date()
        isDriving = false
        location.stopLocation()
    }

    func timerText() -> String {
        let total = Int(Date().timeIntervalSince(startedAt))
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

    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short

        return formatter.string(from: date)
    }
}

final class WatchLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let manager = CLLocationManager()
    var onUpdate: ((CLLocationCoordinate2D) -> Void)?
    var wantsLocation = false

    @Published var coordinate: CLLocationCoordinate2D?

    override init() {
        super.init()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
    }

    func requestLocation() {
        manager.requestWhenInUseAuthorization()
    }

    func startLocation() {
        wantsLocation = true
        requestLocation()

        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
            manager.startUpdatingLocation()
        }
    }

    func stopLocation() {
        wantsLocation = false
        manager.stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if wantsLocation && (manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse) {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newCoordinate = locations.last?.coordinate else { return }
        coordinate = newCoordinate
        onUpdate?(newCoordinate)
    }
}
