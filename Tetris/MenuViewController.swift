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
        
    }
}
