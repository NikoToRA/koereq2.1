//
//  PatientsDetailView.swift
//  Talk_AI_Medicalassitant_3
//

import SwiftUI
import Combine
import AudioToolbox

struct PatientsDetailView: View {
    @Environment(\.dialogViewModel) var dialogViewModel
    @EnvironmentObject var navigationRouter: NavigationRouter
    
    @StateObject var speechManager: SpeechRecognitionManager
    @StateObject var patientsViewModel: PatientsViewModel
    
    @StateObject var chatViewModel: ChatViewModel = ChatViewModel()
    
    @State var isRecording: Bool = false
    @State var inputText: String = ""
    
    @State private var chatMessages: [ChatMessage] = []
    @State private var customPrompts: [Prompt] = []
    @State private var voiceRecognitionSubscription: AnyCancellable?
    
    var patientData: Patients
    
    var body: some View {
        VStack(alignment: .center) {
          VStack(alignment: .trailing, spacing: 16) {
              ScrollViewReader { proxy in
                  ScrollView {
                      ForEach(chatMessages, id: \.self.id) { message in
                          MessageView(chatData: message, onQRTapped: {
                              if message.role == "qr" {
                                  navigationRouter.pushPage(id: .init(label: QRCodeDetailView.label(String(patientData.patient_id))),
                                                            destination: {
                                      QRCodeDetailView(chatViewModel: chatViewModel,
                                                       patientData: patientData,
                                                       messageContent: message.content)
                                                                
                                                            })
                              }
                          })
                      }
                  }
                  .padding(12)
                  .onChange(of: chatMessages.count) {
                      if let lastId = chatMessages.last?.id {
                          withAnimation {
                              proxy.scrollTo(lastId, anchor: .bottom)
                          }
                      }
                  }
              }
          }
          .frame(maxWidth: .infinity)
            
            VStack(alignment: .center, spacing: 0) {
                
                VStack(alignment: .center, spacing: 14) {
                    
                HStack(spacing: 8) {
                    
                    Button(action: {
                        sendToAI(promptId: "A", name: chatViewModel.buttonName["A"]!)
                    }) {
                        Text("カルテ\n作成")
                          .font(Font.custom("Noto Sans JP", size: 16))
                          .foregroundColor(.white)
                          .multilineTextAlignment(.center)
                          .lineLimit(2)
                          .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.48, green: 0.75, blue: 0.96),
                                Color(red: 0.22, green: 0.55, blue: 0.80)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(15)
                      
                  Button(action: {
                      sendToAI(promptId: "B", name: chatViewModel.buttonName["B"]!)
                  }) {
                      Text("紹介状\n作成")
                          .font(Font.custom("Noto Sans JP", size: 16))
                          .foregroundColor(.white)
                          .multilineTextAlignment(.center)
                          .lineLimit(2)
                          .fixedSize(horizontal: false, vertical: true)
                  }
                  .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                  .background(
                      LinearGradient(
                          gradient: Gradient(colors: [
                              Color(red: 0.48, green: 0.75, blue: 0.96),
                              Color(red: 0.22, green: 0.55, blue: 0.80)
                          ]),
                          startPoint: .leading,
                          endPoint: .trailing
                      )
                  )
                  .cornerRadius(15)
           
                    Button(action: {
                        sendToAI(promptId: "C", name: chatViewModel.buttonName["C"]!)
                    }) {
                        Text("IC用\nまとめ")
                            .font(Font.custom("Noto Sans JP", size: 16))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.48, green: 0.75, blue: 0.96),
                                Color(red: 0.22, green: 0.55, blue: 0.80)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(15)
                    
                    Menu {
                        // 取得したボタン情報の一覧を表示
                        ForEach(self.customPrompts, id: \.prompt_id) { buttonInfo in
                            Button(action: {
                                sendToAI(promptId: String(buttonInfo.prompt_id), name: buttonInfo.prompt_name)
                            }) {
                                Text(buttonInfo.prompt_name)
                                    .font(Font.custom("Noto Sans JP", size: 12))
                            }
                        }
                    } label: {
                        Text("カスタム")
                            .font(Font.custom("Noto Sans JP", size: 14))
                            .foregroundColor(Color(red: 0.22, green: 0.55, blue: 0.80))
                            .padding(EdgeInsets(top: 18, leading: 12, bottom: 18, trailing: 12))
                            .cornerRadius(100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .inset(by: 0.50)
                                    .stroke(Color(red: 0.94, green: 0.95, blue: 0.96), lineWidth: 1.50)
                            )
                    }
                    .if(chatViewModel.customPrompts.isEmpty) { view in
                         view.visibility(.invisible)
                    }
                }
                  
                HStack(spacing: 12) {
                    ZStack(alignment: .topLeading) {
                        AutoScrollingTextView(
                            text: $inputText,
                            font: UIFont(name: "Noto Sans JP", size: 16) ?? UIFont.systemFont(ofSize: 16),
                            textColor: UIColor(red: 0.56, green: 0.59, blue: 0.62, alpha: 1),
                            // AutoScrollingTextView 内部で背景色を設定しないことで、親の背景が見えるようにする
                            backgroundColor: .clear
                        )
                        .frame(height: 50)
                        
                        if inputText.isEmpty {
                            Text("患者情報を音声入力してください")
                                .font(Font.custom("Noto Sans JP", size: 16))
                                .foregroundColor(.gray)
                                .padding(EdgeInsets(top: 8, leading: 4, bottom: 0, trailing: 0))
                                .allowsHitTesting(false)
                        }
                    }
                    .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                    .background(Color(red: 0.95, green: 0.96, blue: 0.98))
                    .cornerRadius(8)
                    
                    RecordingButtonView(isRecording: $isRecording,
                      startRecording: {
                        speechManager.startRecording()
                        isRecording = true
                    },
                      stopRecording: {
                        let _ = speechManager.stopRecording()
                        isRecording = false

                        let diff = inputText.difference(from: speechManager.currentText)
                        if !diff.isEmpty {
                            chatViewModel.isLoading = true
                            self.sendMessage(inputText)
                            speechManager.currentText = ""
                        }
                    })
                    .frame(width: 48, height: 48)
                    .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                }
                .frame(maxWidth: .infinity)
                  
              }
              .padding(12)
              .frame(width: .infinity, height: 160)
              .background(.white)
                
            }
            .frame(width: .infinity, height: 155)

        }
        .frame(width: .infinity, height: .infinity)
        .background(Color(red: 0.94, green: 0.95, blue: 0.96))
        .onReceive(chatViewModel.$messages) { newMessages in
            // 新しい AI メッセージのみを取得
            let newAIResponses = newMessages.filter { !$0.isFromUser }

            // 既存のメッセージを除外
            let existingMessageIDs = Set(chatMessages.map { $0.id })
            let uniqueNewMessages = newAIResponses.filter { !existingMessageIDs.contains($0.id) }

            // 新しい AI メッセージを追加
            if !uniqueNewMessages.isEmpty {
                self.chatMessages.append(contentsOf: uniqueNewMessages)
            }
            
        }
        .onReceive(speechManager.$transcribedText) { text in
            // 重複したテキストは先に省く (音声認識中は bestTranscription.formattedString をリセットできない件のカバー)
            let diff = text.difference(from: speechManager.currentText)
            inputText = diff
        }
        .onAppear() {
            if !self.chatMessages.isEmpty {
                return
            }
            
            // チャットデータ一覧を取得
            chatViewModel.fetchPatientChatList(patientId: patientData.patient_id, completion: {
                res in
                
                switch res {
                case .success(_):
                    self.chatMessages =  chatViewModel.messages
                    
                case .failure(let error):
                    let dialogContent = DialogContent(title: "失敗",      message: error.message,
                           isCancelable: false, buttons:[(DialogButtonType.positive, "閉じる")])
                                                
                      dialogViewModel.show(content: dialogContent,
                        positiveAction: { dialogViewModel.dismiss() },
                        negativeAction: { dialogViewModel.dismiss() }
                      )
                }
            })
            
            // カスタムプロンプトデータ一覧を取得
            chatViewModel.fetchCustomPromptList(completion: {
                res in
                
                switch res {
                case .success(_):
                    self.customPrompts =  chatViewModel.customPrompts
                    
                case .failure(let error):
                    let dialogContent = DialogContent(title: "失敗",      message: error.message,
                           isCancelable: false, buttons:[(DialogButtonType.positive, "閉じる")])
                                                
                      dialogViewModel.show(content: dialogContent,
                        positiveAction: { dialogViewModel.dismiss() },
                        negativeAction: { dialogViewModel.dismiss() }
                      )
                }
            })
            
            speechManager.clearText()
            voiceRecognitionSubscription = speechManager.autoSendTrigger
                .receive(on: DispatchQueue.main)
                .sink { text in
                    self.sendMessage(text)
                    speechManager.currentText = text
                    speechManager.hasAutoSent = false
                }
        }
        .onDisappear {
            let _ = speechManager.stopRecording()
            voiceRecognitionSubscription?.cancel()
            voiceRecognitionSubscription = nil
        }
        .withHeader(title: patientData.title, canBack: true, icon: "patient_" + patientData.icon_type)
        .onChange(of: chatViewModel.isLoading) {
            old, loading in
            dialogViewModel.isShowIndicator = loading
        }
        
    }
    
    private func sendMessage(_ text: String) {
        // 重複したテキストは先に省く (音声認識中は bestTranscription.formattedString をリセットできない件のカバー)
        let diff = text.difference(from: speechManager.currentText)
        if diff.isEmpty {
            return
        }
        
        let newMessage = ChatMessage(
            id: UUID(),
            content: diff,
            isFromUser: true,
            isHidden: false,
            role: "user"
        )
        chatMessages.append(newMessage)
        chatViewModel.conversation.append(newMessage)
        
        // チャット更新内容をAPIに投げる
        chatViewModel.sendChatMessage(newMessage: newMessage, completion: {
            (res) in
            
            switch res {
            case .success(_):
                break
            case .failure(let error):
                showErrorDialog(error: error)
            }
        })

        inputText = ""
        speechManager.clearText()
    }
    
    // private func sendToAI(type: AIpromptType) {
    private func sendToAI(promptId: String, name: String) {
        // 効果音を鳴らす
        AudioServicesPlaySystemSound(1004)
        
        // 入力テキストをトリム
        let userInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)

        // 新しいユーザーメッセージを追加（入力があれば）
        if !userInput.isEmpty {
            let newMessage = ChatMessage(
                id: UUID(),
                content: userInput,
                isFromUser: true,
                isHidden: false,
                role: "user"
            )
            chatMessages.append(newMessage)
            chatViewModel.conversation.append(newMessage)

            // 入力テキストをクリア
            inputText = ""
            speechManager.clearText()
        }
        
        // AI指示をユーザコメントとして投げる
        let command = ChatMessage(id: UUID(), content: "【" + name + "】",
                                  isFromUser: true, isHidden: false, role: "user")
        chatMessages.append(command)

        chatViewModel.instructAI(promptId: promptId, title: patientData.title, command: command, completion: { (res) in
            switch res {
            case .success(_):
                break
            case .failure(let error):
                showErrorDialog(error: error)
            }
        })
        

    }
    
    private func showErrorDialog(error: DisplayError) {
        let dialogContent = DialogContent(title: "失敗", message: error.message,
                                          isCancelable: false, buttons:[(DialogButtonType.positive, "閉じる")])
                                    
        dialogViewModel.show(content: dialogContent,
                             positiveAction: { dialogViewModel.dismiss() },
                             negativeAction: { dialogViewModel.dismiss() }
        )
    }
    
}

struct PatientsDetailView_Previews: PreviewProvider {
    static var previews: some View {
        PatientsDetailView(speechManager: .init(), patientsViewModel: .init(), patientData: Patients(patient_id: 1, title: "aaa", created_at: "aaa", icon_type: "patinets_man_20"))
    }
}

