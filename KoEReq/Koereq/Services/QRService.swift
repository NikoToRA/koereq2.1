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
    
    // QRコードの文字数制限を読み取り精度最優先で設定
    private let maxCharacters = 300 // 読み取り精度最優先（400から300に減少）
    
    func generateQRCode(from text: String) -> UIImage? {
        print("[QRService] generateQRCode called with text length: \(text.count)")
        
        guard !text.isEmpty else {
            self.error = QRError.invalidText
            return nil
        }
        
        guard let data = text.data(using: .utf8) else {
            self.error = QRError.invalidText
            return nil
        }
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            self.error = QRError.filterNotAvailable
            return nil
        }
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel") // 最高エラー訂正レベル
        
        guard let ciImage = filter.outputImage else {
            self.error = QRError.generationFailed
            return nil
        }
        
        // 最高速度：シンプルなスケーリング
        let scale: CGFloat = 10.0
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        // 最高読み取り精度：適切な白枠
        let padding: CGFloat = 40.0
        let finalSize = CGSize(
            width: scaledImage.extent.width + padding * 2,
            height: scaledImage.extent.height + padding * 2
        )
        
        // 高速描画
        UIGraphicsBeginImageContextWithOptions(finalSize, true, 0)
        UIColor.white.setFill()
        UIRectFill(CGRect(origin: .zero, size: finalSize))
        
        let context = CIContext()
        if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
            UIImage(cgImage: cgImage).draw(in: CGRect(
                x: padding,
                y: padding,
                width: scaledImage.extent.width,
                height: scaledImage.extent.height
            ))
        }
        
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let result = finalImage else {
            self.error = QRError.renderingFailed
            return nil
        }
        
        print("[QRService] QR code generated successfully")
        self.generatedQRCode = result
        return result
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
                let chunkWithHeader = chunk
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
        
        // 制限値（少し余裕を持たせる）
        let safeLimit = maxCharacters - 10 // 少し余裕を持たせる
        
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
        
        isGenerating = true
        
        var qrImages: [UIImage] = []
        
        // テキストが制限を超えている場合は分割
        if text.count > maxCharacters {
            print("[QRService] Text exceeds \(maxCharacters) char limit, splitting into chunks")
            let textChunks = splitText(text)
            print("[QRService] Split into \(textChunks.count) chunks")
            
            for (index, chunk) in textChunks.enumerated() {
                let finalText = chunk
                print("[QRService] Generating QR code \(index + 1)/\(textChunks.count)")
                
                if let qrImage = generateQRCode(from: finalText) {
                    qrImages.append(qrImage)
                    print("[QRService] QR code \(index + 1) generated successfully")
                }
            }
        } else {
            print("[QRService] Generating single QR code")
            if let qrImage = generateQRCode(from: text) {
                qrImages.append(qrImage)
                print("[QRService] Single QR code generated successfully")
            }
        }
        
        isGenerating = false
        generatedQRCodes = qrImages
        
        print("[QRService] Total QR codes generated: \(qrImages.count)")
        return qrImages
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
