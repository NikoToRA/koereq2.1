//
//  KoEReqApp.swift
//  KoEReq
//
//  Created by KoEReq Team on 2025/05/23.
//

import SwiftUI

@main
struct KoEReqApp: App {
    @StateObject private var userManager = UserManager()
    @StateObject private var sessionStore = SessionStore()
    @StateObject private var promptManager = PromptManager()
    @StateObject private var recordingService = RecordingService()
    @StateObject private var sttService = STTService()
    @StateObject private var openAIService = OpenAIService()
    @StateObject private var storageService = StorageService()
    @StateObject private var qrService = QRService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userManager)
                .environmentObject(sessionStore)
                .environmentObject(promptManager)
                .environmentObject(recordingService)
                .environmentObject(sttService)
                .environmentObject(openAIService)
                .environmentObject(storageService)
                .environmentObject(qrService)
        }
    }
}