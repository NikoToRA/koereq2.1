//
//  ContentView.swift
//  Koereq
//
//  Created by Koereq Team on 2025/05/23.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        Group {
            if userManager.isLoggedIn {
                HomeView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: userManager.isLoggedIn)
    }
}

#Preview {
    ContentView()
        .environmentObject(UserManager())
        .environmentObject(SessionStore())
        .environmentObject(PromptManager())
        .environmentObject(RecordingService())
        .environmentObject(STTService())
        .environmentObject(OpenAIService())
        .environmentObject(StorageService())
        .environmentObject(QRService())
}
