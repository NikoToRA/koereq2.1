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
    @State private var showCloseButton = false
    
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
                        if content.count > 500 {
                            Text("読み取りやすさ重視で分割処理中（\(content.count)文字 → 500文字ずつ）")
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
                    GeometryReader { geometry in
                        ScrollViewReader { proxy in
                            ScrollView(.vertical, showsIndicators: false) {
                                LazyVStack(spacing: 60) {
                                    ForEach(0..<qrImages.count, id: \.self) { index in
                                        VStack(spacing: 20) {
                                            // QRコード画像（最大化、番号なし）
                                            Image(uiImage: qrImages[index])
                                                .interpolation(.none)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: min(geometry.size.width - 40, 350), 
                                                       height: min(geometry.size.width - 40, 350))
                                                .background(Color.white)
                                                .cornerRadius(20)
                                                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
                                        }
                                        .id(index)
                                        .onAppear {
                                            // 最後のQRコードが表示された時に閉じるボタンを表示
                                            if index == qrImages.count - 1 {
                                                withAnimation(.easeInOut(duration: 0.5)) {
                                                    showCloseButton = true
                                                }
                                            }
                                        }
                                        .onDisappear {
                                            // 最後のQRコードが見えなくなったら閉じるボタンを非表示
                                            if index == qrImages.count - 1 {
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    showCloseButton = false
                                                }
                                            }
                                        }
                                    }
                                    
                                    // 余白のみ
                                    Spacer()
                                        .frame(height: showCloseButton ? 80 : 20)
                                }
                                .padding(.top, 20)
                            }
                        }
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
                
                // 閉じるボタン（最後のQRコードが見えた時のみ）
                if showCloseButton && !isLoading {
                    VStack {
                        Spacer()
                        
                        Button(action: { dismiss() }) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                Text("閉じる")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(25)
                        }
                        .padding(.bottom, 30)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
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
        isLoading = true
        qrImages = []
        
        // プレビューでテキストの長さを表示
        if content.count > 500 {
            loadingProgress = "読み取りやすさ重視で分割中（\(content.count)文字 → 500文字ずつ）..."
        } else {
            loadingProgress = "高品質QRコード生成中..."
        }
        
        Task {
            let images = await qrService.generateQRCodesAsync(from: content)
            await MainActor.run {
                print("[QRCodeView] Received \(images.count) QR images")
                if images.isEmpty {
                    // エラー状態
                    isLoading = false
                    alertMessage = "QRコードの生成に失敗しました。テキストが長すぎるか、システムエラーが発生した可能性があります。"
                    showingAlert = true
                } else {
                    qrImages = images
                    isLoading = false
                    print("[QRCodeView] QR codes generated successfully: \(images.count) codes")
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
