import SwiftUI
import MapKit

struct ManualView: View {
    @State private var date: Date = Date()
    @State private var hours: Int = 0
    @State private var minutes: Int = 30
    @State private var dayPeriod: DayPeriod = .day
    @State private var mapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
            span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
        )
    )
    @State private var mapCenter: CLLocationCoordinate2D?
    @State private var pinCoordinate: CLLocationCoordinate2D?

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            GeometryReader { proxy in
                let mapHeight = max(150, min(220, proxy.size.height * 0.28))

                VStack(alignment: .leading, spacing: 18) {
                    header
                    sessionCard
                    pinCard(mapHeight: mapHeight)
                    saveButton
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 24)
                .padding(.top, -30)
                .padding(.bottom, 6)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Add Drive")
                .font(.custom("Montserrat-ExtraBold", size: 28))
                .foregroundStyle(.black)
            Text("Manually log a driving session.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.black.opacity(0.7))
        }
    }

    private var sessionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Session details")
                .font(.subheadline)
                .foregroundStyle(.black.opacity(0.7))

            DatePicker("Date & time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .foregroundStyle(.black)
                .frame(width: 120, height: 10)
                .offset(x: 75, y: 5)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Duration")
                        .font(.caption)
                        .foregroundStyle(.black.opacity(0.6))
                        .offset(y: 10)
                    HStack(spacing: 10) {
                        Picker("Hours", selection: $hours) {
                            ForEach(0..<10, id: \.self) { value in
                                Text("\(value)h").tag(value)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 90, height: 50)
                        .offset(x: -20)

                        Picker("Minutes", selection: $minutes) {
                            ForEach([0, 15, 30, 45], id: \.self) { value in
                                Text("\(value)m").tag(value)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 95, height: 50)
                        .offset(x: -40)
                    }
                }

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Time of day")
                        .font(.caption)
                        .foregroundStyle(.black.opacity(0.6))
                        .offset(x: -50)
                    Picker("Time of Day", selection: $dayPeriod) {
                        Text("Day").tag(DayPeriod.day)
                        Text("Night").tag(DayPeriod.night)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120, height: 10)
                    .offset(x: -50,y: 10)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.12), lineWidth: 1)
        )
        .offset(x: -5)
    }

    private func pinCard(mapHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pin a general area")
                .font(.subheadline)
                .foregroundStyle(.black)
            Text("Move the map and set a single pin.")
                .font(.caption)
                .foregroundStyle(.black.opacity(0.6))

            Map(position: $mapPosition) {
                if let pinCoordinate {
                    Marker("Area", coordinate: pinCoordinate)
                }
            }
            .mapStyle(.standard)
            .onMapCameraChange { context in
                mapCenter = context.region.center
            }
            .frame(height: mapHeight)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
            )
            .overlay(alignment: .center) {
                Circle()
                    .stroke(Color.black.opacity(0.25), lineWidth: 2)
                    .frame(width: 28, height: 28)
                Circle()
                    .fill(Color.black)
                    .frame(width: 6, height: 6)
            }

            Button {
                if let mapCenter {
                    pinCoordinate = mapCenter
                }
            } label: {
                Text(pinCoordinate == nil ? "Set Pin Here" : "Update Pin")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.12), lineWidth: 1)
        )
    }

    private var saveButton: some View {
        Button {
            saveManualDrive()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .semibold))
                Text("Save Drive")
                    .font(.custom("Montserrat-ExtraBold", size: 14))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private func saveManualDrive() {
        let duration = TimeInterval((hours * 3600) + (minutes * 60))
        let endDate = date.addingTimeInterval(duration)
        let route = pinCoordinate.map { [RouteCoordinate($0)] } ?? []

        let session = DriveSession(
            id: UUID(),
            startDate: date,
            endDate: endDate,
            duration: duration,
            dayPeriod: dayPeriod,
            route: route
        )
        DriveSessionStore.shared.add(session)

        hours = 0
        minutes = 30
        dayPeriod = .day
        pinCoordinate = nil
    }
}

#Preview {
    MainView()
}

