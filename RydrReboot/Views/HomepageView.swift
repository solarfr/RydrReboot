import SwiftUI
import MapKit
import CoreLocation

struct HomepageView: View {
    @State private var locationManager = LocationManager()
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var store = DriveSessionStore.shared

    private let goalHours: Double = 50
    private let goalHoursNight: Double = 10

    private var loggedHours: Double {
        store.totalLoggedHours
    }
    
    private var nightHours: Double {
        store.totalNightHours
    }

    private var progress: Double {
        min(max(loggedHours / goalHours, 0), 1)
    }
    
    private var progressCircleNight: Double {
        min(max(nightHours / goalHoursNight, 0), 1)
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                header
                startDriveButton
                progressCard
                progressCardNight
                locationMap
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 24)
            .padding(.top, 24)
        }
        .onAppear {
            locationManager.onUpdate = { newCoordinate in
                coordinate = newCoordinate
                withAnimation(.easeInOut(duration: 0.5)) {
                    mapPosition = .region(
                        MKCoordinateRegion(
                            center: newCoordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
                        )
                    )
                }
            }
            locationManager.requestAuthorization()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Rydr")
                .foregroundStyle(.black)
                .font(.custom("Montserrat-ExtraBold", size: 40))
            Text("View and log driving hours easily!")
                .foregroundStyle(.black.opacity(0.7))
                .font(.system(size: 16, weight: .medium))
        }
    }

    private var startDriveButton: some View {
        NavigationLink {
            DriveSessionView()
        } label: {
            Text("Start Drive")
                .font(.custom("Montserrat-ExtraBold", size: 14))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var progressCard: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
            )
            .frame(height: 120)
            .overlay(
                HStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .stroke(Color.black.opacity(0.08), lineWidth: 10)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.black, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text(String(format: "%.0f%%", progress * 100))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.black)
                    }
                    .frame(width: 60, height: 60)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Total Hours")
                            .font(.subheadline)
                            .foregroundStyle(.black.opacity(0.7))
                        Text(String(format: "%.fh / %.0fh", loggedHours, goalHours))
                            .font(.title2)
                            .foregroundStyle(.black)
                        Text("Keep going to reach 50!")
                            .font(.caption)
                            .foregroundStyle(.black.opacity(0.6))
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 18)
            )
    }
    
    private var progressCardNight: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
            )
            .frame(height: 120)
            .overlay(
                HStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .stroke(Color.black.opacity(0.08), lineWidth: 10)
                        Circle()
                            .trim(from: 0, to: progressCircleNight)
                            .stroke(Color.black, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text(String(format: "%.0f%%", progressCircleNight * 100))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.black)
                    }
                    .frame(width: 60, height: 60)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Night Hours")
                            .font(.subheadline)
                            .foregroundStyle(.black.opacity(0.7))
                        Text(String(format: "%.0fh / %.0fh", nightHours, goalHoursNight))
                            .font(.title2)
                            .foregroundStyle(.black)
                        Text("Keep going to reach 50!")
                            .font(.caption)
                            .foregroundStyle(.black.opacity(0.6))
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 18)
            )
            .offset(y: -10)
    }

    private var locationMap: some View {
        Map(position: $mapPosition) {
            if let coordinate {
                Marker("You", coordinate: coordinate)
            }
        }
        .mapStyle(.standard)
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.black.opacity(0.12), lineWidth: 1)
        )
        .offset(y: -20)
        .overlay(alignment: .topLeading) {
            Text("Live location")
                .font(.caption)
                .foregroundStyle(.black.opacity(0.6))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(12)
                .offset(y: -20)
        }
    }
}

final class LocationManager: NSObject, CLLocationManagerDelegate {
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

#Preview {
    MainView()
}
