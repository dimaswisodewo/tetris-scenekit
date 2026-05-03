//
//  GameSounds.swift
//  Tetris
//
//  Created by Meynabel Dimas Wisodewo on 6/26/24.
//

// MARK: - Game Sound Management
// This file handles the setup and playback of background music (BGM) and sound effects (SFX).

import Foundation
import AVFoundation

/// Types of sound effects available in the game.
enum SFX {
    case clearance  // Played when a row is cleared
    case gameOver   // Played when the game ends
}

// Global player instances
var bgmQueuePlayer = AVQueuePlayer()
var bgmPlayerLooper: AVPlayerLooper? = nil
var sfxPlayer: AVAudioPlayer? = nil
var isSoundSetupDone = false

// Paths to sound files
var clearSoundPath: String = ""
var gameOverSoundPath: String = ""

/// Initializes the sound system, loads audio files, and starts BGM.
func setupSounds() {
    guard !isSoundSetupDone else { return }
    
    // Locate sound resources in the main bundle
    guard let bgmPath = Bundle.main.path(forResource: "BGM", ofType: "mp3"),
          let clearPath = Bundle.main.path(forResource: "Clear", ofType: "mp3"),
          let gameOverPath = Bundle.main.path(forResource: "GameOver", ofType: "mp3")
    else {
        print("Error: Could not find sound files in bundle.")
        return
    }
    
    // Setup and start looping Background Music
    let bgmUrl = URL(fileURLWithPath: bgmPath)
    let playerItem = AVPlayerItem(asset: AVAsset(url: bgmUrl))
    bgmPlayerLooper = AVPlayerLooper(player: bgmQueuePlayer, templateItem: playerItem)
    bgmQueuePlayer.play()
    
    // Store paths for SFX
    clearSoundPath = clearPath
    gameOverSoundPath = gameOverPath
    
    isSoundSetupDone = true
}

/// Plays a specific sound effect.
/// - Parameter sfx: The sound effect to play.
func playSFX(_ sfx: SFX) {
    guard isSoundSetupDone else { return }
    
    let contentUrl: URL
    switch sfx {
    case .clearance:
        contentUrl = URL(fileURLWithPath: clearSoundPath)
    case .gameOver:
        contentUrl = URL(fileURLWithPath: gameOverSoundPath)
    }
    
    do {
        // Create a new player for the SFX and play it
        sfxPlayer = try AVAudioPlayer(contentsOf: contentUrl)
        sfxPlayer?.play()
    } catch let error {
        print("SFX Playback Error: \(error.localizedDescription)")
    }
}
