//
//  ViewController.swift
//  ShazamKitSample
//
//  Created by kazuya.tachibana on 2021/06/09.
//

import UIKit
import AVFAudio
import ShazamKit

struct MatchResult: Equatable {
    let mediaItem: SHMatchedMediaItem?
    let metaData: MetaData?
    
    static func == (lhs: MatchResult, rhs: MatchResult) -> Bool {
        return lhs.metaData == rhs.metaData
    }
}

struct ReferenceSignature: Hashable {
    let id: UUID
    let channelName: String
    let personalityName: String
    let storyName: String
    let chapterName: String
    let signature: SHSignature
}

extension ReferenceSignature {
    var mediaItem: SHMediaItem {
        SHMediaItem(properties: [
            .artist: personalityName,
            .title: storyName
        ])
    }
}

enum State {
    case idle
    case matching
    case matchFound(SHMatch)
    case failed
}

class ViewController: UIViewController {
    
    @IBOutlet private weak var recoginizedLabel: UILabel!
    
    /// マイクから音声を得るために使用します。
    private lazy var audioEngine = AVAudioEngine()
    /// オーディオ入力からオーディオシグネチャを生成するために使用します。
    private lazy var signatureGenerator = SHSignatureGenerator()
    private lazy var capturedSignatures = [ReferenceSignature]()
    private lazy var session = SHSession()
    private var url: URL?
    
    @Published var result = MatchResult(mediaItem: nil, metaData: nil)
    var isAnalysed = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction private func onTapRecoginizedButton(_ sender: Any) {
        let catalog = SHCustomCatalog()
        try? catalog.add(from: url!)
        
        // セッションは、何が再生されているかを認識するためのものです。
        session = SHSession(catalog: catalog)
        // このデリゲートは、メディアが認識されるとコールバックを受け取ります。
        session.delegate = self
        
        audioEngine = AVAudioEngine()
        
        // 入力のフォーマットに基づいて、バッファ用のオーディオフォーマットを作成し、シングルチャンネル（モノラル）にします。
        let audioFormat = AVAudioFormat(
            standardFormatWithSampleRate: audioEngine.inputNode.outputFormat(forBus: 0).sampleRate,
            channels: 1
        )
        
        // オーディオエンジンの入力に「タップ」を設置し、マイクからのバッファをセッションに送れるようにします。
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 2048, format: audioFormat) { [weak session] buffer, audioTime in
            // 新しいバッファが入ってくると、それをセッションに送って認識してもらいます。
            session?.matchStreamingBuffer(buffer, at: audioTime)
        }
        
        // これから録音を開始することをシステムに伝えます。
        try? AVAudioSession.sharedInstance().setCategory(.record)
        
        // 録音の許可が得られたことを確認して、オーディオエンジンを起動します。
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] success in
            guard success, let self = self else { return }
            
            try? self.audioEngine.start()
            self.recoginizedLabel.text = "認識中"
        }
    }
    
    @IBAction private func onTapAnalyseButton(_ sender: Any) {
        // 入力のフォーマットに基づいて，バッファ用のオーディオフォーマットを作成します（チャンネルは1つ（モノラル））．
        let audioFormat = AVAudioFormat(
            standardFormatWithSampleRate: audioEngine.inputNode.outputFormat(forBus: 0).sampleRate,
            channels: 1
        )
        
        // オーディオエンジンの入力に「タップ」を設置し、マイクからのバッファをシグネチャージェネレーターに送れるようにします。
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 2048, format: audioFormat) { [weak signatureGenerator] buffer, audioTime in
            // 新しいバッファが入ってくると、それをシグネチャジェネレータに送ります。
            try? signatureGenerator?.append(buffer, at: audioTime)
        }
        
        // これから録音を開始することをシステムに伝えます。
        try? AVAudioSession.sharedInstance().setCategory(.record)
        
        // 録音の許可が得られたことを確認して、オーディオエンジンを起動します。
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] success in
            guard success, let self = self else { return }
            
            try? self.audioEngine.start()
            self.recoginizedLabel.text = "分析中！！"
        }
    }
    
    @IBAction private func finishRecording(_ sender: Any) {
        audioEngine.stop()
        capturedSignatures.append(ReferenceSignature(id: UUID.init(),
                                                     channelName: "K.T",
                                                     personalityName: "Kazuya Tachibana",
                                                     storyName: "Voicy",
                                                     chapterName: "No.1",
                                                     signature: signatureGenerator.signature()))
        recoginizedLabel.text = export(createCatalog()!)?.absoluteString
    }
    
    private func createCatalog() -> SHCustomCatalog? {
        let catalog = SHCustomCatalog()
        
        do {
            // capturedSignaturesは、カスタムモデルタイプである[ReferenceSignature]の配列です。
            try capturedSignatures.forEach { reference in
                try catalog.addReferenceSignature(reference.signature, representing: [reference.mediaItem])
            }
        } catch {
            print("Something went wrong: \(error)")
        }
        
        return catalog
    }
    
    private func export(_ catalog: SHCustomCatalog) -> URL? {
        url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("shazamcatalog")
        
        do {
            try catalog.write(to: url!)
            
            return url
        } catch {
            print("Export error: \(error)")
            return nil
        }
    }
}

extension ViewController: SHSessionDelegate {
    
    func session(_ session: SHSession, didFind match: SHMatch) {
        DispatchQueue.main.async {
            print("###\(match.mediaItems.first?.title ?? "")")
        }
    }
    
    func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature, error: Error?) {
        print("###error:\(error?.localizedDescription ?? "")")
    }
}
