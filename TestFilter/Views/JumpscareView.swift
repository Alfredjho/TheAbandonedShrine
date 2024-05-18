import SwiftUI

struct JumpscareView: View {
    @State private var gameOverTextAppear = false
    @Environment(\.presentationMode) var presentationMode
    let audioPlayer = AudioManager()
    
    var body: some View {
        VStack {
            ZStack {
                Image("JumpscareImg")
                    .resizable()
                    .ignoresSafeArea()
                    .scaledToFill()
                
                if gameOverTextAppear {
                    gameOverText()
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.gameOverTextAppear = true
                }
            }
        }
        .onAppear {
            audioPlayer.playJumpscare()
        }
    }
    
    func gameOverText() -> some View {
        VStack {
            Text("Game Over!")
                .foregroundStyle(Color.white)
                .font(.title)
                .bold()
            Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Back to Main Menu")
                        }
        }
    }
}

//#Preview {
//    JumpscareView()
//}
