//
//  LoginView.swift
//  Koereq
//
//  Created by Koereq Team on 2025/05/23.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var userManager: UserManager
    
    @State private var facilityId = ""
    @State private var facilityName = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingFacilityList = false
    @State private var suggestedFacilityName = ""
    @State private var showingFacilityManagement = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // ロゴエリア
                VStack(spacing: 16) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Koereq v2.1")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("医療向け音声記録支援アプリ")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 50)
                
                Spacer()
                
                // ログインフォーム
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("施設ID")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button("登録施設一覧") {
                                showingFacilityList = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        
                        TextField("施設IDを入力 (例: 001)", text: $facilityId)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: facilityId) { _, newValue in
                                // 施設IDに基づいて施設名を自動補完
                                if let suggested = userManager.getFacilityName(for: newValue.trimmingCharacters(in: .whitespacesAndNewlines)) {
                                    suggestedFacilityName = suggested
                                } else {
                                    suggestedFacilityName = ""
                                }
                            }
                        
                        // 施設ID入力補助
                        if !suggestedFacilityName.isEmpty {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                
                                Text("候補: \(suggestedFacilityName)")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                
                                Button("適用") {
                                    facilityName = suggestedFacilityName
                                }
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                            }
                            .padding(.top, 4)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("施設名")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("施設名を入力 (例: A病院)", text: $facilityName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .padding(.horizontal, 20)
                
                // 認証説明
                VStack(spacing: 4) {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        
                        Text("事前登録済みの施設のみアクセス可能")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("施設IDと施設名の組み合わせで認証します")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                
                // ログインボタン
                Button(action: login) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                        Text("ログイン")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isLoginEnabled ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!isLoginEnabled)
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
                
                // フッター情報
                VStack(spacing: 4) {
                    Text("Apple標準音声認識 + Azure OpenAI + Azure Storage")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Version 2.1.0")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    // 施設管理ボタン
                    Button("施設管理") {
                        showingFacilityManagement = true
                    }
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.top, 8)
                }
                .padding(.bottom, 30)
            }
            .navigationBarHidden(true)
        }
        .alert("ログインエラー", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingFacilityList) {
            FacilityListView()
                .environmentObject(userManager)
        }
        .sheet(isPresented: $showingFacilityManagement) {
            FacilityManagementView()
                .environmentObject(userManager)
        }
    }
    
    private var isLoginEnabled: Bool {
        !facilityId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !facilityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func login() {
        let trimmedFacilityId = facilityId.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedFacilityName = facilityName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 空白チェック
        guard !trimmedFacilityId.isEmpty && !trimmedFacilityName.isEmpty else {
            showAlert(message: "施設IDと施設名を入力してください")
            return
        }
        
        // 基本的なバリデーション
        guard trimmedFacilityId.count >= 3 else {
            showAlert(message: "施設IDは3文字以上で入力してください")
            return
        }
        
        guard trimmedFacilityName.count >= 2 else {
            showAlert(message: "施設名は2文字以上で入力してください")
            return
        }
        
        // 施設認証ログイン処理
        let result = userManager.login(
            facilityId: trimmedFacilityId,
            facilityName: trimmedFacilityName
        )
        
        switch result {
        case .success:
            // ログイン成功 - UserManagerのisLoggedInの変更で自動的に画面遷移
            break
        case .failure(let error):
            showAlert(message: error.localizedDescription)
        }
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showingAlert = true
    }
}

// MARK: - 登録施設一覧表示
struct FacilityListView: View {
    @EnvironmentObject var userManager: UserManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("事前登録済み施設一覧")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top)
                
                Text("以下の施設IDと施設名の組み合わせでログインできます")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                List(userManager.getRegisteredFacilities(), id: \.facilityId) { facility in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("施設ID:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(facility.facilityId)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                        
                        HStack {
                            Text("施設名:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(facility.facilityName)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Spacer()
            }
            .navigationTitle("登録施設")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 施設管理画面
struct FacilityManagementView: View {
    @EnvironmentObject var userManager: UserManager
    @Environment(\.dismiss) var dismiss
    
    @State private var showingAddFacility = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var facilitiesToDelete: Set<String> = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ヘッダー
                VStack(alignment: .leading, spacing: 8) {
                    Text("施設管理")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("登録済み施設の管理と新規追加")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top)
                
                // 施設一覧
                List {
                    ForEach(userManager.getAllFacilities(), id: \.facilityId) { facility in
                        FacilityRowView(facility: facility)
                            .environmentObject(userManager)
                    }
                    .onDelete(perform: deleteFacilities)
                }
                .listStyle(PlainListStyle())
                
                // 新規追加ボタン
                Button(action: { showingAddFacility = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("新規施設追加")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddFacility) {
            AddFacilityView()
                .environmentObject(userManager)
        }
        .alert("確認", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func deleteFacilities(offsets: IndexSet) {
        let facilities = userManager.getAllFacilities()
        
        for index in offsets {
            let facility = facilities[index]
            if userManager.removeFacility(facilityId: facility.facilityId) {
                alertMessage = "施設「\(facility.facilityName)」を削除しました"
            } else {
                alertMessage = "施設の削除に失敗しました"
            }
        }
        
        showingAlert = true
    }
}

// MARK: - 施設行表示
struct FacilityRowView: View {
    @EnvironmentObject var userManager: UserManager
    let facility: FacilityMaster
    
    var body: some View {
        HStack(spacing: 12) {
            // ステータスインジケーター
            Circle()
                .fill(facility.isActive ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("ID: \(facility.facilityId)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text(facility.isActive ? "有効" : "無効")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(facility.isActive ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                        .foregroundColor(facility.isActive ? .green : .red)
                        .cornerRadius(4)
                }
                
                Text(facility.facilityName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            // 有効/無効切り替えボタン
            Button(action: {
                _ = userManager.toggleFacilityStatus(facilityId: facility.facilityId)
            }) {
                Image(systemName: facility.isActive ? "pause.circle" : "play.circle")
                    .foregroundColor(facility.isActive ? .orange : .green)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 新規施設追加画面
struct AddFacilityView: View {
    @EnvironmentObject var userManager: UserManager
    @Environment(\.dismiss) var dismiss
    
    @State private var facilityId = ""
    @State private var facilityName = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // ヘッダー
                VStack(spacing: 8) {
                    Text("新規施設追加")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("施設IDと施設名を入力してください")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 32)
                
                Spacer()
                
                // 入力フォーム
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("施設ID")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("施設IDを入力 (例: 006)", text: $facilityId)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("施設名")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("施設名を入力 (例: ○○病院)", text: $facilityName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .padding(.horizontal, 20)
                
                // 注意事項
                VStack(spacing: 4) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                        
                        Text("施設IDは他の施設と重複しないようにしてください")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("登録後は即座にログインに利用できます")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                
                // 登録ボタン
                Button(action: addFacility) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("施設を登録")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isAddEnabled ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!isAddEnabled)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                Spacer()
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
        .alert("施設登録", isPresented: $showingAlert) {
            Button("OK") {
                if alertMessage.contains("成功") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var isAddEnabled: Bool {
        !facilityId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !facilityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func addFacility() {
        let result = userManager.addFacility(
            facilityId: facilityId.trimmingCharacters(in: .whitespacesAndNewlines),
            facilityName: facilityName.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        switch result {
        case .success:
            alertMessage = "施設「\(facilityName)」を正常に登録しました"
        case .failure(let error):
            alertMessage = error.localizedDescription
        }
        
        showingAlert = true
    }
}

#Preview {
    LoginView()
        .environmentObject(UserManager())
}
