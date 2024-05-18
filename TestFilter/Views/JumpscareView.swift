import SwiftUI

struct JumpscareView: View {
    @State private var gameOverTextAppear = false
    @Environment(\.presentationMode) var presentationMode
    let audioPlayer = AudioManager()
    
    var body: some View {
        VStack {
            ZStack {
                Image("JumpscareBG-Phone")
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
            Image("gameOver-Phone")
                .resizable()
                .frame(maxWidth: 350, maxHeight: 200)
            Button(action: {
                presentationMode.wrappedValue.dismiss()}
            ) {
                Text("-Menu-")
                    .font(.custom("WaitingfortheSunrise", size: 64))
                    .foregroundStyle(Color.white)
            }
        }
    }
}

//#Preview {
//    JumpscareView()
//}
