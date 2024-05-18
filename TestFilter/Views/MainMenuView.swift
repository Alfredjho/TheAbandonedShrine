import SwiftUI

struct MainMenuView: View {
    let audioPlayer = AudioManager()
    let bgPlayer = AudioManager()
    @Binding var isARViewPresented: Bool
    
    var body: some View {
        ZStack {
            
            Image("Background-Phone")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack {
                
                Image("Title-Phone")
                    .resizable()
                    .frame(maxWidth: 300, maxHeight: 200)
                
                Button{
                    isARViewPresented.toggle()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: /*@START_MENU_TOKEN@*/25.0/*@END_MENU_TOKEN@*/)
                            .frame(maxWidth: 200, maxHeight: 60)
                            .foregroundStyle(Color.gray)
                            
                        Text("Play Game")
                            .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                            .bold()
                            .foregroundStyle(Color.white)
                    }
                }
                .padding(.top, 50)
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


