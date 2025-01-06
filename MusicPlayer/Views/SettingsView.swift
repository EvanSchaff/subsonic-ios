//
//  SettingsView.swift
//  MusicPlayer
//
//  Created by Evan Schaff on 12/17/24.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var config = ConfigurationManager.shared
    @State private var serverUrl: String
    @State private var username: String
    @State private var password: String
    
    init() {
        let credentials = ConfigurationManager.shared.getCredentials()
        _serverUrl = State(initialValue: credentials.baseURL)
        _username = State(initialValue: credentials.username)
        _password = State(initialValue: credentials.password)
    }
    
    var body: some View {
        List {
            // Server Connection Section
            Section(header: Text("Server Connection")) {
                TextField("Server URL", text: $serverUrl)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                
                TextField("Username", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                SecureField("Password", text: $password)
                
                Button(action: {
                    connectToServer()
                }) {
                    Text("Connect")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                
                if config.hasValidCredentials() {
                    Button(action: {
                        config.clearCredentials()
                        serverUrl = ""
                        username = ""
                        password = ""
                    }) {
                        Text("Clear Credentials")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .foregroundColor(.red)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
    }
    func connectToServer() {
        config.updateCredentials(
            baseURL: serverUrl,
            username: username,
            password: password
        )
        // Add your connection logic here
    }
}
