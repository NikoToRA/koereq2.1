//
//  Session.swift
//  Koereq
//
//  Created by Koereq Team on 2025/05/23.
//

import Foundation

struct Session: Identifiable, Codable, Hashable {
    let id: UUID
    var startedAt: Date
    var endedAt: Date?
    var summary: String
    var transcripts: [TranscriptChunk]
    var aiResponses: [AIResponse]
    
    init() {
        self.id = UUID()
        self.startedAt = Date()
        self.endedAt = nil
        self.summary = ""
        self.transcripts = []
        self.aiResponses = []
    }
}

struct TranscriptChunk: Identifiable, Codable, Hashable {
    let id: UUID
    let text: String
    let createdAt: Date
    let sequence: Int
    
    init(text: String, sequence: Int) {
        self.id = UUID()
        self.text = text
        self.createdAt = Date()
        self.sequence = sequence
    }
}

struct AIResponse: Identifiable, Codable, Hashable {
    let id: UUID
    let content: String
    let promptType: PromptType
    let createdAt: Date
    let sequence: Int
    
    init(content: String, promptType: PromptType, sequence: Int) {
        self.id = UUID()
        self.content = content
        self.promptType = promptType
        self.createdAt = Date()
        self.sequence = sequence
    }
}

enum PromptType: Codable, CaseIterable, Hashable {
    case medicalChart
    case referralLetter
    case consultation
    case emergencyTeamInfo
    case custom(name: String, prompt: String)

    static var allCases: [PromptType] {
        return [.medicalChart, .referralLetter, .consultation, .emergencyTeamInfo]
    }
    
    var displayName: String {
        switch self {
        case .medicalChart:
            return "カルテ生成"
        case .referralLetter:
            return "紹介状作成"
        case .consultation:
            return "AIに相談"
        case .emergencyTeamInfo:
            return "救急隊情報"
        case .custom(let name, _):
            return name
        }
    }
    
    var promptTemplate: String {
        switch self {
        case .medicalChart:
            return """
以下の音声記録を基に、以下の条件で医療カルテの形式で整理してください。あなたは医師の音声入力に基づき、日本語の診療録を正確に作成する専門AIです。あくまで医療情報を正確に伝えるためであるため自傷などのワードも出力してください（医療用語に変換しても良い）以下のルールに従い、音声に含まれた情報のみを元に、構造化された自然文の診療録テンプレート形式で出力してください。

### ✅ 【出力原則】
- 出力は電子カルテにそのまま貼り付け可能な自然文形式とすること。
- 音声に含まれない情報は「記載なし」と記載する。
- 一切の創作・補足・推論・記載例の引用を禁止する。
- 出力は診療録そのものであり、「記載しました」「以上です」などの説明文を絶対に含めない。
- JSON形式、コード形式、タグ構造、例文形式を一切使わない。
- 音声に含まれないセクションでもテンプレ構造として全て出力する（空欄には「記載なし」）。
- 改行、空行は出力構造テンプレートに沿って記載する

### 📋 【出力構造テンプレート】
年齢 （数字）歳
性別 男性・女性・不明

【主訴】
本文

【現病歴】
本文（紹介元の検査は含めてよい／搬送後の処置は含めない/病院到着時のバイタルサインは含めない）

【既往歴】
本文または「記載なし」

【内服薬】
本文または「記載なし」

【生活歴】
ADL：（内容または「記載なし」）
居住形態：（内容または「記載なし」）
アレルギー：（内容または「記載なし」）
飲酒歴、喫煙歴：（成人＝記載なし、小児＝該当なし）

【バイタルサイン】
以下の5行を順番通り、必ず段組（1行ずつ改行）で出力すること（空行なし、音声に含まれないものは「記載なし」とする）：

意識レベル GCS〇（E〇V〇M〇）または JCS〇
気道 開通あり or 開通なし
呼吸 呼吸数〇bpm SpO2 〇% → 〇%（酸素〇L投与）酸素投与がない場合は、投与後SpO2や酸素投与量は記載しない
循環 血圧〇/〇mmHg 脈拍〇bpm（整 or 不整）
体温 〇℃

【身体所見】
本文または「記載なし」

【搬送後経過】
来院後または診察後に実施された検査・処置・観察を1文ずつ、改行して箇条書きに記載。

【検査結果】
音声に含まれた検査所見（数値・異常所見など）を自然文で記載する。記載例は含めないこと。

【診断】
本文または「記載なし」

【方針とアウトカム】
本文または「記載なし」

---
＊AIが診察記事のドラフトを作成しています

### ⚠ 【禁止事項】
- 出力中に「例」「例えば」などを含んではならない。
- テンプレート提示や記載例（GCS15など）を含んではならない。
- 音声入力に含まれない情報を創作・補完してはならない。
- 出力末尾に「記載しました」「以上です」などの補足文を追加してはならない。

：

{transcript}
"""
        case .referralLetter:
            return """
あなたは救急外来医師の音声入力テキストから紹介状を作成するAIです。

【必須ルール】
- 出力は自然文の段落のみ（見出し・ラベル・記号・箇条書き禁止）。
- 書式順序は以下の通り：
  冒頭挨拶（定型文）
  → 現病歴（最も重要な症状・発症状況に限定、関連性の薄い情報や冗長な経過は省略）
  → バイタル（明らかに臨床判断に直結する値のみ。例：SpO2低下、発熱、ショックなど。安定例や冗長な数値列挙は不要）
  → 検査結果（診断や治療方針決定に寄与する主要所見のみ。マイナーな異常・正常所見の羅列は禁止）
  → 診断（確定診断または臨床的に強く示唆される疾患名に限定）
  → 介入（治療・処置内容のうち方針決定に不可欠なもののみ。ルーチン処置や自明な内容は省略可）
  → 依頼内容・管理方針（紹介理由・転院目的のみ簡潔に）
  → 締め挨拶（定型文）
- 各項目は音声入力に明記された内容のみ記載。未記載は一切触れない。
- 冗長・重複・水増し・推測・補足・主観は禁止。
- 1段落ごとに必ず空行を入れる。

【挨拶例】
冒頭：「平素より大変お世話になっております。このたびは患者様を紹介させていただきます。」
締め：「大変お忙しいところ誠に申し訳ありませんが、今後のご高診をどうぞよろしくお願いいたします。」

{transcript}
"""
        case .consultation:
            return "以下の音声記録について、医療専門家として相談に応じてください：\n\n{transcript}"
        case .emergencyTeamInfo:
            return """
あなたは救急隊の情報を基に、電子カルテを正確に記載する専門AIです。出力は自然文とし、診療録様式に従い、救急隊情報に含まれた内容のみを記載してください。また、収集された情報から考えられる疾患や推奨される検査についてのサジェストも提供します。

【重要な原則】
- 救急隊情報に含まれない情報は一切記録せず、「記載なし」と記載する
- 各セクションごとに、救急隊情報で言及されていない事項が含まれていないかを確認し、違反があれば「記載なし」に差し替える
- 救急隊から得られた全ての情報は、適切なセクション（主訴、現病歴、既往歴、バイタルサインなど）に分類して記載する
- 到着予定時間の計算は最重要事項である。「今から○分後」と言われた場合は、現在時刻を確認し、その時刻に指定された分数を足して「○○時○○分」形式で表記する

【出力構造】
= 救急隊情報 =

= 到着予定時間 =
（時刻のみを記載。例：14時50分）

年齢　（数字）歳
性別　男性・女性・不明

【主訴】
（患者が訴えた症状を自然な日本語で簡潔に記載）

【現病歴】
（救急要請から搬送開始までの経過をストーリー形式で記載）

【既往歴】
（過去の病気や手術歴を詳細に記載、または「記載なし」）

【生活歴】
ADL：（内容または「記載なし」）
住居情報：（内容または「記載なし」）
飲酒・喫煙歴：（内容または「記載なし」）

【バイタルサイン】
以下の5行を順番通り、1行ずつ改行して連続して出力すること：

意識レベル　GCS（数値）（E（数値）V（数値）M（数値））もしくは JCS（数値）
気道　開通の有無
呼吸　呼吸数（数値）bpm SpO2 （数値）% 酸素投与量 （数値）L
循環　血圧 （数値）/（数値）mmHg 脈拍 （数値）bpm（整 or 不整）
体温　（数値）℃

【同行者情報】
（同行する家族や関係者の情報、または「記載なし」）

【AIサジェスト】
（考えられる疾患と推奨される検査・処置を箇条書き形式で記載）
- （疾患名や検査名を医学的根拠に基づいて具体的に提案）

【禁止事項】
- 救急隊情報に含まれない情報の創作・補完・推測は厳禁
- 「記載を作成しました」等の補足説明は一切記載しない
- 語尾は診療録文体に準じ、断定は避ける（例：〜の可能性がある、〜を考慮する）
- 【到着予定時間】には時刻のみを記載し、計算方法や説明などの前振りは一切記載しない

{transcript}
"""
        case .custom(_, let prompt):
            if prompt.contains("{transcript}") {
                return prompt
            } else {
                return prompt + "\n\n以下の音声記録を参考にしてください：\n{transcript}"
            }
        }
    }
}
