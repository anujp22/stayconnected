//
//  AppShellView.swift
//  StayConnected
//
//  Created by Anuj Patel on 1/30/26.
//

import CoreData
import SwiftUI

// MARK: - App Tabs

enum AppTab: Hashable {
    case home
    case pool
    case summary
    case settings
}

struct AppShellView: View {
    // MARK: - Environment
    @Environment(\.managedObjectContext) private var ctx

    // MARK: - State
    @State private var selectedTab: AppTab = .home

    // MARK: - View
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(AppTab.home)

            PoolView()
                .tabItem {
                    Label("Pool", systemImage: "person.2.fill")
                }
                .tag(AppTab.pool)

            SummaryView()
                .tabItem {
                    Label("Summary", systemImage: "chart.bar.fill")
                }
                .tag(AppTab.summary)
            
            SettingsView(context: ctx)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(AppTab.settings)
        }
        .tint(Color("Primary"))
    }
}
