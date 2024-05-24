//
//  GameStatus.swift
//  TestFilter
//
//  Created by Alfred Jhonatan on 24/05/24.
//

import Foundation

class GameStatus: ObservableObject {
    @Published var isModelLoaded = false
    @Published var isShrineFound = false
}
