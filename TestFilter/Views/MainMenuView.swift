import SwiftUI

struct MainMenuView: View {
    let audioPlayer = AudioManager()
    let bgPlayer = AudioManager()
    @Binding var isARViewPresented: Bool
    
    var body: some View {
        ZStack {
            
            Image("MenuBG")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack {
                
                Image("Title")
                    .resizable()
                    .frame(maxWidth: 500, maxHeight: 300)
                
                Button{
                    isARViewPresented.toggle()
                } label: {
                        Text("-PLAY-")
                            .font(.custom("WaitingfortheSunrise", size: 64))
                            .foregroundStyle(Color.white)
                }
                .padding(.top, 80)
            }
            .onAppear {
                audioPlayer.playBgMusic()
                playBgMusicEvery20Seconds()
            }
        }
    }
    
    private func playBgMusicEvery20Seconds() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
                bgPlayer.playRandomBGM()
                playBgMusicEvery20Seconds() // Schedule next play
            }
    }
}


