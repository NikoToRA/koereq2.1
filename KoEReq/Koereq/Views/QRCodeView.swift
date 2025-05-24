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
    @State private var showingShareSheet = false
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
                    if qrImage != nil {
                        // 共有ボタン
                        Button(action: shareQRCode) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("共有")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        // 写真に保存ボタン
                        Button(action: saveToPhotos) {
                            HStack {
                                Image(systemName: "photo.badge.plus")
                                Text("写真に保存")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    
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
        .sheet(isPresented: $showingShareSheet) {
            if let qrImage = qrImage {
                ShareSheet(items: [qrImage])
            }
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
    
    private func shareQRCode() {
        showingShareSheet = true
    }
    
    private func saveToPhotos() {
        guard let qrImage = qrImage else { return }
        
        qrService.saveQRCodeToPhotos(qrImage)
        
        // 保存完了メッセージ
        alertMessage = "QRコードを写真に保存しました"
        showingAlert = true
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // iPadでの表示設定
        if let popover = controller.popoverPresentationController {
            popover.sourceView = UIApplication.shared.windows.first?.rootViewController?.view
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    QRCodeView(content: "これはサンプルのAI応答内容です。QRコードとして表示されます。")
        .environmentObject(QRService())
}
