//
//  GameSounds.swift
//  Tetris
//
//  Created by Meynabel Dimas Wisodewo on 6/26/24.
//

import Foundation
import AVFoundation

enum SFX {
    case clearance
    case gameOver
}

var bgmQueuePlayer = AVQueuePlayer()
var bgmPlayerLooper: AVPlayerLooper? = nil
var sfxPlayer: AVAudioPlayer? = nil
var isSoundSetupDone = false

var clearSoundPath: String = ""
var gameOverSoundPath: String = ""

func setupSounds() {
    guard !isSoundSetupDone else { return }
    
    guard let bgmPath = Bundle.main.path(forResource: "BGM", ofType: "mp3"),
          let clearPath = Bundle.main.path(forResource: "Clear", ofType: "mp3"),
          let gameOverPath = Bundle.main.path(forResource: "GameOver", ofType: "mp3")
    else { return }
    
    // BGM
    let bgmUrl = URL(filePath: bgmPath)
    let playerItem = AVPlayerItem(asset: AVAsset(url: bgmUrl))
    bgmPlayerLooper = AVPlayerLooper(player: bgmQueuePlayer, templateItem: playerItem)
    bgmQueuePlayer.play()
    
    // SFX
    clearSoundPath = clearPath
    gameOverSoundPath = gameOverPath
    
    isSoundSetupDone = true
}

func playSFX(_ sfx: SFX) {
    guard isSoundSetupDone else { return }
    
    let contentUrl: URL
    switch sfx {
    case .clearance:
        contentUrl = URL(filePath: clearSoundPath)
    case .gameOver:
        contentUrl = URL(filePath: gameOverSoundPath)
    }
    
    do {
        sfxPlayer = try AVAudioPlayer(contentsOf: contentUrl)
        sfxPlayer?.play()
    } catch let error {
        print(error.localizedDescription)
    }
}
