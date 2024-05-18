import SwiftUI

struct MainView: View {
    @State private var isARViewPresented = false
    @State private var jumpscareView = JumpscareView()
    @State private var isGameOver = false
    
  var body: some View {
      
      NavigationStack {
          VStack {
              MainMenuView(isARViewPresented: $isARViewPresented)
                  NavigationLink (
                    destination:
                        ZStack {
                            ZStack{
                                ARViewContainer(isGameOver: $isGameOver)
                                    .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                                
                                HStack (alignment: .top){
                                    Spacer()
                                    VStack (alignment: .trailing){
                                        Text("Find the items!")
                                            .font(.custom("WaitingfortheSunrise", size: 24))
                                            .foregroundStyle(Color.white)
                                        HStack {
                                            Image("OrigamiNF_Phone")
                                            Image("BellNF_Phone")
                                            Image("CoinNF_Phone")
                                        }
                                        Spacer()
                                    }
                                }
                                .padding(.trailing, 20)
                            }
                            
                            if isGameOver {
                                self.jumpscareView
                            }
                        },
                    isActive: $isARViewPresented) {
                        EmptyView()
                    }
                    .navigationBarHidden(true)
          }
          
      }
      
      
      
  }
}

