//
//  User.swift
//  Koereq
//
//  Created by Koereq Team on 2025/05/23.
//

import Foundation

struct User: Codable {
    let facilityId: String
    let facilityName: String
    
    init(facilityId: String, facilityName: String) {
        self.facilityId = facilityId
        self.facilityName = facilityName
    }
}

struct UserDefaults_Keys {
    static let currentUser = "currentUser"
    static let isLoggedIn = "isLoggedIn"
}

class UserManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoggedIn: Bool = false
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadUser()
    }
    
    func login(facilityId: String, facilityName: String) {
        let user = User(facilityId: facilityId, facilityName: facilityName)
        self.currentUser = user
        self.isLoggedIn = true
        saveUser(user)
    }
    
    func logout() {
        self.currentUser = nil
        self.isLoggedIn = false
        userDefaults.removeObject(forKey: UserDefaults_Keys.currentUser)
        userDefaults.set(false, forKey: UserDefaults_Keys.isLoggedIn)
    }
    
    private func saveUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            userDefaults.set(encoded, forKey: UserDefaults_Keys.currentUser)
            userDefaults.set(true, forKey: UserDefaults_Keys.isLoggedIn)
        }
    }
    
    private func loadUser() {
        self.isLoggedIn = userDefaults.bool(forKey: UserDefaults_Keys.isLoggedIn)
        
        if let userData = userDefaults.data(forKey: UserDefaults_Keys.currentUser),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
        }
    }
}
