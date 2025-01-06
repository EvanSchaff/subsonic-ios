//
//  Credentials.swift
//  MusicPlayer
//
//  Created by Evan Schaff on 12/31/24.
//

import Foundation

class ConfigurationManager: ObservableObject {
    static let shared = ConfigurationManager()
    
    @Published var baseURL: String {
        didSet {
            UserDefaults.standard.set(baseURL, forKey: "serverUrl")
        }
    }
    
    @Published var username: String {
        didSet {
            UserDefaults.standard.set(username, forKey: "username")
        }
    }
    
    private var password: String {
        didSet {
            if let passwordData = password.data(using: .utf8) {
                KeychainHelper.standard.save(
                    passwordData,
                    service: "com.yourapp.subsonic",
                    account: "userPassword"
                )
            }
        }
    }
    
    private init() {
        self.baseURL = UserDefaults.standard.string(forKey: "serverUrl") ?? ""
        self.username = UserDefaults.standard.string(forKey: "username") ?? ""
        
        // Try to get password from keychain
        if let passwordData = KeychainHelper.standard.read(
            service: "com.yourapp.subsonic",
            account: "userPassword"
        ),
        let storedPassword = String(data: passwordData, encoding: .utf8) {
            self.password = storedPassword
        } else {
            self.password = ""
        }
    }
    
    func getCredentials() -> (baseURL: String, username: String, password: String) {
        return (baseURL, username, password)
    }
    
    func updateCredentials(baseURL: String, username: String, password: String) {
        self.baseURL = baseURL
        self.username = username
        self.password = password
    }
    
    func hasValidCredentials() -> Bool {
        return !baseURL.isEmpty && !username.isEmpty && !password.isEmpty
    }
    
    func clearCredentials() {
        baseURL = ""
        username = ""
        password = ""
        UserDefaults.standard.removeObject(forKey: "serverUrl")
        UserDefaults.standard.removeObject(forKey: "username")
        KeychainHelper.standard.delete(
            service: "com.yourapp.subsonic",
            account: "userPassword"
        )
    }
}
