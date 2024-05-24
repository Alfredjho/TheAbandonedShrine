import SwiftUI

struct JumpscareView: View {
    @State private var gameOverTextAppear = false
    @Environment(\.presentationMode) var presentationMode
    let audioPlayer = AudioManager()
    
    var body: some View {
        VStack {
            
            ZStack {
                
                Image("JumpscareBG")
                    .resizable()
                    .ignoresSafeArea()
                    .scaledToFill()
                
                if gameOverTextAppear {
                    gameOverText()
                }
                
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
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
            Image("gameOver")
                .resizable()
                .frame(maxWidth: 500, maxHeight: 300)
            
            Text("You died!")
                .font(.custom("WaitingfortheSunrise", size: 36))
                .foregroundStyle(Color.white)
                .padding(.top, -50)
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }
            ) {
                Text("-Menu-")
                    .font(.custom("WaitingfortheSunrise", size: 64))
                    .foregroundStyle(Color.white)
            }
            .padding(.top, 50)
        }
        
    }
    
}

//#Preview {
//    JumpscareView()
//}
