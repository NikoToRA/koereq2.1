# STT処理の構成まとめ (KoEReqプロジェクト)

1.  **目的**:
    *   録音された音声ファイル全体を、途中の無音区間で途切れることなく、確実に文字起こし（STT）する。
    *   音声データは別途ファイルとして保存されている前提。

2.  **主要コンポーネントと役割**:

    *   **`RecordingService.swift`**:
        *   役割: マイクからの音声入力の録音とファイルへの保存。音声レベルのモニタリング。
        *   主なメソッド:
            *   `startRecording() -> URL?`: 録音を開始し、保存先ファイルのURLを返す。
            *   `stopRecording() -> URL?`: 録音を停止し、保存されたファイルのURLを返す。
        *   使用技術: `AVAudioRecorder` (ファイルへの直接録音)。

    *   **`STTService.swift`**:
        *   役割: 指定された音声ファイルURLから音声データを読み込み、文字起こし処理を実行する。
        *   主なメソッド:
            *   `transcribe(audioURL: URL) async throws -> String`: 音声ファイルを文字起こしし、結果のテキストを返す。
                *   **無音対策**: `SFSpeechAudioBufferRecognitionRequest` を使用。`AVAudioFile` を使って音声ファイルをチャンク（`AVAudioPCMBuffer`）に分割して読み込み、順次STTエンジンに供給する。これにより、ファイル全体の処理と、無音区間による処理中断の防止を目指す。
        *   使用技術: `Speech.framework` (`SFSpeechRecognizer`, `SFSpeechAudioBufferRecognitionRequest`), `AVFoundation` (`AVAudioFile`, `AVAudioPCMBuffer`)。

    *   **`SessionView.swift` (呼び出し元の例)**:
        *   役割: UI操作（録音開始・停止ボタン）をトリガーとし、`RecordingService` と `STTService` の各メソッドを適切な順序で呼び出す。
        *   処理フロー（STT関連部分）:
            1.  録音開始ボタンタップ: `RecordingService.startRecording()` を呼び出す。
            2.  録音停止ボタンタップ: `RecordingService.stopRecording()` を呼び出し、保存された音声ファイルのURLを取得。
            3.  取得した音声ファイルURLを `STTService.transcribe(audioURL:)` に渡し、STT処理を実行。
            4.  STT結果をUIに表示し、セッションデータとして保存。

3.  **無音対策のキーポイント (`STTService.transcribe`内)**:
    *   `SFSpeechURLRecognitionRequest` (ファイルURLを直接渡す) ではなく、`SFSpeechAudioBufferRecognitionRequest` (オーディオバッファを逐次供給) を使用。
    *   `AVAudioFile` で音声ファイルを開く。
    *   ループ処理で、音声ファイルから小さなチャンク (`AVAudioPCMBuffer`) を読み出す。
        *   `audioFile.read(into:frameCapacity:)`
    *   読み出した各バッファを `recognitionRequest.append(_:)` でSTTエンジンに供給。
    *   ファイルの最後までバッファを供給し終えたら、`recognitionRequest.endAudio()` を呼び出して音声入力の完了を明示的に通知。
    *   認識タスクのコールバックで、最終的な認識結果 (`result.isFinal`) を取得する。

4.  **ファイル構成 (関連ファイル)**:
    *   `KoEReq/Koereq/Services/RecordingService.swift`
    *   `KoEReq/Koereq/Services/STTService.swift`
    *   `KoEReq/Koereq/Views/SessionView.swift` (呼び出し側の一例として)

5.  **前提となる権限設定 (`Info.plist`)**:
    *   `NSMicrophoneUsageDescription` (マイク利用許可)
    *   `NSSpeechRecognitionUsageDescription` (音声認識利用許可)

**次のスレッドで検討・確認すると良い可能性のある点**:

*   `STTService.transcribe` メソッド内のバッファサイズ (`AVAudioFrameCount(4096)`) の妥当性。
*   エラーハンドリングの詳細（特定のSTTエラーコードに対する個別対応の要否など）。
*   長時間録音（例: 数十分以上）の場合の安定性とパフォーマンス。
*   リアルタイム文字起こしの要件が再度浮上した場合の対応（現在の `STTService.transcribeRealTime` の活用や拡張）。 