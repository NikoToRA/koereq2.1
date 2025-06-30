//
//  KoereqApp.swift
//  Koereq
//
//  Created by Hirayama Suguru on 2025/05/23.
//

import SwiftUI

@main
struct KoereqApp: App {
    // let persistenceController = PersistenceController.shared // コメントアウト
    @StateObject var userManager = UserManager()
    @StateObject var sessionStore = SessionStore() // SessionStoreはCoreDataなしで初期化される
    @StateObject var promptManager = PromptManager()
    @StateObject var recordingService = RecordingService()
    @StateObject var sttService = STTService()
    @StateObject var openAIService = OpenAIService()
    @StateObject var storageService = StorageService()
    @StateObject var qrService = QRService()
    @StateObject var simpleMedicalGuideManager = SimpleMedicalGuideManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                // .environment(\.managedObjectContext, persistenceController.container.viewContext) // コメントアウト
                .environmentObject(userManager)
                .environmentObject(sessionStore)
                .environmentObject(promptManager)
                .environmentObject(recordingService)
                .environmentObject(sttService)
                .environmentObject(openAIService)
                .environmentObject(storageService)
                .environmentObject(qrService)
                .environmentObject(simpleMedicalGuideManager)
        }
    }
}
