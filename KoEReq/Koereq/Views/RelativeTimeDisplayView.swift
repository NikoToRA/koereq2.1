import SwiftUI

// 型が見つからない場合のため、必要な型定義をインポート
// STTService.swiftで定義されている型を使用

struct RelativeTimeDisplayView: View {
    @StateObject private var sttService = STTService()
    @State private var deviceTimeInfo: DeviceTimeInfo?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // デバイス時刻情報セクション
                    DeviceTimeInfoSection(deviceTimeInfo: deviceTimeInfo)
                    
                    // 音声認識結果セクション
                    TranscriptionResultSection(sttService: sttService)
                    
                    // 検出された相対時間表現セクション
                    DetectedTimeExpressionsSection(
                        detectedDates: sttService.detectedRelativeTimeExpressions
                    )
                    
                    // テスト実行ボタン
                    TestButtonsSection(sttService: sttService)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("相対時間解析")
            .onAppear {
                loadDeviceTimeInfo()
            }
        }
    }
    
    private func loadDeviceTimeInfo() {
        deviceTimeInfo = sttService.getCurrentDeviceTime()
    }
}

// MARK: - デバイス時刻情報セクション

struct DeviceTimeInfoSection: View {
    let deviceTimeInfo: DeviceTimeInfo?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("📱 デバイス時刻情報")
                .font(.headline)
                .foregroundColor(.blue)
            
            if let timeInfo = deviceTimeInfo {
                VStack(alignment: .leading, spacing: 4) {
                    InfoRow(label: "現在時刻", value: timeInfo.formattedString)
                    InfoRow(label: "タイムゾーン", value: timeInfo.timeZoneIdentifier)
                    InfoRow(label: "オフセット", value: timeInfo.timeZoneOffset)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            } else {
                Text("時刻情報を読み込み中...")
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - 音声認識結果セクション

struct TranscriptionResultSection: View {
    @ObservedObject var sttService: STTService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🎤 音声認識結果")
                .font(.headline)
                .foregroundColor(.green)
            
            Group {
                if !sttService.transcriptionResult.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("元のテキスト:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(sttService.transcriptionResult)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        
                        if !sttService.processedTranscriptionResult.isEmpty &&
                           sttService.processedTranscriptionResult != sttService.transcriptionResult {
                            Text("日時を明確化したテキスト:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                            Text(sttService.processedTranscriptionResult)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                } else {
                    Text("音声認識を開始してください")
                        .foregroundColor(.gray)
                        .italic()
                }
            }
        }
    }
}

// MARK: - 検出された相対時間表現セクション

struct DetectedTimeExpressionsSection: View {
    let detectedDates: [DetectedDate]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("⏰ 検出された時間表現")
                .font(.headline)
                .foregroundColor(.purple)
            
            if !detectedDates.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(detectedDates.enumerated()), id: \.offset) { index, detectedDate in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(detectedDate.originalText)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.purple)
                                Text(formatDateByType(detectedDate.calculatedDate, isTimeUnit: detectedDate.isTimeUnit))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.right")
                                .foregroundColor(.purple)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            } else {
                Text("時間表現が検出されていません")
                    .foregroundColor(.gray)
                    .italic()
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDateByType(_ date: Date, isTimeUnit: Bool) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        
        if isTimeUnit {
            // 時間単位（分・時間）の場合：時刻のみ表示
            formatter.dateStyle = .none
            formatter.timeStyle = .short
        } else {
            // 日付単位（日・週・月・年）の場合：日付のみ表示
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
        }
        
        return formatter.string(from: date)
    }
}

// MARK: - テストボタンセクション

struct TestButtonsSection: View {
    @ObservedObject var sttService: STTService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🧪 テスト機能")
                .font(.headline)
                .foregroundColor(.red)
            
            VStack(spacing: 8) {
                Button(action: runBasicTest) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("基本的なテストを実行")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                Button(action: runMedicalTest) {
                    HStack {
                        Image(systemName: "cross.circle.fill")
                        Text("医療用語テストを実行")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                Button(action: runComplexTest) {
                    HStack {
                        Image(systemName: "gear.circle.fill")
                        Text("複合表現テストを実行")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private func runBasicTest() {
        let testText = "30分前に患者さんが来院され、2時間後に手術予定です"
        simulateTranscription(testText)
    }
    
    private func runMedicalTest() {
        let testText = "1週間前から症状が始まり、昨日悪化しました。明日再診予定です"
        simulateTranscription(testText)
    }
    
    private func runComplexTest() {
        let testText = "3日前に発症し、昨日救急外来を受診。今日入院し、明日手術、1週間後退院予定です"
        simulateTranscription(testText)
    }
    
    private func simulateTranscription(_ text: String) {
        // 音声認識結果をシミュレート
        let result = sttService.parseRelativeTimeFromText(text)
        sttService.transcriptionResult = text
        sttService.processedTranscriptionResult = result.processedText
        sttService.detectedRelativeTimeExpressions = result.detectedDates
    }
}

// MARK: - ヘルパービュー

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.regular)
            Spacer()
        }
    }
}

// MARK: - プレビュー

struct RelativeTimeDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        RelativeTimeDisplayView()
    }
} 