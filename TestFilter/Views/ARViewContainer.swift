import SwiftUI
import RealityKit
import ARKit
import CoreImage.CIFilterBuiltins
import AVFoundation
import Speech
import CoreHaptics

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
        
    }
}

struct ARViewContainer: UIViewRepresentable {
    
    @State private var totalDistanceTraveled: Float = 0.0
    @State private var hasSpawned = false
    @State private var hapticEngine: CHHapticEngine?
    @State private var hapticPlayer: CHHapticPatternPlayer?
    
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
    var hapticManager: HapticManager
    var audioPlayer = AudioManager()
    var gameStatus = GameStatus()
    
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
        hapticManager = HapticManager()
    }
    
    func manageModels() {
        ghostModel.transform.scale = SIMD3<Float>(0.005, 0.005, 0.005)
        let ghostPosition = SIMD3<Float>(5,0,5)
        ghostModel.transform.translation = ghostPosition
        
        groundModel.transform.scale = SIMD3<Float>(0.001,0.001,0.001)
        groundModel.transform.translation = SIMD3<Float>(0,0,0)
        
        shrineModel.transform.scale = SIMD3<Float>(0.1, 0.1, 0.1)
        let shrinePosition = SIMD3<Float>(0,0,-4)
        shrineModel.transform.translation = shrinePosition
        
        origamiModel.transform.scale = SIMD3<Float>(0.0025,0.0025,0.0025)
        let origamiPosition = randomPosition(a: 4, b: 7)
        origamiModel.transform.translation = origamiPosition
        
        bellModel.transform.scale = SIMD3<Float>(0.0025,0.0025,0.0025)
        let bellPosition = randomPosition(a: -7, b: -4)
        bellModel.transform.translation = bellPosition
        
        coinModel.transform.scale = SIMD3<Float>(0.005,0.005,0.005)
        let coinPosition = randomPosition(a: -10, b: 10)
        coinModel.transform.translation = coinPosition
    }
    
    func addModelsToScene(arView: ARView) {
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        config.planeDetection = [.horizontal]
        arView.session.run(config)
        
        let anchor = AnchorEntity(.plane(.horizontal, classification: .floor, minimumBounds: SIMD2<Float>(0.2, 0.2)))
        anchor.children.append( ghostModel)
        anchor.children.append(shrineModel)
        anchor.children.append(groundModel)
        anchor.children.append( origamiModel)
        anchor.children.append(bellModel)
        anchor.children.append(coinModel)
        arView.scene.anchors.append(anchor)
    }
    
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero)
        let ciContext = CIContext()
        
        arView.addCoaching()
        gameStatus.isModelLoaded = true
        
        manageModels()
        addModelsToScene(arView: arView)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            if !hasSpawned {
                audioPlayer.playNarration(fileName: "Spawn")
            }
            self.hasSpawned = true
        }
       
        arView.renderCallbacks.postProcess = { postProcessingContext in
            
            let monoFilter = CIFilter.photoEffectNoir()
            
            let source = CIImage(mtlTexture: postProcessingContext.sourceColorTexture)!
                .oriented(.downMirrored)
            
            monoFilter.inputImage = source
            
            let filteredSource = monoFilter.outputImage!
            
            do {
                let renderTask = try ciContext.startTask(toRender: filteredSource, to: .init(mtlTexture: postProcessingContext.targetColorTexture, commandBuffer: nil))
                try renderTask.waitUntilCompleted()
            } catch {
                fatalError(error.localizedDescription)
            }
        }
        
        updateGameState(arView: arView)
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        return arView
    }
    
    func stopARSession(arView: ARView) {
       let configuration = ARWorldTrackingConfiguration()
       arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
       arView.session.pause()
    }
    
    func updateGameState(arView: ARView) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                self.checkDistance(arView: arView)
                
                if !isEverythingCollected {
                    moveModelForward(ghostModel, arView: arView, distance: 0.075)
                } else {
                    moveModelForward(ghostModel, arView: arView, distance: 0.15)
                }
                
                if distanceFromCamera(arView: arView, model: shrineModel) <= 3  && isEverythingCollected {
                    shrineModel.generateCollisionShapes(recursive: true)
                }
                
                enableTouch(arView: arView, model: origamiModel)
                enableTouch(arView: arView, model: bellModel)
                enableTouch(arView: arView, model: coinModel)
                
                if isEverythingCollected {
                    hapticManager.startHaptic()
                    
                    if isWin || isGameOver {
                        hapticManager.stopHaptic()
                        stopARSession(arView: arView)
                    }
                }
            }
        }
    }
    
    func enableTouch(arView: ARView, model: ModelEntity) {
        if distanceFromCamera(arView: arView, model: model) <= 3 {
            model.generateCollisionShapes(recursive: true)
        }
    }
    
    func randomPosition(a: Float, b: Float) -> SIMD3<Float> {
        let randomX = Float.random(in: a...b)
        let randomZ = Float.random(in: a...b)
        return SIMD3<Float>(randomX, 0, randomZ)
    }
    
    func distanceFromCamera(arView: ARView, model: ModelEntity) -> Float {
        let modelPosition = model.transform.translation
        let cameraPosition = arView.cameraTransform.translation
        
        let distanceFromCamera = simd_distance(cameraPosition, modelPosition)
        
        return distanceFromCamera
    }
    
    func checkDistance(arView: ARView) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            
            let cameraPosition = arView.cameraTransform.translation
            let ghostModelPosition = ghostModel.transform.translation
            let shrineModelPosition = shrineModel.transform.translation
            
            let ghostDistance = simd_distance(cameraPosition, ghostModelPosition)
            let distanceFromShrine = simd_distance(cameraPosition, shrineModelPosition)
            
            if gameStatus.isModelLoaded {
                if ghostDistance <= 1.0 {
                    isGameOver = true
                }
                
                if distanceFromShrine <= 3.5 {
                    if !gameStatus.isShrineFound {
                        audioPlayer.playNarration(fileName: "ShrineNear")
                    }
                    gameStatus.isShrineFound = true
                }
            }
            
        }
    }
    
    func moveModelForward(_ modelEntity: ModelEntity, arView: ARView, distance: Float) {
        let cameraPosition = arView.cameraTransform.translation
        
        var currentPosition = modelEntity.transform.translation
        
        currentPosition.z +=  distance
        
        totalDistanceTraveled += distance
        
        if totalDistanceTraveled >= 7.5 {
                        
            let respawnRadius: Float = 5.0
            
            let randomXOffset = Float.random(in: -respawnRadius...respawnRadius)
            let randomZOffset = Float.random(in: -respawnRadius...respawnRadius)
            
            let randomX = cameraPosition.x + randomXOffset
            let randomZ = cameraPosition.z + randomZOffset

            currentPosition.x = randomX
            currentPosition.z = randomZ
            
            totalDistanceTraveled = 0.0
            
            modelEntity.transform.translation = currentPosition
        }
        else {
            modelEntity.transform.translation = currentPosition
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(shrineModel: shrineModel, origamiModel: origamiModel, bellModel: bellModel,
                    coinModel: coinModel, isOrigamiCollected: $isOrigamiCollected, isBellCollected: $isBellCollected,
                    isCoinCollected: $isCoinCollected, isEverythingCollected: $isEverythingCollected, isWin: $isWin)
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        
    }
    
}
