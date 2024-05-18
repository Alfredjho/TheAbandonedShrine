import SwiftUI
import RealityKit
import ARKit
import CoreImage.CIFilterBuiltins

var isModelLoaded = false
var audioPlayer = AudioManager()
var isShrineFound = false

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
        isModelLoaded = true
        print("did deactivate")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            audioPlayer.playNarration(fileName: "Spawn")
        }
        
    }
}

// ini baru berhasil detect bahwa ada long press di cameraAR, belom bisa detek modelEntity nya

extension ARView {
    @objc func handleLongPress(_ recognizer: UITapGestureRecognizer? = nil) {

           let touchInView = recognizer?.location(in: self)
        
           guard let touchInView = recognizer?.location(in: self) else {
               return
           }

           guard let modelEntity = self.entity(at: touchInView) as? ModelEntity else {
               print("===========================================modelEntity not found at \(touchInView)")
               return
           }
           
           print("===============================================Long press detected on - \(modelEntity.name)")
           
       }
}

struct ARViewContainer: UIViewRepresentable {
    
    @State private var totalDistanceTraveled: Float = 0.0
    @Binding var isGameOver: Bool
    
    var timer: Timer?
    var ghostModel: ModelEntity
    var shrineModel: ModelEntity
    var groundModel: ModelEntity
    var origamiModel: ModelEntity
    var bellModel: ModelEntity
    var coinModel: ModelEntity
    
    init(isGameOver: Binding<Bool>) {
        ghostModel = try! ModelEntity.loadModel(named: "Mieruko-chan_shrine_Ghost.usdz")
        shrineModel = try! ModelEntity.loadModel(named: "Japanese_Shinto_Shrine.usdz")
        groundModel = try! ModelEntity.loadModel(named: "ground.usdz")
        origamiModel = try! ModelEntity.loadModel(named: "3D_Origami_crane.usdz")
        bellModel = try! ModelEntity.loadModel(named: "Cute_Bronze_Bell.usdz")
        coinModel = try! ModelEntity.loadModel(named: "Pile_of_coins.usdz")
        _isGameOver = isGameOver
    }
    
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero)
        let ciContext = CIContext()
        
        arView.addCoaching()
        
        ghostModel.transform.scale = SIMD3<Float>(0.005, 0.005, 0.005)
        let ghostPosition = SIMD3<Float>(10, 0, 10)
        ghostModel.transform.translation = ghostPosition
        
        groundModel.transform.scale = SIMD3<Float>(0.001,0.001,0.001)
        groundModel.transform.translation = SIMD3<Float>(0,0,0)
        
        shrineModel.transform.scale = SIMD3<Float>(0.1, 0.1, 0.1)
        var shrinePosition = randomPosition(a: 3, b: 5)
        shrineModel.transform.translation = shrinePosition
        
        origamiModel.transform.scale = SIMD3<Float>(0.0025,0.0025,0.0025)
        var origamiPosition: SIMD3<Float>
        
        bellModel.transform.scale = SIMD3<Float>(0.0025,0.0025,0.0025)
        var bellPosition: SIMD3<Float>
        
        coinModel.transform.scale = SIMD3<Float>(0.005,0.005,0.005)
        var coinPosition: SIMD3<Float>
        
        repeat {
            shrinePosition = randomPosition(a: -5, b: -2)
        } while isWithinRadius(ghostPosition, shrinePosition, radius: 5) || isWithinRadius(groundModel.transform.translation, shrinePosition, radius: 0.1)
        
        shrineModel.transform.translation = shrinePosition
        
        // Tentukan posisi Origami
        repeat {
            origamiPosition = randomPosition(a: -10, b: -2)
        } while isWithinRadius(ghostPosition, origamiPosition, radius: 5) || isWithinRadius(shrinePosition, origamiPosition, radius: 5) || isWithinRadius(groundModel.transform.translation, origamiPosition, radius: 0.1)
        
        origamiModel.transform.translation = origamiPosition
        
        // Tentukan posisi Bell
        repeat {
            bellPosition = randomPosition(a: -10, b: -2)
        } while isWithinRadius(ghostPosition, bellPosition, radius: 5) || isWithinRadius(shrinePosition, bellPosition, radius: 5) || isWithinRadius(origamiPosition, bellPosition, radius: 5) || isWithinRadius(groundModel.transform.translation, bellPosition, radius: 0.1)
        
        bellModel.transform.translation = bellPosition
        
        // Tentukan posisi Coin
        repeat {
            coinPosition = randomPosition(a: -10, b: -2)
        } while isWithinRadius(ghostPosition, coinPosition, radius: 5) || isWithinRadius(shrinePosition, coinPosition, radius: 5) || isWithinRadius(origamiPosition, coinPosition, radius: 5) || isWithinRadius(bellPosition, coinPosition, radius: 5) || isWithinRadius(groundModel.transform.translation, coinPosition, radius: 0.1)
        
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
            self.checkDistance(arView: arView)
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                self.checkDistance(arView: arView)
//                moveModelForward(ghostModel, arView: arView)
            }
        }
        
        // detect ada longpress
        
        let longpress = UILongPressGestureRecognizer(target: arView, action: #selector(arView.handleLongPress(_:)))
        arView.addGestureRecognizer(longpress)
        
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
    
    
    func checkDistance(arView: ARView) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { // ini bikin jeda anggepannya invincible selama 30 detik, kalau ga pake ini, default printedDistancenya pas baru mulai itu 0 atau kadang dibawah threshold karena loading kamera.
            
            let cameraPosition = arView.cameraTransform.translation
            print("cameraPosition: \(cameraPosition)")
            let ghostModelPosition = ghostModel.transform.translation
            print("ghostPosition: \(ghostModelPosition)")
            
            let groundPosition = groundModel.transform.translation
            print("groundPosition: \(groundPosition)")
            
            let printedDistance = simd_distance(cameraPosition, ghostModelPosition)
            
            print("Distance between ghost and camera: \(printedDistance)")
            
            let distanceFromShrine = simd_distance(cameraPosition, shrineModel.transform.translation)
            print("Distance from shrine: \(distanceFromShrine)")
            
            if isModelLoaded {
                if printedDistance <= 0.7 { // If distance is less than or equal to 0.7
                    isGameOver = true // Set game over
                    //                    print("Udah game over")
                }
                
                if distanceFromShrine <= 3 {
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
        let distance: Float = 0.05
        
        let cameraPosition = arView.cameraTransform.translation
        
        // Get the current position of the model
        var currentPosition = modelEntity.transform.translation
        
        // Calculate the new position by adding the forward vector multiplied by the distance
        currentPosition.z +=  distance
        
        
        // Update the total distance traveled
        totalDistanceTraveled += distance
        
        // Check if the model has traveled more than 10 meter
        if totalDistanceTraveled >= 5.0 {
            
            // Respawn the ghost at position (0, 0) with random X and Z positions relative to camera
            
            let respawnRadius: Float = 3.0
            
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
