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
    
    @State private var qrImages: [UIImage] = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = true
    @State private var loadingProgress = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // メインコンテンツ
                if isLoading {
                    // ローディング表示
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text(loadingProgress.isEmpty ? "QRコード生成中..." : loadingProgress)
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        // プレビューでテキストの長さを表示
                        if content.count > 300 {
                            Text("読み取り精度最優先で分割処理中（\(content.count)文字 → 300文字ずつ）")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .multilineTextAlignment(.center)
                        }
                        
                        // キャンセルボタン
                        Button(action: { dismiss() }) {
                            Text("キャンセル")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                    }
                } else if !qrImages.isEmpty {
                    // QRコード一覧をフルスクリーン表示
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 40) {
                            ForEach(0..<qrImages.count, id: \.self) { index in
                                VStack(spacing: 20) {
                                    
                                    // QRコード画像
                                    Image(uiImage: qrImages[index])
                                        .interpolation(.high)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 300, height: 300)
                                        .background(Color.white)
                                        .cornerRadius(16)
                                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                }
                                .id(index)
                                .onAppear {
                                    print("[QRCodeView] QR code \(index + 1) appeared")
                                }
                            }
                            
                            // 余白
                            Spacer()
                                .frame(height: 30)
                        }
                        .padding(.top, 20)
                        .padding(.horizontal, 20)
                    }
                } else {
                    // エラー状態
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        
                        Text("QRコード生成に失敗しました")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("再度お試しください")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button(action: retry) {
                            Text("再試行")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            generateQRCodes()
        }
        .onChange(of: qrService.isGenerating) { _, isGenerating in
            if isGenerating {
                loadingProgress = "QRコード生成中..."
            }
        }
        .alert("エラー", isPresented: $showingAlert) {
            Button("OK") { }
            Button("再試行") { retry() }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func generateQRCodes() {
        print("[QRCodeView] generateQRCodes called with content length: \(content.count)")
        print("[QRCodeView] Content preview: \(String(content.prefix(100)))...")
        isLoading = true
        qrImages = []
        
        // プレビューでテキストの長さを表示
        if content.count > 300 {
            loadingProgress = "読み取り精度最優先で分割中（\(content.count)文字 → 300文字ずつ）..."
        } else {
            loadingProgress = "高品質QRコード生成中..."
        }
        
        Task {
            print("[QRCodeView] Starting async QR generation")
            let images = await qrService.generateQRCodesAsync(from: content)
            
            await MainActor.run {
                print("[QRCodeView] Received \(images.count) QR images")
                
                if images.isEmpty {
                    print("[QRCodeView] No images received - showing error")
                    // エラー状態
                    isLoading = false
                    alertMessage = "QRコードの生成に失敗しました。テキストが長すぎるか、システムエラーが発生した可能性があります。"
                    showingAlert = true
                } else {
                    print("[QRCodeView] Setting \(images.count) images and updating UI")
                    qrImages = images
                    isLoading = false
                    print("[QRCodeView] QR codes generated successfully: \(images.count) codes")
                    print("[QRCodeView] isLoading: \(isLoading), qrImages.count: \(qrImages.count)")
                }
            }
        }
    }
    
    private func retry() {
        print("[QRCodeView] Retry requested")
        generateQRCodes()
    }
}

#Preview {
    QRCodeView(content: "これはサンプルのAI応答内容です。QRコードとして表示されます。")
        .environmentObject(QRService())
}
