//
//  MenuViewController.swift
//  Tetris
//
//  Created by Meynabel Dimas Wisodewo on 6/26/24.
//

import UIKit
import SceneKit

/// The initial screen of the game.
/// Displays a rotating 3D Tetris scene and a "Play" button.
class MenuViewController: UIViewController {

    private var gameScene: SCNScene!
    
    // MARK: - UI Elements
    
    private let titleLabel: UILabel = {
        let txt = UILabel()
        txt.font = UIFont(name: "LuckiestGuy-Regular", size: 60)
        txt.textAlignment = .right
        txt.textColor = .white
        txt.text = "TETRIS"
        txt.backgroundColor = .clear
        txt.translatesAutoresizingMaskIntoConstraints = false
        return txt
    }()
    
    private let buttonPlay: UIButton = {
        let btn = UIButton(type: .roundedRect)
        btn.titleLabel?.font = UIFont(name: "LuckiestGuy-Regular", size: 20)
        btn.setTitleColor(.white, for: .normal)
        btn.setTitle("Play", for: .normal)
        btn.backgroundColor = .systemBlue
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Load the 3D menu background scene
        gameScene = SCNScene(named: "art.scnassets/menu-scene.scn")!
        
        // Setup lighting for the menu scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .directional
        lightNode.light!.intensity = 1000
        lightNode.light!.castsShadow = true
        lightNode.light!.shadowMode = .deferred
        lightNode.light!.shadowSampleCount = 16
        lightNode.light!.shadowRadius = 8.0
        lightNode.light!.shadowColor = UIColor.black.withAlphaComponent(0.6)
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        lightNode.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 4, 0)
        gameScene.rootNode.addChildNode(lightNode)
        
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor(white: 0.4, alpha: 1.0)
        gameScene.rootNode.addChildNode(ambientLightNode)
        
        // Enhance materials with PBR (Physically Based Rendering) for a modern look
        gameScene.rootNode.enumerateChildNodes { (node, _) in
            node.geometry?.materials.forEach { material in
                material.lightingModel = .physicallyBased
                material.metalness.contents = 0.1
                material.roughness.contents = 0.3
            }
        }
        
        // Configure the SCNView
        let scnView = self.view as! SCNView
        scnView.scene = gameScene
        scnView.allowsCameraControl = false
        scnView.backgroundColor = UIColor.black
        
        // Start the rotating camera effect
        rotateMenuCamera()
        
        setupUI()
        setupButtonEvents()
        
        // Initialize background music
        setupSounds()
    }
    
    /// Animates the camera to rotate continuously around the scene's center.
    private func rotateMenuCamera() {
        let cam = gameScene.rootNode.childNode(withName: "cameraParent", recursively: false)
        cam?.runAction(
            .repeatForever(
                .rotate(
                    by: 360,
                    around: SCNVector3(0, 1, 0),
                    duration: 1000 // Slow rotation
                )
            )
        )
    }
    
    /// Layout the title and play button.
    private func setupUI() {
        let safeAreaInsets = view.safeAreaInsets
        
        view.addSubview(titleLabel)
        view.addSubview(buttonPlay)
        
        NSLayoutConstraint.activate([
            // Title: Positioned near the top
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: safeAreaInsets.top + 80),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
            // Play Button: Stretches across the bottom
            buttonPlay.heightAnchor.constraint(equalToConstant: 80),
            buttonPlay.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            buttonPlay.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            buttonPlay.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -safeAreaInsets.bottom - 32),
        ])
    }
    
    private func setupButtonEvents() {
        buttonPlay.addTarget(self, action: #selector(onTapPlay), for: .touchUpInside)
    }
    
    /// Transitions from the menu to the main game view.
    @objc
    private func onTapPlay() {
        buttonPlay.isEnabled = false
        
        // Play sound effect on interaction
        playSFX(.clearance)
        
        // Brief delay for the sound to play before transitioning
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let vc = storyBoard.instantiateViewController(withIdentifier: "GameViewController")
            let appdelegate = UIApplication.shared.delegate as! AppDelegate
            appdelegate.window!.rootViewController = vc
        }
    }
}
