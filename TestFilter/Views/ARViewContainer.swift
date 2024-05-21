import SwiftUI
import RealityKit
import ARKit
import CoreImage.CIFilterBuiltins
import AVFoundation
import Speech

var isModelLoaded = false
var audioPlayer = AudioManager()
var isShrineFound = false
var hasSpawned = false

extension ARView: ARCoachingOverlayViewDelegate {
    func addCoaching() {
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.delegate = self
        coachingOverlay.session = self.session
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.goal = .horizontalPlane
        self.addSubview(coachingOverlay)
    }

    public func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        print("did deactivate")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            if !hasSpawned {
                audioPlayer.playNarration(fileName: "Spawn")
            }
            hasSpawned = true
        }
        
    }
}

struct ARViewContainer: UIViewRepresentable {
    
    @State private var totalDistanceTraveled: Float = 0.0
    @Binding var isGameOver: Bool
    @Binding var isWin: Bool
    @Binding var isOrigamiCollected: Bool
    @Binding var isBellCollected: Bool
    @Binding var isCoinCollected: Bool
    @Binding var isEverythingCollected: Bool
    
    var timer: Timer?
    var ghostModel: ModelEntity
    var shrineModel: ModelEntity
    var groundModel: ModelEntity
    var origamiModel: ModelEntity
    var bellModel: ModelEntity
    var coinModel: ModelEntity
    
    init(isGameOver: Binding<Bool>, isWin: Binding<Bool>, isOrigamiCollected: Binding<Bool>, isBellCollected: Binding<Bool>, isCoinCollected: Binding<Bool>, isEverythingCollected: Binding<Bool>) {
        ghostModel = try! ModelEntity.loadModel(named: "Mieruko-chan_shrine_Ghost.usdz")
        shrineModel = try! ModelEntity.loadModel(named: "Japanese_Shinto_Shrine.usdz")
        groundModel = try! ModelEntity.loadModel(named: "ground.usdz")
        origamiModel = try! ModelEntity.loadModel(named: "3D_Origami_crane.usdz")
        bellModel = try! ModelEntity.loadModel(named: "Cute_Bronze_Bell.usdz")
        coinModel = try! ModelEntity.loadModel(named: "Pile_of_coins.usdz")
        _isGameOver = isGameOver
        _isWin = isWin
        _isOrigamiCollected = isOrigamiCollected
        _isBellCollected = isBellCollected
        _isCoinCollected = isCoinCollected
        _isEverythingCollected = isEverythingCollected
    }
    
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero)
        let ciContext = CIContext()
        
        arView.addCoaching()
        isModelLoaded = true
        
        ghostModel.transform.scale = SIMD3<Float>(0.005, 0.005, 0.005)
        let ghostPosition = SIMD3<Float>(5,0,5)
        ghostModel.transform.translation = ghostPosition
        
        groundModel.transform.scale = SIMD3<Float>(0.001,0.001,0.001)
        groundModel.transform.translation = SIMD3<Float>(0,0,0)
        
        shrineModel.transform.scale = SIMD3<Float>(0.1, 0.1, 0.1)
        let shrinePosition = SIMD3<Float>(0,0,-4)
        shrineModel.transform.translation = shrinePosition
        
        origamiModel.transform.scale = SIMD3<Float>(0.0025,0.0025,0.0025)
        let origamiPosition = randomPosition(a: 4, b: 8)
        origamiModel.transform.translation = origamiPosition
        
        bellModel.transform.scale = SIMD3<Float>(0.0025,0.0025,0.0025)
        let bellPosition = randomPosition(a: -3, b: -1)
        bellModel.transform.translation = bellPosition
        
        coinModel.transform.scale = SIMD3<Float>(0.005,0.005,0.005)
        let coinPosition = randomPosition(a: -8, b: -5)
        coinModel.transform.translation = coinPosition
        
        
        //Add models to AR Camera
        
        let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)))
        anchor.children.append( ghostModel)
        anchor.children.append(shrineModel)
        anchor.children.append(groundModel)
        anchor.children.append( origamiModel)
        anchor.children.append(bellModel)
        anchor.children.append(coinModel)
        arView.scene.anchors.append(anchor)
        
        // Configure post-processing for filter (assuming you want the filter)
        arView.renderCallbacks.postProcess = { postProcessingContext in
            
            // A filter that applies a mono style to an image.
            let monoFilter = CIFilter.photoEffectNoir()
            
            // Make a CIImage from the rendered frame buffer.
            let source = CIImage(mtlTexture: postProcessingContext.sourceColorTexture)!
                .oriented(.downMirrored) // This orientation is essential to make sure that CoreImage interprets the texture contents correctly.
            
            // Set the source image as the input to the mono filter.
            monoFilter.inputImage = source
            
            // Request the filtered output image.
            let filteredSource = monoFilter.outputImage!
            
            // Render the filtered output image to the target color texture (this is the texture that ultimately gets displayed).
            do {
                let renderTask = try ciContext.startTask(toRender: filteredSource, to: .init(mtlTexture: postProcessingContext.targetColorTexture, commandBuffer: nil))
                
                // You must waitUntilCompleted here. RealityKit is expecting all post-processing work to be finished by the end of this closure.
                try renderTask.waitUntilCompleted()
            } catch {
                fatalError(error.localizedDescription)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // Adjust delay if needed
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                self.checkDistance(arView: arView)
                
                moveModelForward(ghostModel, arView: arView)
                
                if distanceFromCamera(arView: arView, model: shrineModel) <= 3  && isEverythingCollected{
                    shrineModel.generateCollisionShapes(recursive: true)
                }
                
                if distanceFromCamera(arView: arView, model: origamiModel) <= 3 {
                    origamiModel.generateCollisionShapes(recursive: true)
                }
                
                if distanceFromCamera(arView: arView, model: bellModel) <= 3 {
                    bellModel.generateCollisionShapes(recursive: true)
                }
                
                if distanceFromCamera(arView: arView, model: coinModel) <= 3 {
                    coinModel.generateCollisionShapes(recursive: true)
                }
                
            }
        }
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        

        
        return arView
    }
    
    
    func randomPosition(a: Float, b: Float) -> SIMD3<Float> {
        let randomX = Float.random(in: a...b)
        let randomZ = Float.random(in: a...b)
        return SIMD3<Float>(randomX, 0, randomZ)
    }
    
    func isWithinRadius(_ position1: SIMD3<Float>, _ position2: SIMD3<Float>, radius: Float) -> Bool {
        let distance = simd_distance(position1, position2)
        return distance < radius
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(shrineModel: shrineModel, origamiModel: origamiModel, bellModel: bellModel, 
                    coinModel: coinModel, isOrigamiCollected: $isOrigamiCollected, isBellCollected: $isBellCollected, isCoinCollected: $isCoinCollected, isEverythingCollected: $isEverythingCollected, isWin: $isWin)
    }
    
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
                    print("Tapped the model!")
                
                if entity == shrineModel {
                    print("LALALALALLALALALALALALALALALALALLAALLALAALLALALALALALALALALALAALLAALALALALA")
                    //speech recognition disini lalu kalau menang redirect ke winPage
                    
                    toggleListening()
                }
                
                if entity == origamiModel {
                    self.isOrigamiCollected = true
                    audioPlayer.playNarration(fileName: "CollectItem")
                    entity.removeFromParent()
                    
                    if (self.isBellCollected && self.isCoinCollected) {
                        self.isEverythingCollected = true
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            audioPlayer.playNarration(fileName: "CollectedAll")
                        }
                    }
                }
                
                if entity == bellModel {
                    self.isBellCollected = true
                    audioPlayer.playNarration(fileName: "CollectItem")
                    entity.removeFromParent()
                    
                    if (self.isOrigamiCollected && self.isCoinCollected) {
                        self.isEverythingCollected = true
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            audioPlayer.playNarration(fileName: "CollectedAll")
                        }
                    }
                }
                
                if entity == coinModel {
                    self.isCoinCollected = true
                    audioPlayer.playNarration(fileName: "CollectItem")
                    entity.removeFromParent()
                    
                    if (self.isBellCollected && self.isOrigamiCollected) {
                        self.isEverythingCollected = true
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            audioPlayer.playNarration(fileName: "CollectedAll")
                        }
                    }
                }
                
                
            } else {
                print("================================================= You tapped at nothing")
            }
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
            print("listening stopped")
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            isListening = false
        }
            
        func startListening() {
            print("start listening")
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
                        // Detected the secret word "swift"
                        print("Secret word spelled")
                        self.isWin = true
                    }
                }
            }
    
            audioEngine.prepare()
            do {
                try audioEngine.start()
            } catch {
                print("Error starting audio engine: \(error.localizedDescription)")
            }
    
            isListening = true
        }
            
    }
    
    
    
    func distanceFromCamera(arView: ARView, model: ModelEntity) -> Float {
        let modelPosition = model.transform.translation
        let cameraPosition = arView.cameraTransform.translation
        
        let distanceFromCamera = simd_distance(cameraPosition, modelPosition)
        
        return distanceFromCamera
    }
    
    
    func checkDistance(arView: ARView) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { // ini bikin jeda anggepannya invincible selama 15 detik, kalau ga pake ini, default printedDistancenya pas baru mulai itu 0 atau kadang dibawah threshold karena loading kamera.
            
            let cameraPosition = arView.cameraTransform.translation
            print("cameraPosition: \(cameraPosition)")
            
            let ghostModelPosition = ghostModel.transform.translation
            print("ghostPosition: \(ghostModelPosition)")
            
            let origamiModelPosition = origamiModel.transform.translation
            print("Origami Position: \(origamiModelPosition)")
            
            let BellModelPosition = bellModel.transform.translation
            print("Bell Position: \(BellModelPosition)")
            
            let CoinModelPosition = coinModel.transform.translation
            print("Coin Position: \(CoinModelPosition)")
            
            
            let printedDistance = simd_distance(cameraPosition, ghostModelPosition)
            
            print("Distance between ghost and camera: \(printedDistance)")
            
            let distanceFromShrine = simd_distance(cameraPosition, shrineModel.transform.translation)
            print("Distance from shrine: \(distanceFromShrine)")
            
            let distanceFromOrigami = simd_distance(cameraPosition, origamiModelPosition)
            print("Distance from Origami: \(distanceFromOrigami)")
            
            let distanceFromBell = simd_distance(cameraPosition, BellModelPosition)
            print("Distance from Bell: \(distanceFromBell)")
            
            let distanceFromCoin = simd_distance(cameraPosition, CoinModelPosition)
            print("Distance from Coin: \(distanceFromCoin)")
            
            if isModelLoaded {
                if printedDistance <= 1.0 { // If distance is less than or equal to 1
                    isGameOver = true // Set game over
                    //                    print("Udah game over")
                }
                
                if distanceFromShrine <= 3.5 {
                    if !isShrineFound {
                        audioPlayer.playNarration(fileName: "ShrineNear")
                    }
                    isShrineFound = true
                }
            }
            
        }
    }
    
    
    func moveModelForward(_ modelEntity: ModelEntity, arView: ARView) {
        // Define the distance you want the model to move in the Z-axis
        var distance: Float = 0.075
        
        if isEverythingCollected {
            distance = 0.1
        }
        
        let cameraPosition = arView.cameraTransform.translation
        
        // Get the current position of the model
        var currentPosition = modelEntity.transform.translation
        
        // Calculate the new position by adding the forward vector multiplied by the distance
        currentPosition.z +=  distance
        
        
        // Update the total distance traveled
        totalDistanceTraveled += distance
        
        // Check if the model has traveled more than 10 meter
        if totalDistanceTraveled >= 10.0 {
            
            // Respawn the ghost at position (0, 0) with random X and Z positions relative to camera
            
            let respawnRadius: Float = 5.0
            
            let randomXOffset = Float.random(in: -respawnRadius...respawnRadius)
            let randomZOffset = Float.random(in: -respawnRadius...respawnRadius)
            
            let randomX = cameraPosition.x + randomXOffset
            let randomZ = cameraPosition.z + randomZOffset

            currentPosition.x = randomX
            currentPosition.z = randomZ
            
            // Reset the total distance traveled
            totalDistanceTraveled = 0.0
            
            // Set the new position to the model's transform
            modelEntity.transform.translation = currentPosition
        }
        else {
            // Update the model's position if it hasn't respawned
            modelEntity.transform.translation = currentPosition
        }
    }
    
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Not required in this case, but can be used for updates
    }
    
}
