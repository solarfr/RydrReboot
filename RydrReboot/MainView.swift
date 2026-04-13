//
//  ContentView.swift
//  RydrReboot
//
//  Created by Krishiv Patel on 3/20/26.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Spacer()
                
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
            }
        }
        .padding(.bottom, -20)
    }
}

#Preview {
    MainView()
}
