//
//  GameViewController.swift
//  Tetris
//
//  Created by Meynabel Dimas Wisodewo on 6/20/24.
//

import UIKit
import SceneKit

class GameViewController: UIViewController {
    enum Direction {
        case left
        case right
        case up
        case down
    }

    enum BlockType: CaseIterable {
        case orangeRicky
        case blueRicky
        case clevelandZ
        case rhodeIslandZ
        case hero
        case teewee
        case smashboy
    }

    enum BlockPosition {
        case position1
        case position2
        case position3
        case position4
    }
    
    private var timer: Timer?
    private let blockHeight: Float = 0.4
    
    private var score: Int = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    private var level: Int = 0 {
        didSet {
            // Increase block drop speed when leveled up
            timer?.invalidate()
            update()
        }
    }
    
    private var clearedRowsCount: Int = 0
    
    // Current game scene
    private var gameScene: SCNScene!
    
    // To store blocks placed in field
    private var placedBlocks = Dictionary<String, SCNNode?>()
    
    private let blockNode: SCNNode = SCNNode()
    private var blockType: BlockType = .orangeRicky
    private var blockPosition: BlockPosition = .position1
    
    // Field size
    private let colCount: Int = 10
    private let rowCount: Int = 20
    
    // Spawn position
    private let fieldSpawnPosition: SCNVector3 = SCNVector3(-0.2, 0, 0)
    private let blockSpawnPosition: SCNVector3 = SCNVector3(0, 8.8, 0)
    
    // Field configuration
    private let maxPosX: Float = 1.6
    private let minPosX: Float = -2
    private let minPosY: Float = 0.4
    private let maxPosY: Float = 8.0
    
    // Object pooling
    private var objectPool: [SCNNode] = []
    private let poolInitialCount: Int = 150
    
    // UI
    private let scoreLabel: UILabel = {
        let txt = UILabel()
        txt.font = UIFont(name: "LuckiestGuy-Regular", size: 20)
        txt.textAlignment = .right
        txt.textColor = .white
        txt.text = "Score: 0"
        txt.backgroundColor = .clear
        txt.translatesAutoresizingMaskIntoConstraints = false
        return txt
    }()
    
    private let buttonLeft: UIButton = {
        let btn = UIButton(type: .roundedRect)
        btn.titleLabel?.font = UIFont(name: "LuckiestGuy-Regular", size: 20)
        btn.setTitleColor(.white, for: .normal)
        btn.setTitle("Left", for: .normal)
        btn.backgroundColor = .systemBlue
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let buttonRight: UIButton = {
        let btn = UIButton(type: .roundedRect)
        btn.titleLabel?.font = UIFont(name: "LuckiestGuy-Regular", size: 20)
        btn.setTitleColor(.white, for: .normal)
        btn.setTitle("Right", for: .normal)
        btn.backgroundColor = .systemBlue
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let buttonDown: UIButton = {
        let btn = UIButton(type: .roundedRect)
        btn.titleLabel?.font = UIFont(name: "LuckiestGuy-Regular", size: 20)
        btn.setTitleColor(.white, for: .normal)
        btn.setTitle("Down", for: .normal)
        btn.backgroundColor = .systemIndigo
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let buttonPause: UIButton = {
        let btn = UIButton(type: .roundedRect)
        btn.titleLabel?.font = UIFont(name: "LuckiestGuy-Regular", size: 20)
        btn.setTitleColor(.white, for: .normal)
        btn.setTitle("Pause", for: .normal)
        btn.configuration?.titleAlignment = .center
        btn.backgroundColor = .systemBlue
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private var isButtonDownDisabled = false
    private var isOver = false
    private var isPaused = false {
        didSet {
            buttonPause.setTitle(isPaused ? "Resume" : "Pause", for: .normal)
        }
    }
    
    // Materials
    private var orangeMat = SCNMaterial()
    private var blueMat = SCNMaterial()
    private var redMat = SCNMaterial()
    private var greenMat = SCNMaterial()
    private var cyanMat = SCNMaterial()
    private var purpleMat = SCNMaterial()
    private var yellowMat = SCNMaterial()
    
    private let wallMat = SCNMaterial()
    
    deinit {
        timer?.invalidate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a new scene
        gameScene = SCNScene(named: "art.scnassets/tetris-scene.scn")!
        
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
        
        gameScene.rootNode.addChildNode(blockNode)
        
        // configure the view
        scnView.backgroundColor = UIColor.black
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
        
        setupDictionary()
        setupUI()
        setupButtonEvents()
        setupMaterials()
        
        populatePool()
        
        generateField()
        generateRandomBlock()
        
        update()
    }
    
    // Populate object pool
    private func populatePool() {
        for _ in 0..<poolInitialCount {
            sendToPool(node: getFromPool())
        }
    }
    
    private func sendToPool(node: SCNNode) {
        node.isHidden = true
        node.position = blockSpawnPosition
        objectPool.append(node)
    }
    
    private func getFromPool() -> SCNNode {
        let node = objectPool.popLast() ?? getBlock()
        node.isHidden = false
        return node
    }
    
    private func setupMaterials() {
        let blockScene = SCNScene(named: "art.scnassets/menu-scene.scn")!
        
        if let j = blockScene.rootNode.childNode(withName: "J", recursively: false),
           let jMat = j.geometry?.material(named: "Blue") {
            blueMat = jMat
        }
        
        if let o = blockScene.rootNode.childNode(withName: "O", recursively: false),
           let oMat = o.geometry?.material(named: "Yellow") {
            yellowMat = oMat
        }
        
        if let t = blockScene.rootNode.childNode(withName: "T", recursively: false),
           let tMat = t.geometry?.material(named: "Purple") {
            purpleMat = tMat
        }
        
        if let i = blockScene.rootNode.childNode(withName: "I", recursively: false),
           let iMat = i.geometry?.material(named: "Cyan") {
            cyanMat = iMat
        }
        
        if let s = blockScene.rootNode.childNode(withName: "S", recursively: false),
           let sMat = s.geometry?.material(named: "Green") {
            greenMat = sMat
        }
        
        if let z = blockScene.rootNode.childNode(withName: "Z", recursively: false),
           let zMat = z.geometry?.material(named: "Red") {
            redMat = zMat
        }
        
        if let l = blockScene.rootNode.childNode(withName: "L", recursively: false),
           let lMat = l.geometry?.material(named: "Orange") {
            orangeMat = lMat
        }
        
        wallMat.diffuse.contents = UIColor.darkGray
        wallMat.diffuse.intensity = 0.1
        wallMat.transparencyMode = .dualLayer
        wallMat.isDoubleSided = true
        wallMat.blendMode = .alpha
        wallMat.shininess = 100
        wallMat.transparency.native = 0.7
        wallMat.cullMode = .back
    }
    
    private func getMaterial(blockType: BlockType) -> SCNMaterial {
        switch blockType {
        case .orangeRicky:
            return orangeMat
        case .blueRicky:
            return blueMat
        case .clevelandZ:
            return redMat
        case .rhodeIslandZ:
            return greenMat
        case .hero:
            return cyanMat
        case .teewee:
            return purpleMat
        case .smashboy:
            return yellowMat
        }
    }
    
    private func setupDictionary() {
        // Seed keys
        /// Increment row by 1 because `hero` block occupy 4 more row on start position, to prevent logic error when
        /// running `isBlockCanBeMovedVertically()` caused by key does not exists
        for row in 1...rowCount + 4 {
            for col in 1...colCount {
                let xPos = ((Float(col) * blockHeight) - (Float(colCount) * 0.2)) - blockHeight
                let yPos = Float(row) * blockHeight
                
                // Change into 1 digit precision floating point
                let xPosRounded = setFloatPrecision(float: xPos, digitBehindComma: 1)
                let yPosRounded = setFloatPrecision(float: yPos, digitBehindComma: 1)
                
                let key = "\(xPosRounded),\(yPosRounded)"
                placedBlocks.updateValue(nil, forKey: key)
            }
        }
    }
    
    // Generate block to fill the field to check if position is correct
    private func fillFieldWithBlocks() {
        for row in 1...rowCount {
            for col in 1...colCount {
                let xPos = ((Float(col) * blockHeight) - (Float(colCount) * 0.2)) - blockHeight
                let yPos = Float(row) * blockHeight
                
                // Change into 1 digit precision floating point
                let xPosRounded = setFloatPrecision(float: xPos, digitBehindComma: 1)
                let yPosRounded = setFloatPrecision(float: yPos, digitBehindComma: 1)
                
                let block = getFromPool()
                block.position = SCNVector3(xPosRounded, yPosRounded, 0)
                gameScene.rootNode.addChildNode(block)
            }
        }
    }
    
    private func showGameOverAlert() {
        let alert = UIAlertController(title: "Game Over", message: "You got \(score) points!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Restart", style: .default, handler: { [weak self] _ in
            // Restart
            self?.restart()
        }))
        alert.addAction(UIAlertAction(title: "Back to Menu", style: .destructive, handler: { [weak self] _ in
            // Back to menu
            self?.backToMenu()
        }))
        
        present(alert, animated: true)
    }
    
    private func restart() {
        let blocks = gameScene.rootNode.childNodes { node, _ in
            node.name == "Cube"
        }
        for block in blocks {
            sendToPool(node: block)
        }
        for block in blockNode.childNodes {
            sendToPool(node: block)
        }
        
        setupDictionary()
        level = 0
        score = 0
        isOver = false
        isPaused = false
        
        timer?.invalidate()
        update()
    }
    
    private func backToMenu() {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let vc = storyBoard.instantiateViewController(withIdentifier: "MenuViewController")
        let appdelegate = UIApplication.shared.delegate as! AppDelegate
        appdelegate.window!.rootViewController = vc
    }
    
    private func setFloatPrecision(float: Float, digitBehindComma: Int) -> Float {
        let precisionMultiplier = Float(10 * digitBehindComma)
        let finalValue = Float(round(precisionMultiplier * float) / precisionMultiplier)
        return finalValue == -0.0 ? 0.0 : finalValue
    }
    
    @objc
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        guard !isPaused else { return }
        
        gestureRecognize.cancelsTouchesInView = true
        
        if gestureRecognize.state == .ended && isBlockCanBeRotated() {
            rotateBlock()
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    // MARK: - Method
    
    private func setupUI() {
        let safeAreaInsets = view.safeAreaInsets
        
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        view.addSubview(buttonPause)
        view.addSubview(scoreLabel)
        view.addSubview(buttonLeft)
        view.addSubview(buttonRight)
        view.addSubview(buttonDown)
        
        NSLayoutConstraint.activate([
            // Pause Button
            buttonPause.centerYAnchor.constraint(equalTo: scoreLabel.centerYAnchor, constant: -8),
            buttonPause.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            buttonPause.widthAnchor.constraint(equalToConstant: 100),
            buttonPause.heightAnchor.constraint(equalToConstant: 36),
            // Score Label
            scoreLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: safeAreaInsets.top + 36),
            scoreLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scoreLabel.heightAnchor.constraint(equalToConstant: 60),
            scoreLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
            // Left Button
            buttonLeft.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1 / 3),
            buttonLeft.heightAnchor.constraint(equalToConstant: 80),
            // Down Button
            buttonDown.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1 / 3),
            buttonDown.heightAnchor.constraint(equalToConstant: 80),
            // Right Button
            buttonRight.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1 / 3),
            buttonRight.heightAnchor.constraint(equalToConstant: 80),
        ])
        
        buttonPause.layer.cornerRadius = 12
        
        stackView.addArrangedSubview(buttonLeft)
        stackView.addArrangedSubview(buttonDown)
        stackView.addArrangedSubview(buttonRight)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -safeAreaInsets.bottom - 32),
        ])
    }

    private func update() {
        timer = Timer.scheduledTimer(withTimeInterval: 1 - (0.05 * Double(level)), repeats: true, block: { [weak self] _ in
            guard let self = self else { return }
            
            if isButtonDownDisabled {
                isButtonDownDisabled = false
            }
            
            if self.isBlockCanBeMovedVertically() {
                self.moveBlock(.down)
            } else {
                self.placeBlockOnField()
                self.generateRandomBlock() // Should check if game over before generate random block
                
                isOver = self.isGameOver()
                self.blockNode.isHidden = isOver
                
                if isOver {
                    self.timer?.invalidate()
                    self.showGameOverAlert()
                    playSFX(.gameOver)
                }
            }
        })
    }
    
    // MARK: - Block Control
    
    private func generateRandomBlock() {
        guard let nextBlockType = BlockType.allCases.randomElement()
        else { return }
        
        blockNode.position = blockSpawnPosition
        
        blockType = nextBlockType
        
        let blockPos: [[Int]] = getBlockPosition(blockType: blockType, blockPosition: .position1) ?? smashboyPos
        blockPosition = .position1
        
        let mat: SCNMaterial = getMaterial(blockType: blockType)
        
        for pos in blockPos {
            let block = getFromPool()
            block.geometry?.materials = [mat]
            block.position = SCNVector3(x: Float(pos[0]) * blockHeight, y: Float(pos[1]) * blockHeight, z: 0)
            blockNode.addChildNode(block)
        }
    }
    
    private func generateField() {
        let field = getField()
        field.position = fieldSpawnPosition
        field.childNodes.first?.geometry?.materials = [wallMat]
        gameScene.rootNode.addChildNode(field)
    }
    
    private func getField() -> SCNNode {
        let tetrisField = SCNScene(named: "art.scnassets/tetris-field.dae")!
        return tetrisField.rootNode.childNode(withName: "Field", recursively: false)!
    }
    
    private func getBlock() -> SCNNode {
        let tetrisScene = SCNScene(named: "art.scnassets/tetris-block.dae")!
        return tetrisScene.rootNode.childNode(withName: "Cube", recursively: false)!
    }
    
    private func rotateBlock() {
        let nextBlockPos: BlockPosition = getNextBlockPositionType()
        
        guard let newBlockPos = getBlockPosition(blockType: blockType, blockPosition: nextBlockPos)
        else { return }
        
        // Assign new block pos
        blockPosition = nextBlockPos
        
        // Reposition blocks
        for i in 0..<4 { // Every tetris blocks consists of 4 small blocks
            let xPos = newBlockPos[i][0]
            let yPos = newBlockPos[i][1]
            blockNode.childNodes[i].position = SCNVector3(Float(xPos) * blockHeight, Float(yPos) * blockHeight, 0)
        }
    }
    
    // Determine next block position
    private func getNextBlockPositionType() -> BlockPosition {
        switch blockPosition {
        case .position1:
            return .position2
        case .position2:
            return .position3
        case .position3:
            return .position4
        case .position4:
            return .position1
        }
    }
    
    private func getBlockPosition(blockType: BlockType, blockPosition: BlockPosition) -> [[Int]]? {
        switch blockType {
        case .orangeRicky:
            switch blockPosition {
            case .position1:
                return orangeRickyPos
            case .position2:
                return orangeRickyPos2
            case .position3:
                return orangeRickyPos3
            case .position4:
                return orangeRickyPos4
            }
        case .blueRicky:
            switch blockPosition {
            case .position1:
                return blueRickyPos
            case .position2:
                return blueRickyPos2
            case .position3:
                return blueRickyPos3
            case .position4:
                return blueRickyPos4
            }
        case .clevelandZ:
            switch blockPosition {
            case .position1:
                return clevelandZPos
            case .position2:
                return clevelandZPos2
            case .position3:
                return clevelandZPos3
            case .position4:
                return clevelandZPos4
            }
        case .rhodeIslandZ:
            switch blockPosition {
            case .position1:
                return rhodeIslandZPos
            case .position2:
                return rhodeIslandZPos2
            case .position3:
                return rhodeIslandZPos3
            case .position4:
                return rhodeIslandZPos4
            }
        case .hero:
            switch blockPosition {
            case .position1:
                return heroPos
            case .position2:
                return heroPos2
            case .position3:
                return heroPos3
            case .position4:
                return heroPos4
            }
        case .teewee:
            switch blockPosition {
            case .position1:
                return teeweePos
            case .position2:
                return teeweePos2
            case .position3:
                return teeweePos3
            case .position4:
                return teeweePos4
            }
        case .smashboy:
            break
        }
        return nil
    }
    
    private func isBlockCanBeMovedVertically() -> Bool {
        for block in blockNode.childNodes {
            let xPos = setFloatPrecision(float: block.worldPosition.x, digitBehindComma: 1)
            let yPos = setFloatPrecision(float: block.worldPosition.y - blockHeight, digitBehindComma: 1)
            
            let key = "\(xPos),\(yPos)"
            
            if yPos < minPosY {
                return false
            }
            
            guard let dictValue = placedBlocks[key] else {
                return false
            }
            if dictValue != nil {
                return false
            }
        }
        return true
    }
    
    private func forcedDown() {
        timer?.invalidate()
        while true {
            if !isBlockCanBeMovedVertically() { break }
            blockNode.position = SCNVector3(
                x: blockNode.position.x,
                y: blockNode.position.y - blockHeight,
                z: blockNode.position.z
            )
        }
        update()
    }
    
    private func isBlockCanBeMovedRight() -> Bool {
        for block in blockNode.childNodes {
            let xPos = setFloatPrecision(float: block.worldPosition.x + blockHeight, digitBehindComma: 1)
            let yPos = setFloatPrecision(float: block.worldPosition.y, digitBehindComma: 1)
            
            let key = "\(xPos),\(yPos)"
            
            // Failed to get dictionary value
            guard let dictValue = placedBlocks[key] else {
                return false
            }
            
            // Cannot move right
            if dictValue != nil || xPos > maxPosX {
                return false
            }
        }
        return true
    }
    
    private func isBlockCanBeMovedLeft() -> Bool {
        for block in blockNode.childNodes {
            let xPos = setFloatPrecision(float: block.worldPosition.x - blockHeight, digitBehindComma: 1)
            let yPos = setFloatPrecision(float: block.worldPosition.y, digitBehindComma: 1)
            
            let key = "\(xPos),\(yPos)"
            
            // Failed to get dictionary value
            guard let dictValue = placedBlocks[key] else {
                return false
            }
            
            // Cannot move left
            if dictValue != nil || xPos < minPosX {
                return false
            }
        }
        return true
    }
    
    private func isBlockCanBeRotated() -> Bool {
        let nextBlockPos: BlockPosition = getNextBlockPositionType()
        
        guard let newBlockPos = getBlockPosition(blockType: blockType, blockPosition: nextBlockPos)
        else { return false }
        
        for i in 0..<4 { // Every tetris blocks consists of 4 small blocks
            let xPos = setFloatPrecision(
                float: blockNode.worldPosition.x + (Float(newBlockPos[i][0]) * blockHeight),
                digitBehindComma: 1
            )
            
            let yPos = setFloatPrecision(
                float: blockNode.worldPosition.y + (Float(newBlockPos[i][1]) * blockHeight),
                digitBehindComma: 1
            )
            
            // Check by block position
            if xPos < minPosX || xPos > maxPosX || yPos < minPosY {
                return false
            }
            
            // Check if block position after rotated is occupied
            let key = "\(xPos),\(yPos)"
            if let dictValue = placedBlocks[key], dictValue != nil {
                return false
            }
        }
        return true
    }
    
    private func moveBlock(_ direction: Direction) {
        switch direction {
        case .left:
            moveBlock(x: -blockHeight, y: 0, z: 0)
        case .right:
            moveBlock(x: blockHeight, y: 0, z: 0)
        case .up:
            moveBlock(x: 0, y: blockHeight, z: 0)
        case .down:
            moveBlock(x: 0, y: -blockHeight, z: 0)
        }
    }
    
    private func moveBlock(x: Float, y: Float, z: Float) {
        blockNode.position = SCNVector3(
            x: blockNode.position.x + x,
            y: blockNode.position.y + y,
            z: 0
        )
    }
    
    private func placeBlockOnField() {
        for block in blockNode.childNodes {
            let xPos = setFloatPrecision(float: block.worldPosition.x, digitBehindComma: 1)
            let yPos = setFloatPrecision(float: block.worldPosition.y, digitBehindComma: 1)
            
            let key = "\(xPos),\(yPos)"
            placedBlocks.updateValue(block, forKey: key)
        }
        
        checkForClearance()
        
        // Remove block from parent node
        for block in blockNode.childNodes {
            block.transform = block.convertTransform(SCNMatrix4Identity, to: gameScene.rootNode) // Prevent changing transform in world space
            block.removeFromParentNode()
            gameScene.rootNode.addChildNode(block)
        }
    }
    
    private func checkForClearance() {
        var minY: Float = 999
        var maxY: Float = -999
        // Get row for clearance checking from recently placed block in field
        for block in blockNode.childNodes {
            minY = min(minY, block.worldPosition.y)
            maxY = max(maxY, block.worldPosition.y)
        }
        
        minY = setFloatPrecision(float: minY, digitBehindComma: 1)
        maxY = setFloatPrecision(float: maxY, digitBehindComma: 1)
        
        var clearanceStartIndex: Int = 999
        var numOfRowsCleared: Int = 0
        let startRow = Int(round(minY / blockHeight))  // Start row for clearance checking
        let distance = Int(round(abs(maxY - minY) / blockHeight)) // Distance from lowest row to highest row for clearance checking
        for row in startRow...startRow + distance {
            var keysForClearance: [String] = []
            var isRowFull = true
            for col in 1...colCount {
                let xPos = ((Float(col) * blockHeight) - (Float(colCount) * 0.2)) - blockHeight
                let yPos = Float(row) * blockHeight
                
                // Change into 1 digit precision floating point
                let xPosRounded = setFloatPrecision(float: xPos, digitBehindComma: 1)
                let yPosRounded = setFloatPrecision(float: yPos, digitBehindComma: 1)
                
                let key = "\(xPosRounded),\(yPosRounded)"
                
                guard let dictValue = placedBlocks[key], let _ = dictValue
                else {
                    isRowFull = false
                    break
                }
                
                keysForClearance.append(key)
            }
            
            guard isRowFull else {
                continue
            }
            
            numOfRowsCleared += 1
            
#if DEBUG
            print("Checking for clearance at Row \(row)")
#endif
            
            clearanceStartIndex = min(clearanceStartIndex, row)
            
            // Clearance
            for key in keysForClearance {
                guard let block = placedBlocks[key], let unwrappedBlock = block
                else {
#if DEBUG
                    print("Failed to do clearance on \(key)")
#endif
                    break
                }
                
                sendToPool(node: unwrappedBlock)
                
                placedBlocks.updateValue(nil, forKey: key)
            }
        }
        
        guard clearanceStartIndex < 999 else { return }
        
        // Bring down blocks placed above
        var bottom = clearanceStartIndex
        var top = clearanceStartIndex + 1
        while bottom < rowCount {
            if top > rowCount {
                // Out of bounds, all rows above are empty. Thus, set nil to current row, then break the loop
                for row in 1...colCount {
                    let xPos = ((Float(row) * blockHeight) - (Float(colCount) * 0.2)) - blockHeight
                    let yPos = Float(bottom) * blockHeight
                    
                    // Change into 1 digit precision floating point
                    let xPosRounded = setFloatPrecision(float: xPos, digitBehindComma: 1)
                    let yPosRounded = setFloatPrecision(float: yPos, digitBehindComma: 1)
                    
                    let key = "\(xPosRounded),\(yPosRounded)"
                    placedBlocks.updateValue(nil, forKey: key)
                }
                break
            }
            guard let keys = getRowBlockKeysIfNotNil(startRow: top) else {
                top += 1
                continue
            }
            
            // Bring down
            for row in 1...colCount {
                let xPos = ((Float(row) * blockHeight) - (Float(colCount) * 0.2)) - blockHeight
                let yPos = Float(bottom) * blockHeight
                
                // Change into 1 digit precision floating point
                let xPosRounded = setFloatPrecision(float: xPos, digitBehindComma: 1)
                let yPosRounded = setFloatPrecision(float: yPos, digitBehindComma: 1)
                
                let key = "\(xPosRounded),\(yPosRounded)"
                let keyAbove = keys[row - 1]
                
                guard let block = placedBlocks[keyAbove] else {
                    fatalError()
                }
                
                if let unwrappedBlock = block {
                    unwrappedBlock.position = SCNVector3(
                        x: unwrappedBlock.position.x,
                        y: unwrappedBlock.position.y - Float(top - bottom) * blockHeight,
                        z: 0
                    )
                    placedBlocks.updateValue(unwrappedBlock, forKey: key)
                } else {
                    placedBlocks.updateValue(nil, forKey: key)
                }
                
                placedBlocks.updateValue(nil, forKey: keyAbove)
            }
            
            bottom += 1
        }
        
        // Calculate score and level
        print("num of rows cleared: \(numOfRowsCleared)")
        calculateScore(numOfRowsCleared: numOfRowsCleared)
        calculateLevel()
        
        // Play clearance sfx
        playSFX(.clearance)
    }
    
    // Get keys of 1 row, return nil if row empty
    private func getRowBlockKeysIfNotNil(startRow: Int) -> [String]? {
        var keys = [String]()
        var isRowEmpty = true
        for col in 1...colCount {
            let xPos = ((Float(col) * blockHeight) - (Float(colCount) * 0.2)) - blockHeight
            let yPos = Float(startRow) * blockHeight
            
            // Change into 1 digit precision floating point
            let xPosRounded = setFloatPrecision(float: xPos, digitBehindComma: 1)
            let yPosRounded = setFloatPrecision(float: yPos, digitBehindComma: 1)
            
            let key = "\(xPosRounded),\(yPosRounded)"
            keys.append(key)
            
            if let block = placedBlocks[key], let _ = block {
                isRowEmpty = false
            }
        }
        return isRowEmpty ? nil : keys
    }
    
    private func isGameOver() -> Bool {
        for block in blockNode.childNodes {
            let xPos = setFloatPrecision(float: block.worldPosition.x, digitBehindComma: 1)
            let yPos = setFloatPrecision(float: block.worldPosition.y, digitBehindComma: 1)
            
            let key = "\(xPos),\(yPos)"
            
            guard let dictValue = placedBlocks[key]
            else { continue }
            
            if let unwrappedDictValue = dictValue {
#if DEBUG
                print("Dict key: \(key), Value: \(unwrappedDictValue.description)")
#endif
                return true
            }
        }
        return false
    }
    
    /* 
     Rules for score and level calculation based on:
     https://en.wikipedia.org/wiki/Tetris_(NES_video_game)#:~:text=At%20level%200%2C%20a%20Tetris,a%20Tetris%20worth%201%2C200%20points.
     */
    
    // Score calculation
    private func calculateScore(numOfRowsCleared: Int) {
        guard numOfRowsCleared > 0 else { return }
        
        if numOfRowsCleared == 1 {
            score += 40 * (level + 1)
        } else if numOfRowsCleared == 2 {
            score += 100 * (level + 1)
        } else if numOfRowsCleared == 3 {
            score += 300 * (level + 1)
        } else {
            score += 1200 * (level + 1)
        }
        
        clearedRowsCount += numOfRowsCleared
    }
    
    // Should increase level for every 10 lines cleared
    private func calculateLevel() {
        print("all cleared rows count: \(clearedRowsCount)")
        while clearedRowsCount >= 10 {
            level += 1
            clearedRowsCount -= 10
        }
    }
    
    // MARK: - Button events
    
    private func setupButtonEvents() {
        buttonPause.addTarget(self, action: #selector(tapPause), for: .touchUpInside)
        buttonLeft.addTarget(self, action: #selector(tapButtonLeft), for: .touchUpInside)
        buttonRight.addTarget(self, action: #selector(tapButtonRight), for: .touchUpInside)
        buttonDown.addTarget(self, action: #selector(tapButtonDown), for: .touchUpInside)
    }
    
    private func togglePause() {
        isPaused = !isPaused
        
        buttonLeft.isEnabled = !isPaused
        buttonDown.isEnabled = !isPaused
        buttonRight.isEnabled = !isPaused
        
        if isPaused {
            timer?.invalidate()
            bgmQueuePlayer.pause()
        } else {
            update()
            bgmQueuePlayer.play()
        }
    }
    
    @objc
    private func tapPause() {
        togglePause()
    }
    
    @objc
    private func tapButtonLeft() {
        guard isBlockCanBeMovedLeft(), !isOver else { return }
        moveBlock(.left)
    }
    
    @objc
    private func tapButtonRight() {
        guard isBlockCanBeMovedRight(), !isOver else { return }
        moveBlock(.right)
    }
    
    @objc
    private func tapButtonDown() {
        guard !isButtonDownDisabled, !isOver else { return }
        
        forcedDown()
        isButtonDownDisabled = true
    }
    
    // MARK: - Keypress events
    
#if DEBUG
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let key = presses.first?.key else { return }
        
        switch key.keyCode {
        case .keyboardUpArrow:
            if isBlockCanBeRotated() {
                rotateBlock()
            }
        case .keyboardDownArrow:
            tapButtonDown()
        case .keyboardLeftArrow:
            tapButtonLeft()
        case .keyboardRightArrow:
            tapButtonRight()
        default:
            break
        }
    }
#endif
}
