//
//  NursingPromptManagerView.swift
//  Koereq
//
//  Created by Koereq Team on 2025/06/30.
//

import SwiftUI

struct NursingPromptManagerView: View {
    @EnvironmentObject var promptManager: PromptManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditPrompt = false
    @State private var editingPrompt: CustomPrompt?
    
    var nursingPrompts: [CustomPrompt] {
        promptManager.customPrompts.filter { $0.name.contains("救急看護師") || $0.name.contains("看護") }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(nursingPrompts) { prompt in
                        NursingPromptRow(
                            prompt: prompt
                        ) {
                            editingPrompt = prompt
                            showingEditPrompt = true
                        }
                    }
                } header: {
                    Text("救急看護師専用プロンプト")
                } footer: {
                    Text("使用したいプロンプトを選択してください。AIの応答スタイルが変更されます。")
                        .font(.caption)
                }
                
                Section {
                    Button(action: createNewNursingPrompt) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.pink)
                            Text("新しい救急看護師プロンプトを作成")
                                .foregroundColor(.pink)
                        }
                    }
                } header: {
                    Text("プロンプト管理")
                }
            }
            .navigationTitle("救急看護師プロンプト")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditPrompt) {
            if let prompt = editingPrompt {
                NursingPromptEditView(prompt: prompt) { name, content in
                    if prompt.name == "新しい救急看護師プロンプト" && prompt.content.isEmpty {
                        promptManager.addCustomPrompt(name: name, content: content)
                    } else {
                        promptManager.updateCustomPrompt(id: prompt.id, name: name, content: content)
                    }
                    showingEditPrompt = false
                    editingPrompt = nil
                }
            }
        }
    }
    
    private func createNewNursingPrompt() {
        let defaultNursingPrompt = """
あなたは、看護師がテンプレートを見ながら音声で話した内容をもとに、医療記録を正確かつ簡潔に構造化する役割を担っています。

以下の自然文は、複数回に分けて音声で入力された内容の蓄積です。  
この情報をもとに、テンプレートの各項目に該当する情報を記入してください。

---

【出力ルール】

1. 入力文に該当する情報があるテンプレート項目は、簡潔に記載してください。
2. 入力文に該当する記述がまったく見当たらない場合、その項目は「*記載なし*」と明記してください（アスタリスクで囲ってください）。
3. 意識レベル（GCS）、呼吸数、収縮期血圧の3つがそろっている場合は、qSOFAスコア（0〜3）を自動で算出し、テンプレートの所定位置に記入してください。
4. 自然文中に「時刻（例：朝7時、10時半など）」と「それに紐づく出来事（例：発症、搬送、飲食、来院など）」が含まれていれば、それらを抽出して時刻順に並べ、テンプレート末尾に「■時系列記録まとめ：」として出力してください。
5. 入力に含まれない内容を推測・補完しないでください。現場の安全性を重視してください。

---

【自然文（音声入力内容）】
{transcript}

---

【出力テンプレート構造】

◆ER経過観察記録◆  
- 搬送（救急車）：  
- 妊娠：  
- 付き添い：  
- 【持ち物】：  
- 確認者：  
- 受け取り者：  
- 【症候】：  
- 【経過】：  
- 【既往歴】：  
- 【アレルギー】：  

＜入退院支援チェックリスト＞  
- 【キーパーソン】：  
- 【同居人の有無】：あり／なし／*記載なし*  
- 【住宅】：自宅／施設（施設形態：）／*記載なし*  
- 【生活環境】：戸建て／集合住宅 段の利用：あり／なし／*記載なし*  
- [ADL]：  
- 【各種手帳】：あり（身体障害／精神障害）／なし／*記載なし*  
- 【介護認定】：あり／なし／申請中（事業所名／ケアマネジャー：）／*記載なし*  
- 【利用中のサービス】：あり（内容）／なし／*記載なし*  
- 【生活保護受給】：あり／なし／*記載なし*  
　- 担当区：  
　- 担当者：  
- 【職業】：  
- 【障害高齢者の日常生活自立度】：  
- 【認知症高齢者の日常生活自立度】：  
- 来院時間：  
- 【感染対策】：  
- 第一印象（ショック兆候）：あり／なし（蒼白、冷感、虚脱、脈拍触知不能、呼吸不全）

■一次評価  
- A（気道）：  
- B（呼吸）：呼吸数　回/分 SpO2= %  
　- 呼吸異常：あり／なし  
　- 補助筋使用：あり／なし  
　- 気管偏位：あり／なし  
　- 頸静脈怒張：あり／なし  
　- 呼吸音減弱：あり／なし  
　- 肺副雑音：あり／なし  
　- 皮下気腫：あり／なし  
- C（循環）：HR　回/分、BP　mmHg  
　- チアノーゼ：あり／なし  
　- CRT：〇秒  
　- 皮膚の湿潤：あり／なし  
　- 顔面蒼白：あり／なし  
- D（意識）：GCS E V M 合計 M  
- E（体温）：〇°C  
　- 四肢冷感：あり／なし  
　- 皮膚湿潤：あり／なし  
- QSOFA：スコア（0〜3）

【新型コロナウイルススクリーニング】  
- 過去1ヶ月以内の感染歴：あり／なし  
- 過去3日以内の陽性者との接触：あり／なし  

■初療  
- 移動方法：  
- 名前・生年月日確認：  
- 最終飲食：  
- 飲酒：  
- 喫煙：  
- 最終排泄：  

【入院・帰宅前チェックリスト】：  

---

■時系列記録まとめ：  
- HH:MM　出来事（できるだけ簡潔に）
"""
        
        let newPrompt = CustomPrompt(
            name: "救急看護師用記録テンプレート",
            content: defaultNursingPrompt
        )
        editingPrompt = newPrompt
        showingEditPrompt = true
    }
}

struct NursingPromptRow: View {
    let prompt: CustomPrompt
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "cross.case.fill")
                            .foregroundColor(.pink)
                            .font(.caption)
                        
                        Text(prompt.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    Text(String(prompt.content.prefix(80)) + (prompt.content.count > 80 ? "..." : ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Button(action: onTap) {
                    Image(systemName: "pencil")
                        .foregroundColor(.pink)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NursingPromptEditView: View {
    @State private var name: String
    @State private var content: String
    let onSave: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    init(prompt: CustomPrompt, onSave: @escaping (String, String) -> Void) {
        self._name = State(initialValue: prompt.name)
        self._content = State(initialValue: prompt.content)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("プロンプト名") {
                    TextField("プロンプト名を入力", text: $name)
                }
                
                Section("プロンプト内容") {
                    Text("{transcript} の部分に音声記録が挿入されます")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                }
            }
            .navigationTitle("救急看護師プロンプト編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmedName.isEmpty && !trimmedContent.isEmpty {
                            onSave(trimmedName, trimmedContent)
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.pink)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                             content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    NursingPromptManagerView()
        .environmentObject(PromptManager())
}