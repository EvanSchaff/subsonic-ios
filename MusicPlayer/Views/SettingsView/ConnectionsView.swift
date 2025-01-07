//
//  ConnectionsView.swift
//  MusicPlayer
//
//  Created by Evan Schaff on 1/6/25.
//

import SwiftUI

struct ConnectionsView: View {
    
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
            serverConnectionSection()
        }
        .navigationTitle("Connections")
        .listStyle(InsetGroupedListStyle())
    }
    
    private func serverConnectionSection() -> some View {
        Section(header: Text("Server Connections")) {
            serverUrlField()
            usernameField()
            passwordField()
            connectButton()
            if config.hasValidCredentials() {
                clearCredentialsButton()
            }
        }
        
    }
    
    private func serverUrlField() -> some View {
        TextField("Server URL", text: $serverUrl)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(.URL)
    }
    
    private func usernameField() -> some View {
        TextField("Username", text: $username)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
    }
    
    private func passwordField() -> some View {
        SecureField("Password", text: $password)
    }
    
    private func connectButton() -> some View {
        Button(action: {
            connectToServer()
        }) {
            Text("Connect")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
    }
    
    private func clearCredentialsButton() -> some View {
        Button(action: {
            clearCredentials()
        }) {
            Text("Clear Credentials")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .foregroundColor(.red)
        }
    }
    
    private func connectToServer() {
        config.updateCredentials(
            baseURL: serverUrl,
            username: username,
            password: password
        )
    }
    
    private func clearCredentials() {
        config.clearCredentials()
        serverUrl = ""
        username = ""
        password = ""
    }
}
