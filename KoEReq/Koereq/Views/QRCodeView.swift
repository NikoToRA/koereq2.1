//
//  QRCodeView.swift
//  Koereq
//
//  Created by Koereq Team on 2025/05/23.
//

import SwiftUI

struct QRCodeView: View {
    let content: String
    
    @EnvironmentObject var qrService: QRService
    @Environment(\.dismiss) private var dismiss
    
    @State private var qrImage: UIImage?

    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // ヘッダー
                VStack(spacing: 8) {
                    Text("QRコード")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("AI応答内容をQRコードで共有")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // QRコード表示
                if let qrImage = qrImage {
                    VStack(spacing: 20) {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 250, height: 250)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        
                        Text("QRコードを読み取って内容を確認")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("QRコード生成中...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // アクションボタン
                VStack(spacing: 16) {

                    
                    // 閉じるボタン
                    Button(action: { dismiss() }) {
                        Text("閉じる")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            generateQRCode()
        }

        .alert("通知", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func generateQRCode() {
        Task {
            let image = await qrService.generateQRCodeAsync(from: content)
            await MainActor.run {
                qrImage = image
            }
        }
    }
    

    

}



#Preview {
    QRCodeView(content: "これはサンプルのAI応答内容です。QRコードとして表示されます。")
        .environmentObject(QRService())
}
