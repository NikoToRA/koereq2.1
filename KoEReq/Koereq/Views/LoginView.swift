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
                        Text("施設ID")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("施設IDを入力", text: $facilityId)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    

                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("施設名")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("施設名を入力", text: $facilityName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
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
                    Text("Apple標準音声認識 + Azure OpenAI")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Version 2.1.0")
                        .font(.caption2)
                        .foregroundColor(.secondary)
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
    }
    
    private var isLoginEnabled: Bool {
        !facilityId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !facilityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func login() {
        let trimmedFacilityId = facilityId.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedFacilityName = facilityName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 基本的なバリデーション
        guard trimmedFacilityId.count >= 3 else {
            showAlert(message: "施設IDは3文字以上で入力してください")
            return
        }
        
        guard trimmedFacilityName.count >= 2 else {
            showAlert(message: "施設名は2文字以上で入力してください")
            return
        }
        
        // ログイン処理
        userManager.login(
            facilityId: trimmedFacilityId,
            facilityName: trimmedFacilityName
        )
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showingAlert = true
    }
}

#Preview {
    LoginView()
        .environmentObject(UserManager())
}
