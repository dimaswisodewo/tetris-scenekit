//
//  BlockPositions.swift
//  Tetris
//
//  Created by Meynabel Dimas Wisodewo on 6/26/24.
//

import Foundation

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
