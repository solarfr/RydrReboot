import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomepageView()
            }
            .tabItem {
                Label("Home", systemImage: "car.side.fill")
            }

            NavigationStack {
                ManualView()
            }
            .tabItem {
                Label("Add", systemImage: "plus.circle")
            }

            NavigationStack {
                LogView()
            }
            .tabItem {
                Label("View Log", systemImage: "document.fill")
            }
        }
        .tint(.black)
    }
}

#Preview {
    MainView()
}
