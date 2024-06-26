//
//  MenuViewController.swift
//  Tetris
//
//  Created by Meynabel Dimas Wisodewo on 6/26/24.
//

import UIKit
import SceneKit

class MenuViewController: UIViewController {

    private var gameScene: SCNScene!
    
    // UI
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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // create a new scene
        gameScene = SCNScene(named: "art.scnassets/menu-scene.scn")!
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 21, z: 10)
        gameScene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        gameScene.rootNode.addChildNode(ambientLightNode)
        
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // set the scene to the view
        scnView.scene = gameScene
        scnView.allowsCameraControl = false
        
        // configure the view
        scnView.backgroundColor = UIColor.black
        
        rotateMenuCamera()
        
        setupUI()
        setupButtonEvents()
        
        setupSounds()
    }
    
    private func rotateMenuCamera() {
        let cam = gameScene.rootNode.childNode(withName: "cameraParent", recursively: false)
        cam?.runAction(
            .repeatForever(
                .rotate(
                    by: 360,
                    around: SCNVector3(0, 1, 0),
                    duration: .init(integerLiteral: 1000)
                )
            )
        )
    }
    
    private func setupUI() {
        let safeAreaInsets = view.safeAreaInsets
        
        view.addSubview(titleLabel)
        view.addSubview(buttonPlay)
        
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: safeAreaInsets.top + 80),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
            // Button Play
            buttonPlay.heightAnchor.constraint(equalToConstant: 80),
            buttonPlay.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            buttonPlay.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            buttonPlay.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -safeAreaInsets.bottom - 32),
        ])
    }
    
    private func setupButtonEvents() {
        buttonPlay.addTarget(self, action: #selector(onTapPlay), for: .touchUpInside)
    }
    
    @objc
    private func onTapPlay() {
        buttonPlay.isEnabled = false
        
        playSFX(.clearance)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let vc = storyBoard.instantiateViewController(withIdentifier: "GameViewController")
            let appdelegate = UIApplication.shared.delegate as! AppDelegate
            appdelegate.window!.rootViewController = vc
        }
    }
}
