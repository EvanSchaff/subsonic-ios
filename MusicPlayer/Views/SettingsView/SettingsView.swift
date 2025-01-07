//
//  SettingsView.swift
//  MusicPlayer
//
//  Created by Evan Schaff on 12/17/24.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            connectionsSection()
        }
            .listStyle(InsetGroupedListStyle())
        }
    
    private func connectionsSection() -> some View {
        NavigationLink(destination: ConnectionsView()) {
            Text("Connections")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
        }
    }
}

