//
//  BlockPositions.swift
//  Tetris
//
//  Created by Meynabel Dimas Wisodewo on 6/26/24.
//

import Foundation
import UIKit

/// Represents a coordinate in the Tetris grid.
struct GridPosition: Hashable {
    var col, row: Int
}

/// The four possible rotation states for a block.
enum BlockPosition: Int, CaseIterable {
    case position1 = 0, position2, position3, position4
    
    /// Cycles to the next rotation state.
    var next: BlockPosition { BlockPosition(rawValue: (self.rawValue + 1) % 4) ?? .position1 }
}

/// The seven standard Tetris block types (Tetrominoes).
enum BlockType: CaseIterable {
    case orangeRicky, blueRicky, clevelandZ, rhodeIslandZ, hero, teewee, smashboy
    
    /// Returns the relative grid positions for the block based on its current rotation state.
    func positions(for state: BlockPosition) -> [GridPosition] {
        let coords: [[Int]]
        switch self {
        case .orangeRicky: coords = [orangeRickyPos, orangeRickyPos2, orangeRickyPos3, orangeRickyPos4][state.rawValue]
        case .blueRicky: coords = [blueRickyPos, blueRickyPos2, blueRickyPos3, blueRickyPos4][state.rawValue]
        case .clevelandZ: coords = [clevelandZPos, clevelandZPos2, clevelandZPos3, clevelandZPos4][state.rawValue]
        case .rhodeIslandZ: coords = [rhodeIslandZPos, rhodeIslandZPos2, rhodeIslandZPos3, rhodeIslandZPos4][state.rawValue]
        case .hero: coords = [heroPos, heroPos2, heroPos3, heroPos4][state.rawValue]
        case .teewee: coords = [teeweePos, teeweePos2, teeweePos3, teeweePos4][state.rawValue]
        case .smashboy: coords = [smashboyPos, smashboyPos, smashboyPos, smashboyPos][state.rawValue]
        }
        return coords.map { GridPosition(col: $0[0], row: $0[1]) }
    }
    
    /// Returns a vibrant neon color for the block type.
    var neonColor: UIColor {
        switch self {
        case .hero: return UIColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0)          // Cyan
        case .blueRicky: return UIColor(red: 0.0, green: 0.4, blue: 1.0, alpha: 1.0)     // Neon Blue
        case .orangeRicky: return UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0)   // Neon Orange
        case .smashboy: return UIColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0)      // Neon Yellow
        case .rhodeIslandZ: return UIColor(red: 0.22, green: 1.0, blue: 0.08, alpha: 1.0)// Neon Green
        case .teewee: return UIColor(red: 0.74, green: 0.07, blue: 1.0, alpha: 1.0)     // Neon Purple
        case .clevelandZ: return UIColor(red: 1.0, green: 0.03, blue: 0.23, alpha: 1.0)   // Neon Red
        }
    }
}

// MARK: - Tetris Block Coordinates
// These constants define the relative coordinates (column, row) for each block type in its four possible rotations.
// Each block consists of 4 segments, and the coordinates are relative to the block's pivot point.

// Orange Ricky (L-Block)
let orangeRickyPos = [[1, 1], [-1, 0], [0, 0], [1, 0]]
let orangeRickyPos2 = [[0, 1], [0, 0], [0, -1], [1, -1]]
let orangeRickyPos3 = [[-1, 0], [0, 0], [1, 0], [-1, -1]]
let orangeRickyPos4 = [[-1, 1], [0, 1], [0, 0], [0, -1]]

// Blue Ricky (J-Block)
let blueRickyPos = [[-1, 1], [-1, 0], [0, 0], [1, 0]]
let blueRickyPos2 = [[0, 1], [1, 1], [0, 0], [0, -1]]
let blueRickyPos3 = [[-1, 0], [0, 0], [1, 0], [1, -1]]
let blueRickyPos4 = [[0, 1], [0, 0], [-1, -1], [0, -1]]

// Cleveland Z (Z-Block)
let clevelandZPos = [[-1, 0], [0, 0], [0, -1], [1, -1]]
let clevelandZPos2 = [[0, 1], [0, 0], [-1, 0], [-1, -1]]
let clevelandZPos3 = [[-1, 1], [0, 1], [0, 0], [1, 0]]
let clevelandZPos4 = [[1, 1], [0, 0], [1, 0], [0, -1]]

// Rhode Island Z (S-Block)
let rhodeIslandZPos = [[-1, -1], [0, 0], [0, -1], [1, 0]]
let rhodeIslandZPos2 = [[-1, 1], [-1, 0], [0, 0], [0, -1]]
let rhodeIslandZPos3 = [[-1, 0], [0, 1], [0, 0], [1, 1]]
let rhodeIslandZPos4 = [[0, 1], [0, 0], [1, 0], [1, -1]]

// Hero (I-Block)
let heroPos = [[-1, 0], [0, 0], [1, 0], [2, 0]]
let heroPos2 = [[0, 2], [0, 1], [0, 0], [0, -1]]
let heroPos3 = [[-1, 1], [0, 1], [1, 1], [2, 1]]
let heroPos4 = [[1, 2], [1, 1], [1, 0], [1, -1]]

// Teewee (T-Block)
let teeweePos = [[0, 1], [0, 0], [-1, 0], [1, 0]]
let teeweePos2 = [[0, 1], [0, 0], [1, 0], [0, -1]]
let teeweePos3 = [[-1, 0], [0, 0], [1, 0], [0, -1]]
let teeweePos4 = [[0, 1], [0, 0], [-1, 0], [0, -1]]

// Smashboy (O-Block) - Symmetric, so same for all rotations
let smashboyPos = [[-1, 0], [0, 0], [-1, -1], [0, -1]]
