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

// MARK: - 施設マスターデータ
struct FacilityMaster: Codable {
    let facilityId: String
    let facilityName: String
    let isActive: Bool
    
    init(facilityId: String, facilityName: String, isActive: Bool = true) {
        self.facilityId = facilityId
        self.facilityName = facilityName
        self.isActive = isActive
    }
}

class UserManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoggedIn = false
    @Published var registeredFacilities: [FacilityMaster] = []
    
    private let userDefaults = UserDefaults.standard
    private let currentUserKey = "currentUser"
    private let facilitiesKey = "registeredFacilities"
    
    // デフォルト施設データ
    private let defaultFacilities: [FacilityMaster] = [
        FacilityMaster(facilityId: "001", facilityName: "札幌徳洲会病院"),
        FacilityMaster(facilityId: "002", facilityName: "勤医協中央病院"),
        FacilityMaster(facilityId: "003", facilityName: "函館五稜郭病院"),
        FacilityMaster(facilityId: "004", facilityName: "富士宮市立病院"),
        FacilityMaster(facilityId: "005", facilityName: "回生病院"),
    ]
    
    init() {
        loadFacilities()
        loadUser()
    }
    
    func login(facilityId: String, facilityName: String) -> LoginResult {
        // 施設ID・施設名の組み合わせを検証
        guard let facility = validateFacility(facilityId: facilityId, facilityName: facilityName) else {
            return .failure(.invalidCredentials)
        }
        
        // 施設が有効かチェック
        guard facility.isActive else {
            return .failure(.facilityInactive)
        }
        
        let user = User(facilityId: facility.facilityId, facilityName: facility.facilityName)
        currentUser = user
        isLoggedIn = true
        saveUser()
        print("User logged in: \(facility.facilityName) (\(facility.facilityId))")
        return .success
    }
    
    func logout() {
        currentUser = nil
        isLoggedIn = false
        // アカウント情報は保持したまま、ログイン状態のみを解除
        print("User logged out")
    }
    
    // MARK: - 施設管理機能
    
    func addFacility(facilityId: String, facilityName: String) -> FacilityRegistrationResult {
        let trimmedId = facilityId.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = facilityName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // バリデーション
        guard !trimmedId.isEmpty && !trimmedName.isEmpty else {
            return .failure(.emptyFields)
        }
        
        guard trimmedId.count >= 3 else {
            return .failure(.invalidFacilityId)
        }
        
        guard trimmedName.count >= 2 else {
            return .failure(.invalidFacilityName)
        }
        
        // 重複チェック
        if registeredFacilities.contains(where: { $0.facilityId.lowercased() == trimmedId.lowercased() }) {
            return .failure(.duplicateFacilityId)
        }
        
        if registeredFacilities.contains(where: { $0.facilityName == trimmedName }) {
            return .failure(.duplicateFacilityName)
        }
        
        // 新規施設追加
        let newFacility = FacilityMaster(facilityId: trimmedId, facilityName: trimmedName)
        registeredFacilities.append(newFacility)
        saveFacilities()
        
        print("New facility registered: \(trimmedName) (\(trimmedId))")
        return .success
    }
    
    func removeFacility(facilityId: String) -> Bool {
        guard let index = registeredFacilities.firstIndex(where: { $0.facilityId == facilityId }) else {
            return false
        }
        
        let removedFacility = registeredFacilities[index]
        registeredFacilities.remove(at: index)
        saveFacilities()
        
        print("Facility removed: \(removedFacility.facilityName) (\(removedFacility.facilityId))")
        return true
    }
    
    func toggleFacilityStatus(facilityId: String) -> Bool {
        guard let index = registeredFacilities.firstIndex(where: { $0.facilityId == facilityId }) else {
            return false
        }
        
        let currentFacility = registeredFacilities[index]
        let updatedFacility = FacilityMaster(
            facilityId: currentFacility.facilityId,
            facilityName: currentFacility.facilityName,
            isActive: !currentFacility.isActive
        )
        
        registeredFacilities[index] = updatedFacility
        saveFacilities()
        
        print("Facility status toggled: \(updatedFacility.facilityName) -> \(updatedFacility.isActive ? "Active" : "Inactive")")
        return true
    }
    
    private func validateFacility(facilityId: String, facilityName: String) -> FacilityMaster? {
        return registeredFacilities.first { facility in
            facility.facilityId.lowercased() == facilityId.lowercased() &&
            facility.facilityName == facilityName
        }
    }
    
    private func saveUser() {
        if let user = currentUser,
           let data = try? JSONEncoder().encode(user) {
            userDefaults.set(data, forKey: currentUserKey)
        }
    }
    
    private func loadUser() {
        guard let data = userDefaults.data(forKey: currentUserKey),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            return
        }
        
        // 施設が登録されているかチェック
        if let facility = registeredFacilities.first(where: { $0.facilityId == user.facilityId }) {
            // 施設が有効な場合はログイン状態を復元
            if facility.isActive {
                currentUser = user
                isLoggedIn = true
                print("User session restored: \(facility.facilityName) (\(facility.facilityId))")
            } else {
                // 施設が無効化されている場合でも、ユーザー情報は保持（ログイン状態のみ解除）
                currentUser = user
                isLoggedIn = false
                print("User found but facility is inactive: \(facility.facilityName) (\(facility.facilityId))")
            }
        } else {
            // 施設が登録リストにない場合のみ完全にクリア
            currentUser = nil
            isLoggedIn = false
            userDefaults.removeObject(forKey: currentUserKey)
            print("Unregistered facility removed: \(user.facilityId)")
        }
    }
    
    private func saveFacilities() {
        if let data = try? JSONEncoder().encode(registeredFacilities) {
            userDefaults.set(data, forKey: facilitiesKey)
            print("Saved \(registeredFacilities.count) facilities to UserDefaults")
        }
    }
    
    private func loadFacilities() {
        if let data = userDefaults.data(forKey: facilitiesKey),
           let facilities = try? JSONDecoder().decode([FacilityMaster].self, from: data) {
            registeredFacilities = facilities
            print("Loaded \(registeredFacilities.count) facilities from UserDefaults")
        } else {
            // 初回起動時はデフォルト施設を設定
            registeredFacilities = defaultFacilities
            saveFacilities()
            print("Initialized with \(defaultFacilities.count) default facilities")
        }
    }
    
    // 登録済み施設一覧を取得（ログイン画面での表示用）
    func getRegisteredFacilities() -> [FacilityMaster] {
        return registeredFacilities.filter { $0.isActive }
    }
    
    // 全施設一覧を取得（管理画面用）
    func getAllFacilities() -> [FacilityMaster] {
        return registeredFacilities.sorted { $0.facilityId < $1.facilityId }
    }
    
    // 施設IDから施設名を取得（入力補助用）
    func getFacilityName(for facilityId: String) -> String? {
        return registeredFacilities.first { $0.facilityId.lowercased() == facilityId.lowercased() }?.facilityName
    }
    
    // デフォルト施設にリセット
    func resetToDefaultFacilities() {
        registeredFacilities = defaultFacilities
        saveFacilities()
        print("Reset to default facilities")
    }
}

// MARK: - Login Result
enum LoginResult {
    case success
    case failure(LoginError)
}

enum LoginError: Error, LocalizedError {
    case invalidCredentials
    case facilityInactive
    case emptyFields
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "施設ID・施設名の組み合わせが正しくありません"
        case .facilityInactive:
            return "この施設は現在利用停止中です"
        case .emptyFields:
            return "施設IDと施設名を入力してください"
        }
    }
}

// MARK: - Facility Registration Result
enum FacilityRegistrationResult {
    case success
    case failure(FacilityRegistrationError)
}

enum FacilityRegistrationError: Error, LocalizedError {
    case emptyFields
    case invalidFacilityId
    case invalidFacilityName
    case duplicateFacilityId
    case duplicateFacilityName
    
    var errorDescription: String? {
        switch self {
        case .emptyFields:
            return "施設IDと施設名を入力してください"
        case .invalidFacilityId:
            return "施設IDは3文字以上で入力してください"
        case .invalidFacilityName:
            return "施設名は2文字以上で入力してください"
        case .duplicateFacilityId:
            return "この施設IDは既に登録されています"
        case .duplicateFacilityName:
            return "この施設名は既に登録されています"
        }
    }
}
