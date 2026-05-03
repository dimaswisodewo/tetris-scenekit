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
        txt.font = UIFont(name: "LuckiestGuy-Regular", size: 80)
        txt.textAlignment = .center
        txt.textColor = UIColor.white
        txt.text = "TETRIS"
        txt.backgroundColor = .clear
        txt.translatesAutoresizingMaskIntoConstraints = false
        return txt
    }()
    
    private let buttonPlay: UIButton = {
        let btn = UIButton(type: .roundedRect)
        btn.titleLabel?.font = UIFont(name: "LuckiestGuy-Regular", size: 28)
        btn.setTitleColor(.white, for: .normal)
        btn.setTitle("PLAY", for: .normal)
        btn.backgroundColor = .systemBlue
        btn.layer.cornerRadius = 20
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
        lightNode.light!.intensity = 700 // Reduced intensity
        lightNode.light!.color = UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0) // Pale cyan tone
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
        // Dim indigo ambient to allow neon blocks to pop
        ambientLightNode.light!.color = UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1.0)
        gameScene.rootNode.addChildNode(ambientLightNode)

        // Add colored accent lights for a cyberpunk feel
        let magentaLight = SCNNode()
        magentaLight.light = SCNLight()
        magentaLight.light!.type = .omni
        magentaLight.light!.color = UIColor.magenta
        magentaLight.light!.intensity = 400
        magentaLight.position = SCNVector3(x: -5, y: 5, z: 5)
        gameScene.rootNode.addChildNode(magentaLight)

        let cyanLight = SCNNode()
        cyanLight.light = SCNLight()
        cyanLight.light!.type = .omni
        cyanLight.light!.color = UIColor.cyan
        cyanLight.light!.intensity = 400
        cyanLight.position = SCNVector3(x: 5, y: 5, z: 2)
        gameScene.rootNode.addChildNode(cyanLight)
        
        // Enhance materials with PBR (Physically Based Rendering) and apply neon colors
        gameScene.rootNode.enumerateChildNodes { (node, _) in
            if let geometry = node.geometry {
                // Map node names to BlockType to get the neon colors
                let nameToBlockType: [String: BlockType] = [
                    "I": .hero, "J": .blueRicky, "L": .orangeRicky,
                    "O": .smashboy, "S": .rhodeIslandZ, "T": .teewee, "Z": .clevelandZ
                ]
                
                let blockType = nameToBlockType[node.name ?? ""]
                let color = blockType?.neonColor
                
                geometry.materials.forEach { material in
                    material.lightingModel = .physicallyBased
                    if let neonColor = color {
                        material.diffuse.contents = neonColor
                        material.emission.contents = neonColor
                        material.metalness.contents = 0.1
                        material.roughness.contents = 0.3
                    } else if node.name == "Field" {
                        // Apply the same cyberpunk wall color as in the main game
                        material.diffuse.contents = UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1.0)
                        material.metalness.contents = 0.9
                        material.roughness.contents = 0.15
                    } else {
                        material.metalness.contents = 0.1
                        material.roughness.contents = 0.3
                    }
                }
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
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: safeAreaInsets.top + 100),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Play Button: Centered with padding
            buttonPlay.heightAnchor.constraint(equalToConstant: 70),
            buttonPlay.widthAnchor.constraint(equalToConstant: 240),
            buttonPlay.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonPlay.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -safeAreaInsets.bottom - 80),
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
