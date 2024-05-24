import CoreHaptics

class HapticManager {
    private var hapticEngine: CHHapticEngine?
    private var hapticPlayer: CHHapticPatternPlayer?
    
    init() {
        initializeHaptics()
    }
    
    private func initializeHaptics() {
        do {
            hapticEngine = try CHHapticEngine()
            hapticEngine?.stoppedHandler = { reason in
               
            }
            hapticEngine?.resetHandler = {
               
                do {
                    try self.hapticEngine?.start()
                } catch {
                   
                }
            }
            try hapticEngine?.start()
        } catch {
           
        }
    }
    
    func startHaptic() {
        guard let hapticEngine = hapticEngine, CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        let continuousHapticPattern = try? CHHapticPattern(events: [
            CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
            ], relativeTime: 0, duration: 1.0)
        ], parameters: [])
        
        do {
            hapticPlayer = try hapticEngine.makePlayer(with: continuousHapticPattern!)
            try hapticPlayer?.start(atTime: 0)
        } catch {
            
        }
    }
    
    func stopHaptic() {
        do {
            try hapticPlayer?.stop(atTime: 0)
        } catch {
            
        }
    }
}
