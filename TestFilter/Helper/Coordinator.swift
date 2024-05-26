import Foundation
import RealityKit
import ARKit
import SwiftUI
import Speech
import AVFoundation

class Coordinator: NSObject {

    var shrineModel: ModelEntity
    var origamiModel: ModelEntity
    var bellModel: ModelEntity
    var coinModel: ModelEntity
    @Binding var isOrigamiCollected: Bool
    @Binding var isBellCollected: Bool
    @Binding var isCoinCollected: Bool
    @Binding var isEverythingCollected: Bool
    @Binding var isWin: Bool
            
    
    @Published var isListening: Bool = false
    @State private var recognizedText = ""
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var audioEngine = AVAudioEngine()
    var audioPlayer = AudioManager()
    
    init(shrineModel: ModelEntity, origamiModel: ModelEntity, bellModel: ModelEntity, coinModel: ModelEntity, isOrigamiCollected: Binding<Bool>, isBellCollected: Binding<Bool>, isCoinCollected: Binding<Bool>, isEverythingCollected: Binding<Bool>, isWin: Binding<Bool>) {
                self.shrineModel = shrineModel
                self.origamiModel = origamiModel
                self.bellModel = bellModel
                self.coinModel = coinModel
                _isOrigamiCollected = isOrigamiCollected
                _isBellCollected = isBellCollected
                _isCoinCollected = isCoinCollected
                _isEverythingCollected = isEverythingCollected
                _isWin = isWin
                super.init()
            }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        guard let arView = sender.view as? ARView else {return}
        let tapLocation = sender.location(in: arView)
        
        if let entity = arView.entity(at: tapLocation) {
            
            if entity == shrineModel {
                toggleListening()
            }
            
            tapModel(model: entity)
            
        } else {
            
        }
    }
    
    func tapModel(model: Entity) {
        if (model == origamiModel) {
            self.isOrigamiCollected = true
            
            if (self.isBellCollected && self.isCoinCollected) {
                self.isEverythingCollected = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.audioPlayer.playNarration(fileName: "CollectedAll")
                }
            }
            
        }
        
        else if (model == bellModel) {
            self.isBellCollected = true
            
            if (self.isOrigamiCollected && self.isCoinCollected) {
                self.isEverythingCollected = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.audioPlayer.playNarration(fileName: "CollectedAll")
                }
            }
        }
        
        else if (model == coinModel) {
            self.isCoinCollected = true
            
            if (self.isBellCollected && self.isOrigamiCollected) {
                self.isEverythingCollected = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.audioPlayer.playNarration(fileName: "CollectedAll")
                }
            }
        }
        
        audioPlayer.playNarration(fileName: "CollectItem")
        model.removeFromParent()
    }
    
    func toggleListening() {
        print(isListening)
        if isListening {
            stopListening()
        } else {
      
            startListening()
        }
    }
    
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        isListening = false
    }
        
    func startListening() {
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            SFSpeechRecognizer.requestAuthorization { status in
                if status == .authorized {
                    self.startListening()
                }
            }
            return
        }

        try? AVAudioSession.sharedInstance().setCategory(.record)
        try? AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)

        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
            recognitionRequest.append(buffer)
        }

        speechRecognizer.recognitionTask(with: recognitionRequest) { (result, _) in
            if let result = result {
                let bestString = result.bestTranscription.formattedString
                self.recognizedText = bestString
                if bestString.lowercased().contains("sorry") {
                    self.isWin = true
                }
            }
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
           
        }

        isListening = true
    }
        
}
