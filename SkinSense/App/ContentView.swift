//
//  ContentView.swift
//  SkinSense
//
//  Created by Setianing Budi on 28/06/26.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .scan

    enum Tab {
        case scan, history, about
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ScanView()
                .tabItem {
                    Label("Scan", systemImage: "camera.viewfinder")
                }
                .tag(Tab.scan)

            HistoryView()
                .tabItem {
                    Label("Riwayat", systemImage: "clock.fill")
                }
                .tag(Tab.history)

            AboutView()
                .tabItem {
                    Label("Tentang", systemImage: "info.circle.fill")
                }
                .tag(Tab.about)
        }
        .tint(.teal)
    }
}

#Preview {
    ContentView()
}
