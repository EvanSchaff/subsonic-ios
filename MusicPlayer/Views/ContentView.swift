//
//  ContentView.swift
//  MusicPlayer
//
//  Created by Evan Schaff on 12/17/24.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var player = PlayerViewModel.shared
    @State private var selectedTab = 1
    @State private var previousTab = 1 
    @State private var isConnected = true
    @State private var isPlayerViewVisible = false
    
    
    // Instantiate views once
    private let searchView = SearchView()
    private let mainView = MainView()
    private let settingsView = SettingsView()

    var body: some View {
        VStack(spacing: 0) {
                NavigationView {
                    ZStack(alignment: .bottom) {
                        VStack(spacing: 0) {
                            // Tabs
                            HStack {
                                tabButton(title: "Search", icon: "magnifyingglass", tabIndex: 0)
                                tabButton(title: "Main", icon: "music.note", tabIndex: 1)
                                tabButton(title: "Settings", icon: "gear", tabIndex: 2)
                            }
                            .padding(.horizontal)
                            .background(Color.gray.opacity(0.1))
                            
                            // Main Content Area
                            TabView(selection: $selectedTab) {
                                searchView
                                    .tag(0)
                                mainView
                                    .tag(1)
                                settingsView
                                    .tag(2)
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        }
                    }
                }
                .overlay(
                    Group {
                        if selectedTab != 2 && player.currentSong != nil { 
                            NowPlayingFooter(
                                albumArt: player.albumArt ?? Image("test_album"),
                                songTitle: player.currentSong?.name ?? "No Song Playing",
                                artistName: player.currentSong?.artist ?? "Unknown Artist",
                                isPlayerViewVisible: Binding(
                                    get: { isPlayerViewVisible },
                                    set: { newValue in
                                        if !newValue {
                                            selectedTab = previousTab
                                        }
                                        isPlayerViewVisible = newValue
                                    }
                                )
                            )
                            .padding(.bottom, 16)
                        }
                    },
                    alignment: .bottom
                )
                                .navigationViewStyle(StackNavigationViewStyle())
                .navigationViewStyle(StackNavigationViewStyle())
            }
        }

    private func tabButton(title: String, icon: String, tabIndex: Int) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .foregroundColor(selectedTab == tabIndex ? .blue : .gray)
                .imageScale(.large)

            Rectangle()
                .fill(selectedTab == tabIndex ? Color.blue : Color.clear)
                .frame(height: 2)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            previousTab = tabIndex
            selectedTab = tabIndex
        }
    }
}

#Preview {
    ContentView()
}











