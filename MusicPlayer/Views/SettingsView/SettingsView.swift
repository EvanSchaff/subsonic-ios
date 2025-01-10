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
            clearCacheSection()
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
    
    private func clearCacheSection() -> some View {
        Button(action: {
            clearCache()
        }) {
            Text("Clear Cache")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
        }
    }
    
    private func clearCache() {
        ImageCache.shared.clearCache()
        print("Cache cleared")
    }
    
}
