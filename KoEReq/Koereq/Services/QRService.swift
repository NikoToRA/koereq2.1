//
//  QRService.swift
//  Koereq
//
//  Created by Koereq Team on 2025/05/23.
//

import Foundation
import CoreImage
import UIKit

@MainActor
class QRService: ObservableObject {
    @Published var generatedQRCode: UIImage?
    @Published var generatedQRCodes: [UIImage] = []
    @Published var error: Error?
    @Published var isGenerating = false
    
    // QRコードの文字数制限を読み取りやすさ重視で設定
    private let maxCharacters = 500 // 読み取り精度を優先した制限値
    
    func generateQRCode(from text: String) -> UIImage? {
        print("[QRService] generateQRCode called with text length: \(text.count)")
        
        guard !text.isEmpty else {
            print("[QRService] Error: Empty text provided")
            self.error = QRError.invalidText
            return nil
        }
        
        guard let data = text.data(using: .utf8) else {
            print("[QRService] Error: Failed to convert text to UTF8 data")
            self.error = QRError.invalidText
            return nil
        }
        
        print("[QRService] Text data size: \(data.count) bytes")
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            print("[QRService] Error: CIQRCodeGenerator filter not available")
            self.error = QRError.filterNotAvailable
            return nil
        }
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel") // Medium error correction for better capacity
        
        guard let ciImage = filter.outputImage else {
            print("[QRService] Error: Failed to generate CIImage")
            self.error = QRError.generationFailed
            return nil
        }
        
        print("[QRService] CIImage generated successfully, size: \(ciImage.extent)")
        
        // QRコードをより高解像度にスケールアップ（読み取り精度向上）
        let scaleX = 300 / ciImage.extent.size.width  // 200 → 300 に増加
        let scaleY = 300 / ciImage.extent.size.height
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            print("[QRService] Error: Failed to create CGImage")
            self.error = QRError.renderingFailed
            return nil
        }
        
        let uiImage = UIImage(cgImage: cgImage)
        print("[QRService] QR code generated successfully with improved resolution")
        
        self.generatedQRCode = uiImage
        return uiImage
    }
    
    func generateQRCodes(from text: String) -> [UIImage] {
        print("[QRService] generateQRCodes called with text length: \(text.count)")
        var qrImages: [UIImage] = []
        
        // テキストが制限を超えている場合は分割
        if text.count > maxCharacters {
            print("[QRService] Text exceeds \(maxCharacters) char limit, splitting into readable chunks")
            let textChunks = splitText(text)
            print("[QRService] Split into \(textChunks.count) chunks for better readability")
            
            for (index, chunk) in textChunks.enumerated() {
                let chunkWithHeader = "[\(index + 1)/\(textChunks.count)] \(chunk)"
                print("[QRService] Generating QR code \(index + 1)/\(textChunks.count), text length: \(chunkWithHeader.count)")
                
                if let qrImage = generateQRCode(from: chunkWithHeader) {
                    qrImages.append(qrImage)
                    print("[QRService] QR code \(index + 1) generated successfully")
                } else {
                    print("[QRService] Failed to generate QR code \(index + 1)")
                    // エラーが発生した場合でも処理を続行
                    continue
                }
            }
        } else {
            print("[QRService] Text within \(maxCharacters) char limit, generating single high-quality QR code")
            if let qrImage = generateQRCode(from: text) {
                qrImages.append(qrImage)
                print("[QRService] Single high-quality QR code generated successfully")
            } else {
                print("[QRService] Failed to generate single QR code")
            }
        }
        
        print("[QRService] Total QR codes generated: \(qrImages.count)")
        self.generatedQRCodes = qrImages
        return qrImages
    }
    
    private func splitText(_ text: String) -> [String] {
        print("[QRService] splitText called with text length: \(text.count)")
        var chunks: [String] = []
        var currentChunk = ""
        
        // 改行で分割してから単語で分割
        let paragraphs = text.components(separatedBy: .newlines)
        
        // ヘッダー分の余裕を考慮した制限（より保守的に）
        let safeLimit = maxCharacters - 30 // "[X/Y] "分を考慮して30文字余裕
        
        for paragraph in paragraphs {
            let words = paragraph.components(separatedBy: " ")
            
            for word in words {
                let testChunk = currentChunk.isEmpty ? word : "\(currentChunk) \(word)"
                
                if testChunk.count <= safeLimit {
                    currentChunk = testChunk
                } else {
                    if !currentChunk.isEmpty {
                        chunks.append(currentChunk)
                        print("[QRService] Chunk created with length: \(currentChunk.count) (limit: \(safeLimit))")
                        currentChunk = word
                    } else {
                        // 単語自体が長すぎる場合は文字単位で分割
                        let truncatedWord = String(word.prefix(safeLimit))
                        chunks.append(truncatedWord)
                        print("[QRService] Long word truncated to length: \(truncatedWord.count)")
                        currentChunk = String(word.dropFirst(safeLimit))
                    }
                }
            }
            
            // 段落の終わりで改行を追加
            if !currentChunk.isEmpty && currentChunk.count < safeLimit - 1 {
                currentChunk += "\n"
            }
        }
        
        if !currentChunk.isEmpty {
            chunks.append(currentChunk)
            print("[QRService] Final chunk created with length: \(currentChunk.count)")
        }
        
        print("[QRService] Text split into \(chunks.count) readable chunks")
        return chunks
    }
    
    func generateQRCodeAsync(from text: String) async -> UIImage? {
        print("[QRService] generateQRCodeAsync called")
        return await withCheckedContinuation { continuation in
            Task { @MainActor in
                let result = generateQRCode(from: text)
                continuation.resume(returning: result)
            }
        }
    }
    
    func generateQRCodesAsync(from text: String) async -> [UIImage] {
        print("[QRService] generateQRCodesAsync called")
        await MainActor.run {
            self.isGenerating = true
        }
        
        let result = await withCheckedContinuation { continuation in
            Task { @MainActor in
                let qrCodes = generateQRCodes(from: text)
                continuation.resume(returning: qrCodes)
            }
        }
        
        await MainActor.run {
            self.isGenerating = false
        }
        
        return result
    }
    
    func saveQRCodeToPhotos(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            self.error = QRError.saveFailed(error.localizedDescription)
        }
    }
    
    func shareQRCode(_ image: UIImage) -> UIActivityViewController {
        let activityViewController = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        // iPadでの表示設定
        if let popover = activityViewController.popoverPresentationController {
            if #available(iOS 15.0, *) {
                // Find the first active UIWindowScene
                let windowScene = UIApplication.shared.connectedScenes
                    .filter { $0.activationState == .foregroundActive }
                    .first { $0 is UIWindowScene }
                    as? UIWindowScene
                popover.sourceView = windowScene?.windows.first?.rootViewController?.view
            } else {
                popover.sourceView = UIApplication.shared.windows.first?.rootViewController?.view
            }
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        return activityViewController
    }
    
    func createQRCodeWithLogo(_ text: String, logo: UIImage? = nil) -> UIImage? {
        guard let qrImage = generateQRCode(from: text) else { return nil }
        
        guard let logo = logo else { return qrImage }
        
        let qrSize = qrImage.size
        let logoSize = CGSize(width: qrSize.width * 0.2, height: qrSize.height * 0.2)
        
        UIGraphicsBeginImageContextWithOptions(qrSize, false, 0)
        
        // QRコードを描画
        qrImage.draw(in: CGRect(origin: .zero, size: qrSize))
        
        // ロゴを中央に描画
        let logoRect = CGRect(
            x: (qrSize.width - logoSize.width) / 2,
            y: (qrSize.height - logoSize.height) / 2,
            width: logoSize.width,
            height: logoSize.height
        )
        
        // ロゴの背景を白くする
        UIColor.white.setFill()
        let backgroundRect = logoRect.insetBy(dx: -5, dy: -5)
        UIBezierPath(roundedRect: backgroundRect, cornerRadius: 5).fill()
        
        logo.draw(in: logoRect)
        
        let combinedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return combinedImage
    }
}

enum QRError: Error, LocalizedError {
    case invalidText
    case filterNotAvailable
    case generationFailed
    case renderingFailed
    case saveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidText:
            return "無効なテキストです"
        case .filterNotAvailable:
            return "QRコードフィルターが利用できません"
        case .generationFailed:
            return "QRコードの生成に失敗しました"
        case .renderingFailed:
            return "QRコードのレンダリングに失敗しました"
        case .saveFailed(let message):
            return "QRコードの保存に失敗しました: \(message)"
        }
    }
}
