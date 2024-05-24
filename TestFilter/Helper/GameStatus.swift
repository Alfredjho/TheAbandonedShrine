import Foundation

class GameStatus: ObservableObject {
    @Published var isModelLoaded = false
    @Published var isShrineFound = false
}
