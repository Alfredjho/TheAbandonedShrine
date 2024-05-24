import SwiftUI

struct MainView: View {
    @State private var isARViewPresented = false
    @State private var jumpscareView = JumpscareView()
    @State private var winView = WinView()
    @State private var isGameOver = false
    @State private var isWin = false
    @State private var isOrigamiCollected = false
    @State private var isBellCollected = false
    @State private var isCoinCollected = false
    @State private var isEverythingCollected = false
    
  var body: some View {
      
      NavigationStack {
          VStack {
              MainMenuView(isARViewPresented: $isARViewPresented)
              
                  .navigationDestination(isPresented: $isARViewPresented) {
                      ZStack {
                          ZStack{
                              ARViewContainer(isGameOver: $isGameOver, isWin: $isWin, isOrigamiCollected: $isOrigamiCollected,
                                              isBellCollected: $isBellCollected, isCoinCollected: $isCoinCollected,
                                              isEverythingCollected: $isEverythingCollected)
                                  .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                                  
                              HStack (alignment: .top) {
                                  
                                  Spacer()
                                  
                                  VStack (alignment: .trailing) {
                                      
                                      Text(isEverythingCollected ? "Apologize at the shrine!" : "Find the items!")
                                          .font(.custom("WaitingfortheSunrise", size: 24))
                                          .foregroundStyle(Color.white)
                                      
                                      HStack (spacing: 15) {
                                          Image(isOrigamiCollected ? "Origami_Found": "Origami_NotFound" )
                                              .resizable()
                                              .frame(width: 60, height: 60)
                                          Image(isBellCollected ? "Bell_Found" : "Bell_NotFound")
                                              .resizable()
                                              .frame(width: 60, height: 60)
                                          Image(isCoinCollected ? "Coin_Found" : "Coin_NotFound")
                                              .resizable()
                                              .frame(width: 60, height: 60)
                                      }
                                      
                                      Spacer()
                                  }
                                  .padding(.top, -20)
                                  
                              }
                              .padding(.trailing, 20)
                          }
                          
                          if isGameOver && !isWin {
                              self.jumpscareView
                                  .onDisappear() {
                                      reset()
                                  }
                          }
                          
                          else if isWin {
                              self.winView
                                  .onDisappear() {
                                      reset()
                                  }
                          }
                          
                      }
                  }
              
          }
          
      }
  }
    
    func reset() {
        if isGameOver {
            isGameOver = false
        } else if isWin {
            isWin = false
        }
    }
}

