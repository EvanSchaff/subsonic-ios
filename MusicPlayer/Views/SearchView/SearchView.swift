//
//  SearchView.swift
//  MusicPlayer
//
//  Created by Evan Schaff on 12/17/24.
//

import SwiftUI

struct SearchView: View {
    var body: some View {
        VStack(spacing: 16) {
            staticSearchBar()
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    private func staticSearchBar() -> some View {
        NavigationLink(destination: SearchSection()) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                Text("Search...")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10)
            }
            .padding(.horizontal, 16)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(20)
        }
    }
    
    private func albumScrollView() -> some View {
        return ScrollView() {
            VStack(spacing: 10) {
                
            }
        }
    }
    
}



