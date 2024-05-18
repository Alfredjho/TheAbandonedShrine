import Foundation
import AVFoundation


class AudioManager: ObservableObject {
    var audioPlayer: AVAudioPlayer!
    
    func playBgMusic() {
        let url = Bundle.main.url(forResource: "HorrorBGM", withExtension: "mp4")
        audioPlayer = try! AVAudioPlayer(contentsOf: url!)
        audioPlayer.numberOfLoops = -1
        audioPlayer.play()
    }
    
    func playRandomBGM() {
        
        let bgm = ["HorrorLaugh", "HorrorSing", "HorrorWhisper"]
        
        let url = Bundle.main.url(forResource: bgm.randomElement(), withExtension: "mp4")
        
        audioPlayer = try! AVAudioPlayer(contentsOf: url!)
        audioPlayer.play()
    }
    
    func playJumpscare() {
        let url = Bundle.main.url(forResource: "Jumpscare", withExtension: "mp4")
        
        audioPlayer = try! AVAudioPlayer(contentsOf: url!)
        audioPlayer.play()
    }
    
    func pauseMusic() {
        if audioPlayer != nil && audioPlayer.isPlaying {
            audioPlayer.pause()
        }
    }
}
