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
    @Published var error: Error?
    
    func generateQRCode(from text: String) -> UIImage? {
        guard let data = text.data(using: .utf8) else {
            self.error = QRError.invalidText
            return nil
        }
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            self.error = QRError.filterNotAvailable
            return nil
        }
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel") // High error correction
        
        guard let ciImage = filter.outputImage else {
            self.error = QRError.generationFailed
            return nil
        }
        
        // QRコードを高解像度にスケールアップ
        let scaleX = 200 / ciImage.extent.size.width
        let scaleY = 200 / ciImage.extent.size.height
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            self.error = QRError.renderingFailed
            return nil
        }
        
        let uiImage = UIImage(cgImage: cgImage)
        
        self.generatedQRCode = uiImage
        
        return uiImage
    }
    
    func generateQRCodeAsync(from text: String) async -> UIImage? {
        return generateQRCode(from: text)
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
