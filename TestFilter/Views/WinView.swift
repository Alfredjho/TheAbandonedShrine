import SwiftUI

struct WinView: View {
    @State private var winTextAppear = false
    @Environment(\.presentationMode) var presentationMode
    let audioPlayer = AudioManager()
    
    var body: some View {
        VStack {
            ZStack {
                Image("winBG")
                    .resizable()
                    .ignoresSafeArea()
                    .scaledToFill()
                
                if winTextAppear {
                    winText()
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.winTextAppear = true
                }
            }
        }
        .onAppear {
            audioPlayer.playNarration(fileName: "ghostSigh")
        }
    }
    
    func winText() -> some View {
        VStack {
            Image("Owari")
                .resizable()
                .frame(maxWidth: 500, maxHeight: 300)
                .padding(.leading, 15)
            
            Text("You survived!")
                .font(.custom("WaitingfortheSunrise", size: 36))
                .foregroundStyle(Color.white)
                .padding(.top, -50)
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()}
            ) {
                Text("-Menu-")
                    .font(.custom("WaitingfortheSunrise", size: 64))
                    .foregroundStyle(Color.white)
            }
            .padding(.top, 50)
        }
    }
}
//
//#Preview {
//    WinView()
//}
