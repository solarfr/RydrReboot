import SwiftUI
import MapKit

struct LogView: View {
    @State private var store = DriveSessionStore.shared

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Drive Log")
                        .font(.custom("Montserrat-ExtraBold", size: 28))
                        .foregroundStyle(.black)

                    if store.sessions.isEmpty {
                        Text("No drives saved yet!")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.black.opacity(0.7))
                            .offset(x: 25, y: -20)
                    } else {
                        ForEach(store.sessions) { session in
                            NavigationLink {
                                DriveLogDetailView(session: session)
                            } label: {
                                logCard(for: session)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
        }
    }

    private func logCard(for session: DriveSession) -> some View {
        let route = session.route.map { $0.clLocationCoordinate2D }
        let region = regionForRoute(route)

        return VStack(alignment: .leading, spacing: 12) {
            Map(position: .constant(.region(region))) {
                if route.count > 1 {
                    MapPolyline(coordinates: route)
                        .stroke(Color.black, lineWidth: 3)
                }
                if let first = route.first {
                    Marker("Start", coordinate: first)
                }
            }
            .mapStyle(.standard)
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate(session.startDate))
                    .font(.subheadline)
                    .foregroundStyle(.black)
                Text("Duration: \(formattedDuration(session.duration))")
                    .font(.caption)
                    .foregroundStyle(.black.opacity(0.7))
                Text("Time of Day: \(session.dayPeriod.rawValue.capitalized)")
                    .font(.caption)
                    .foregroundStyle(.black.opacity(0.7))
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.12), lineWidth: 1)
        )
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let total = Int(duration)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        return String(format: "%dh %02dm", hours, minutes)
    }

    private func regionForRoute(_ route: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard !route.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }

        var minLat = route[0].latitude
        var maxLat = route[0].latitude
        var minLon = route[0].longitude
        var maxLon = route[0].longitude

        for coordinate in route {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: max(maxLat - minLat, 0.01) * 1.6,
            longitudeDelta: max(maxLon - minLon, 0.01) * 1.6
        )

        return MKCoordinateRegion(center: center, span: span)
    }
}

struct DriveLogDetailView: View {
    let session: DriveSession

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Drive Details")
                        .font(.custom("Montserrat-ExtraBold", size: 28))
                        .foregroundStyle(.black)

                    detailMap

                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top, spacing: 16) {
                            detailBlock(title: "Start", date: dateOnly(session.startDate), time: timeOnly(session.startDate))
                            Spacer(minLength: 0)
                            detailBlock(title: "End", date: dateOnly(session.endDate), time: timeOnly(session.endDate))
                        }

                        Divider()
                            .overlay(Color.black.opacity(0.08))

                        detailRow(title: "Duration", value: formattedDuration(session.duration))
                        detailRow(title: "Time of Day", value: session.dayPeriod.rawValue.capitalized)
                    }
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.black.opacity(0.12), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var detailMap: some View {
        let route = session.route.map { $0.clLocationCoordinate2D }
        let region = regionForRoute(route)

        return Map(position: .constant(.region(region))) {
            if route.count > 1 {
                MapPolyline(coordinates: route)
                    .stroke(Color.black, lineWidth: 4)
            }
            if let first = route.first {
                Marker("Start", coordinate: first)
            }
            if let last = route.last {
                Marker("End", coordinate: last)
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

    private func detailBlock(title: String, date: String, time: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.black.opacity(0.7))
            Text(date)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.black)
            Text(time)
                .font(.caption)
                .foregroundStyle(.black.opacity(0.6))
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.black.opacity(0.7))
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.black)
        }
    }

    private func dateOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func timeOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let total = Int(duration)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        return String(format: "%dh %02dm", hours, minutes)
    }

    private func regionForRoute(_ route: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard !route.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }

        var minLat = route[0].latitude
        var maxLat = route[0].latitude
        var minLon = route[0].longitude
        var maxLon = route[0].longitude

        for coordinate in route {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: max(maxLat - minLat, 0.01) * 1.6,
            longitudeDelta: max(maxLon - minLon, 0.01) * 1.6
        )

        return MKCoordinateRegion(center: center, span: span)
    }
}

#Preview {
    MainView()
}
