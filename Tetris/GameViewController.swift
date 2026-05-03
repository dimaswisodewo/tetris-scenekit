//
//  GameViewController.swift
//  Tetris
//
//  Created by Meynabel Dimas Wisodewo on 6/20/24.
//

import UIKit
import SceneKit
import ARKit

/// Main controller for the AR Tetris game.
/// Handles AR session management, game logic, rendering, and user interaction.
class GameViewController: UIViewController, ARSCNViewDelegate {
    
    // MARK: - Types
    
    /// Directions for block movement.
    enum Direction {
        case left, right, up, down
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
    }

    /// The four possible rotation states for a block.
    enum BlockPosition: Int, CaseIterable {
        case position1 = 0, position2, position3, position4
        
        /// Cycles to the next rotation state.
        var next: BlockPosition { BlockPosition(rawValue: (self.rawValue + 1) % 4) ?? .position1 }
    }

    /// Represents a coordinate in the Tetris grid.
    struct GridPosition: Hashable {
        var col, row: Int
    }
    
    /// Possible states for the AR game session.
    enum GameState {
        case tracking  // Searching for a flat surface
        case placing   // Surface found, waiting for user to place the board
        case playing   // Game in progress
    }
    
    // MARK: - Game Constants
    
    private let blockHeight: Float = 0.4
    private let colCount = 10
    private let rowCount = 20
    private let minPosX: Float = -2.0  // Leftmost X position in world space
    private let minPosY: Float = 0.4   // Bottom Y position in world space
    private let blockSpawnGridPos = GridPosition(col: 5, row: 22) // Spawn point above the field

    // MARK: - Game State Properties
    
    private var gameState: GameState = .tracking
    /// When locked, the board cannot be scaled or rotated via gestures.
    private var isBoardLocked = false { didSet { buttonLock.setTitle(isBoardLocked ? "Unlock Board" : "Lock Board", for: .normal) } }
    private var initialScale: SCNVector3 = SCNVector3(1, 1, 1)
    private var initialEulerY: Float = 0
    private var lastUpdateTime: TimeInterval = 0
    private var fallAccumulator: TimeInterval = 0 // Tracks time elapsed since last gravity drop
    private var score = 0 { didSet { scoreLabel.text = "Score: \(score)" } }
    private var level = 0
    private var totalLinesCleared = 0
    private var isOver = false
    private var isPaused = false { didSet { buttonPause.setTitle(isPaused ? "Resume" : "Pause", for: .normal) } }
    
    // MARK: - Logical Grid & Active State
    
    /// Map of grid positions to the nodes currently occupying them on the board.
    private var board: [GridPosition: SCNNode] = [:]
    /// Random bag of blocks to ensure a fair distribution (7-bag system).
    private var bag: [BlockType] = []
    private var activeBlockType: BlockType = .orangeRicky
    private var nextBlockType: BlockType!
    private var activeBlockRotation: BlockPosition = .position1
    private var activeBlockGridPos = GridPosition(col: 0, row: 0)
    
    // MARK: - Scene & Rendering Properties
    
    private var gameScene: SCNScene!
    /// Container for the entire Tetris field and placed blocks.
    private let boardNode = SCNNode()
    /// Container for the blocks currently being controlled by the player.
    private let activeBlockNode = SCNNode()
    /// Container for the "Next Block" preview.
    private let nextBlockNode = SCNNode()
    /// Pool of reusable block nodes to avoid frequent allocation.
    private var objectPool: [SCNNode] = []
    private let poolInitialCount = 200
    
    // MARK: - UI Elements
    
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
    
    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "LuckiestGuy-Regular", size: 18)
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Initializing AR..."
        label.numberOfLines = 0
        return label
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
    
    private let buttonLock: UIButton = {
        let btn = UIButton(type: .roundedRect)
        btn.titleLabel?.font = UIFont(name: "LuckiestGuy-Regular", size: 20)
        btn.setTitleColor(.white, for: .normal)
        btn.setTitle("Lock", for: .normal)
        btn.backgroundColor = .systemGreen
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let wallMat = SCNMaterial()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
        setupUI()
        setupMaterials()
        populatePool()
        generateField()
        boardNode.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Setup horizontal plane detection for AR
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        let arView = self.view as! ARSCNView
        arView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let arView = self.view as! ARSCNView
        arView.session.pause()
    }
    
    /// Resets the game state and clears the board.
    private func restart() {
        board.values.forEach { sendToPool(node: $0) }
        activeBlockNode.childNodes.forEach { sendToPool(node: $0) }
        nextBlockNode.childNodes.forEach { sendToPool(node: $0) }
        board.removeAll()
        bag.removeAll()
        score = 0
        level = 0
        totalLinesCleared = 0
        lastUpdateTime = 0
        fallAccumulator = 0
        isOver = false
        isPaused = false
        activeBlockNode.isHidden = false
        nextBlockType = getNextBlockType()
        generateRandomBlock()
    }
    
    // MARK: - ARSCNViewDelegate & Game Loop
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = time
            return
        }
        
        let deltaTime = time - lastUpdateTime
        lastUpdateTime = time
        
        guard gameState == .playing, !isPaused, !isOver else {
            updateInstructions()
            return
        }
        
        // Handle gravity (automatic falling)
        fallAccumulator += deltaTime
        let currentFallSpeed = max(0.1, 1.0 * pow(0.85, Double(level)))
        
        if fallAccumulator >= currentFallSpeed {
            fallAccumulator -= currentFallSpeed
            
            DispatchQueue.main.async {
                // Try to move down
                if self.canMove(to: GridPosition(col: self.activeBlockGridPos.col, row: self.activeBlockGridPos.row - 1), rotation: self.activeBlockRotation) {
                    self.moveActiveBlock(to: GridPosition(col: self.activeBlockGridPos.col, row: self.activeBlockGridPos.row - 1))
                } else {
                    // Cannot move down, so place the block
                    self.placeBlockOnField()
                    self.generateRandomBlock()
                    
                    // Check for Game Over (newly spawned block is blocked)
                    if self.isGameOver() {
                        self.isOver = true
                        self.activeBlockNode.isHidden = true
                        self.showGameOverAlert()
                        playSFX(.gameOver)
                    }
                }
            }
        }
    }

    /// Updates the UI instructions based on the current AR tracking state.
    private func updateInstructions() {
        DispatchQueue.main.async {
            switch self.gameState {
            case .tracking:
                let arView = self.view as! ARSCNView
                // Check if a horizontal plane has been detected
                if let _ = arView.session.currentFrame?.anchors.compactMap({ $0 as? ARPlaneAnchor }).first(where: { $0.alignment == .horizontal }) {
                    self.gameState = .placing
                    self.instructionLabel.text = "Tap to place the board"
                } else {
                    self.instructionLabel.text = "Move camera to find a flat surface"
                }
            case .placing:
                self.instructionLabel.text = "Tap to place the board"
            case .playing:
                self.instructionLabel.text = ""
                self.instructionLabel.isHidden = true
            }
        }
    }

    // MARK: - Core Game Logic
    
    /// Checks if the active block can move to the specified grid position and rotation.
    /// - Parameters:
    ///   - pos: The target anchor grid position.
    ///   - rotation: The target rotation state.
    /// - Returns: True if the movement is valid (no collisions and within bounds).
    private func canMove(to pos: GridPosition, rotation: BlockPosition) -> Bool {
        for offset in activeBlockType.positions(for: rotation) {
            let col = pos.col + offset.col
            let row = pos.row + offset.row
            
            // Boundary checks (Horizontal and bottom) and collision with placed blocks
            if col < 1 || col > colCount || row < 1 || board[GridPosition(col: col, row: row)] != nil {
                return false
            }
        }
        return true
    }

    /// Updates the position and rotation of the active block in the scene.
    /// - Parameters:
    ///   - pos: The target grid position.
    ///   - rotation: Optional new rotation state.
    private func moveActiveBlock(to pos: GridPosition, rotation: BlockPosition? = nil) {
        activeBlockGridPos = pos
        if let rotation = rotation { activeBlockRotation = rotation }
        activeBlockNode.position = gridToWorld(activeBlockGridPos)
        
        let localPositions = activeBlockType.positions(for: activeBlockRotation)
        for (index, node) in activeBlockNode.childNodes.enumerated() {
            node.position = SCNVector3(Float(localPositions[index].col) * blockHeight, Float(localPositions[index].row) * blockHeight, 0)
        }
    }

    /// Returns the next block type from the bag, replenishing it if empty.
    private func getNextBlockType() -> BlockType {
        if bag.isEmpty {
            bag = BlockType.allCases.shuffled()
        }
        return bag.removeFirst()
    }

    /// Spawns a new active block at the top of the grid.
    private func generateRandomBlock() {
        activeBlockType = nextBlockType
        nextBlockType = getNextBlockType()
        
        activeBlockRotation = .position1
        activeBlockGridPos = blockSpawnGridPos
        
        // Clean up current active block visual nodes
        activeBlockNode.childNodes.forEach { sendToPool(node: $0) }
        
        let material = getMaterial(blockType: activeBlockType)
        
        // Create 4 new block segments from the pool
        for _ in 0..<4 {
            let node = getFromPool()
            node.geometry?.materials = [material]
            activeBlockNode.addChildNode(node)
        }
        moveActiveBlock(to: activeBlockGridPos)
        updateNextBlockDisplay()
    }

    /// Updates the 3D preview of the next incoming block.
    private func updateNextBlockDisplay() {
        nextBlockNode.childNodes.forEach { sendToPool(node: $0) }
        let material = getMaterial(blockType: nextBlockType)
        let localPositions = nextBlockType.positions(for: .position1)
        
        for pos in localPositions {
            let node = getFromPool()
            node.geometry?.materials = [material]
            node.position = SCNVector3(Float(pos.col) * blockHeight, Float(pos.row) * blockHeight, 0)
            nextBlockNode.addChildNode(node)
        }
    }

    /// Commits the active block's segments to the board and checks for cleared rows.
    private func placeBlockOnField() {
        let offsets = activeBlockType.positions(for: activeBlockRotation)
        for (index, node) in activeBlockNode.childNodes.enumerated() {
            let pos = GridPosition(col: activeBlockGridPos.col + offsets[index].col, row: activeBlockGridPos.row + offsets[index].row)
            
            // Convert coordinate space to the board and re-parent
            node.transform = node.convertTransform(SCNMatrix4Identity, to: boardNode)
            node.removeFromParentNode()
            boardNode.addChildNode(node)
            board[pos] = node
        }
        checkForClearance()
    }

    /// Identifies full rows, removes them, and shifts remaining blocks down.
    private func checkForClearance() {
        var rowsToClear: [Int] = []
        for row in 1...rowCount + 4 {
            let isFull = (1...colCount).allSatisfy { board[GridPosition(col: $0, row: row)] != nil }
            if isFull { rowsToClear.append(row) }
        }
        
        if rowsToClear.isEmpty { return }
        
        // Clear from top to bottom to maintain grid integrity during shift
        for row in rowsToClear.sorted(by: >) {
            (1...colCount).forEach { col in
                if let node = board.removeValue(forKey: GridPosition(col: col, row: row)) {
                    sendToPool(node: node)
                }
            }
            // Shift down everything above the cleared row
            for r in (row + 1)...(rowCount + 4) {
                for col in 1...colCount {
                    if let node = board.removeValue(forKey: GridPosition(col: col, row: r)) {
                        let newPos = GridPosition(col: col, row: r - 1)
                        board[newPos] = node
                        node.position.y -= blockHeight
                    }
                }
            }
        }
        
        calculateScore(numOfRowsCleared: rowsToClear.count)
        calculateLevel()
        playSFX(.clearance)
    }

    /// Checks if the current state is a Game Over.
    private func isGameOver() -> Bool {
        return !canMove(to: activeBlockGridPos, rotation: activeBlockRotation)
    }

    /// Converts a grid coordinate to a 3D world space coordinate relative to the board.
    private func gridToWorld(_ pos: GridPosition) -> SCNVector3 {
        return SCNVector3(Float(pos.col - 1) * blockHeight + minPosX, Float(pos.row) * blockHeight, 0)
    }

    
    // MARK: - Interaction Handlers
    
    /// Handles tapping for board placement and block rotation.
    @objc func handleTap(_ gestureRecognize: UITapGestureRecognizer) {
        if gameState == .placing {
            let arView = self.view as! ARSCNView
            let location = gestureRecognize.location(in: arView)
            
            // Raycast to find a plane for board placement
            let raycastQuery = arView.raycastQuery(from: location, allowing: .estimatedPlane, alignment: .horizontal)
            if let query = raycastQuery, let result = arView.session.raycast(query).first {
                boardNode.simdTransform = result.worldTransform
                boardNode.scale = SCNVector3(0.3, 0.3, 0.3)
                boardNode.isHidden = false
                gameState = .playing
                instructionLabel.isHidden = true
                restart()
            }
            return
        }
        
        guard !isPaused, !isOver else { return }
        
        // Rotate block on tap during gameplay
        if gestureRecognize.state == .ended {
            let nextRotation = activeBlockRotation.next
            if canMove(to: activeBlockGridPos, rotation: nextRotation) {
                moveActiveBlock(to: activeBlockGridPos, rotation: nextRotation)
            }
        }
    }

    /// Handles pinching to scale the game board.
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard !isBoardLocked, gameState == .playing else { return }
        if gesture.state == .began {
            initialScale = boardNode.scale
        } else if gesture.state == .changed {
            let scale = Float(gesture.scale)
            boardNode.scale = SCNVector3(initialScale.x * scale, initialScale.y * scale, initialScale.z * scale)
        }
    }

    /// Handles panning to rotate the game board around the Y-axis.
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard !isBoardLocked, gameState == .playing else { return }
        let translation = gesture.translation(in: gesture.view)
        if gesture.state == .began {
            initialEulerY = boardNode.eulerAngles.y
        } else if gesture.state == .changed {
            boardNode.eulerAngles.y = initialEulerY + Float(translation.x) * 0.01
        }
    }

    @objc private func tapLock() {
        isBoardLocked.toggle()
    }

    @objc private func tapPause() {
        isPaused.toggle()
        if isPaused {
            bgmQueuePlayer.pause()
        } else {
            lastUpdateTime = 0
            bgmQueuePlayer.play()
        }
        [buttonLeft, buttonDown, buttonRight].forEach { $0.isEnabled = !isPaused }
    }
    
    @objc private func tapButtonLeft() {
        let nextPos = GridPosition(col: activeBlockGridPos.col - 1, row: activeBlockGridPos.row)
        if canMove(to: nextPos, rotation: activeBlockRotation) {
            moveActiveBlock(to: nextPos)
        }
    }
    
    @objc private func tapButtonRight() {
        let nextPos = GridPosition(col: activeBlockGridPos.col + 1, row: activeBlockGridPos.row)
        if canMove(to: nextPos, rotation: activeBlockRotation) {
            moveActiveBlock(to: nextPos)
        }
    }
    
    /// Hard drop: moves the block to the lowest possible position immediately.
    @objc private func tapButtonDown() {
        guard !isOver, !isPaused else { return }
        var nextPos = activeBlockGridPos
        while canMove(to: GridPosition(col: nextPos.col, row: nextPos.row - 1), rotation: activeBlockRotation) {
            nextPos.row -= 1
            score += 1 // Bonus points for hard drop
        }
        moveActiveBlock(to: nextPos)
    }

    #if DEBUG
    /// Keyboard controls for testing in the simulator.
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let key = presses.first?.key else { return }
        switch key.keyCode {
        case .keyboardUpArrow:
            let next = activeBlockRotation.next
            if canMove(to: activeBlockGridPos, rotation: next) { moveActiveBlock(to: activeBlockGridPos, rotation: next) }
        case .keyboardDownArrow: tapButtonDown()
        case .keyboardLeftArrow: tapButtonLeft()
        case .keyboardRightArrow: tapButtonRight()
        default: break
        }
    }
    #endif
}

// MARK: - Setup Extensions

private extension GameViewController {
    
    /// Configures the SceneKit environment, lighting, and initial node hierarchy.
    func setupScene() {
        gameScene = SCNScene(named: "art.scnassets/tetris-scene.scn")!
        
        // Directional light for shadows
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
        
        // Ambient light for general visibility
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor(white: 0.4, alpha: 1.0)
        gameScene.rootNode.addChildNode(ambientLightNode)
        
        let arView = self.view as! ARSCNView
        arView.scene = gameScene
        arView.delegate = self
        arView.allowsCameraControl = false
        arView.backgroundColor = .black
        arView.isPlaying = true
        
        // Hierarchical setup
        gameScene.rootNode.addChildNode(boardNode)
        boardNode.addChildNode(activeBlockNode)
        boardNode.addChildNode(nextBlockNode)
        
        // Position the "Next Block" preview
        nextBlockNode.position = SCNVector3(3.0, 6.0, 0)
        nextBlockNode.scale = SCNVector3(1, 1, 1)
        
        // Add "NEXT" 3D Text label
        let textGeometry = SCNText(string: "NEXT", extrusionDepth: 0.1)
        textGeometry.font = UIFont(name: "LuckiestGuy-Regular", size: 1.0)
        textGeometry.firstMaterial?.diffuse.contents = UIColor.white
        let textNode = SCNNode(geometry: textGeometry)
        textNode.position = SCNVector3(2.5, 6.5, 0)
        textNode.scale = SCNVector3(0.5, 0.5, 0.5)
        boardNode.addChildNode(textNode)
        
        // Add AR interaction gestures
        arView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(_:))))
        arView.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:))))
        arView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))
    }

    /// Configures the UI layout and constraints.
    func setupUI() {
        let safeArea = view.safeAreaLayoutGuide
        let stack = UIStackView(arrangedSubviews: [buttonLeft, buttonDown, buttonRight])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.distribution = .fillEqually
        view.addSubview(stack)
        view.addSubview(buttonPause)
        view.addSubview(buttonLock)
        view.addSubview(scoreLabel)
        view.addSubview(instructionLabel)
        
        NSLayoutConstraint.activate([
            buttonPause.centerYAnchor.constraint(equalTo: scoreLabel.centerYAnchor, constant: -8),
            buttonPause.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            buttonPause.widthAnchor.constraint(equalToConstant: 100),
            buttonPause.heightAnchor.constraint(equalToConstant: 36),
            
            buttonLock.topAnchor.constraint(equalTo: buttonPause.bottomAnchor, constant: 12),
            buttonLock.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            buttonLock.widthAnchor.constraint(equalToConstant: 100),
            buttonLock.heightAnchor.constraint(equalToConstant: 36),
            
            scoreLabel.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 0),
            scoreLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scoreLabel.heightAnchor.constraint(equalToConstant: 60),
            
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            instructionLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            instructionLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
            
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: 0),
            stack.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        buttonPause.layer.cornerRadius = 12
        buttonPause.addTarget(self, action: #selector(tapPause), for: .touchUpInside)
        buttonLock.layer.cornerRadius = 12
        buttonLock.addTarget(self, action: #selector(tapLock), for: .touchUpInside)
        buttonLeft.addTarget(self, action: #selector(tapButtonLeft), for: .touchUpInside)
        buttonRight.addTarget(self, action: #selector(tapButtonRight), for: .touchUpInside)
        buttonDown.addTarget(self, action: #selector(tapButtonDown), for: .touchUpInside)
    }

    /// Pre-configures materials for game objects.
    func setupMaterials() {
        wallMat.lightingModel = .physicallyBased
        wallMat.diffuse.contents = UIColor(white: 0.2, alpha: 1.0)
        wallMat.metalness.contents = 0.8
        wallMat.roughness.contents = 0.2
        wallMat.isDoubleSided = true
    }

    /// Fetches the appropriate material/color for a given block type.
    func getMaterial(blockType: BlockType) -> SCNMaterial {
        let blockScene = SCNScene(named: "art.scnassets/menu-scene.scn")!
        let names: [BlockType: (String, String)] = [
            .blueRicky: ("J", "Blue"), .smashboy: ("O", "Yellow"), .teewee: ("T", "Purple"),
            .hero: ("I", "Cyan"), .rhodeIslandZ: ("S", "Green"), .clevelandZ: ("Z", "Red"), .orangeRicky: ("L", "Orange")
        ]
        let info = names[blockType]!
        let material = blockScene.rootNode.childNode(withName: info.0, recursively: false)?.geometry?.material(named: info.1) ?? SCNMaterial()
        
        material.lightingModel = .physicallyBased
        material.metalness.contents = 0.1
        material.roughness.contents = 0.3
        
        return material
    }

    // MARK: - Object Pooling
    
    /// Pre-allocates block nodes to the pool.
    func populatePool() {
        for _ in 0..<poolInitialCount { sendToPool(node: getBlock()) }
    }

    /// Returns a node to the pool for reuse.
    func sendToPool(node: SCNNode) {
        node.removeFromParentNode()
        node.isHidden = true
        objectPool.append(node)
    }

    /// Retrieves a node from the pool or creates a new one if empty.
    func getFromPool() -> SCNNode {
        let node = objectPool.popLast() ?? getBlock()
        node.isHidden = false
        return node
    }

    /// Loads a single block segment from the DAE asset.
    func getBlock() -> SCNNode {
        let scene = SCNScene(named: "art.scnassets/tetris-block.dae")!
        return scene.rootNode.childNode(withName: "Cube", recursively: false)!.clone()
    }

    // MARK: - Scene Generation
    
    /// Generates the static parts of the game field (frame and shadows).
    func generateField() {
        let scene = SCNScene(named: "art.scnassets/tetris-field.dae")!
        let field = scene.rootNode.childNode(withName: "Field", recursively: false)!
        field.position = SCNVector3(-0.2, 0, 0)
        field.childNodes.first?.geometry?.materials = [wallMat]
        boardNode.addChildNode(field)
        
        // Add a soft blurred circle shadow below the field for better depth perception in AR
        let shadowSize: CGFloat = 4.0
        let shadowPlane = SCNPlane(width: shadowSize, height: shadowSize)
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 128, height: 128))
        let blurredImage = renderer.image { ctx in
            let center = CGPoint(x: 64, y: 64)
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [UIColor(white: 0, alpha: 0.8).cgColor, UIColor(white: 0, alpha: 0.0).cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0]) {
                ctx.cgContext.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: 64, options: [])
            }
        }
        
        let shadowMaterial = SCNMaterial()
        shadowMaterial.diffuse.contents = blurredImage
        shadowMaterial.lightingModel = .constant
        shadowMaterial.writesToDepthBuffer = false
        shadowMaterial.isDoubleSided = true
        shadowPlane.materials = [shadowMaterial]
        
        let shadowNode = SCNNode(geometry: shadowPlane)
        shadowNode.eulerAngles.x = -.pi / 2
        shadowNode.position = SCNVector3(-0.2, 0.01, -0.2)
        shadowNode.castsShadow = false
        boardNode.addChildNode(shadowNode)
    }
    
    // MARK: - Progression & Alerts
    
    /// Updates the player's score based on the number of rows cleared.
    func calculateScore(numOfRowsCleared: Int) {
        let points = [0, 40, 100, 300, 1200]
        score += points[min(numOfRowsCleared, 4)] * (level + 1)
        totalLinesCleared += numOfRowsCleared
    }

    /// Increases the game level every 10 lines cleared.
    func calculateLevel() {
        level = totalLinesCleared / 10
    }

    /// Displays the game over message and options to restart or quit.
    func showGameOverAlert() {
        let alert = UIAlertController(title: "Game Over", message: "You got \(score) points!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Restart", style: .default) { _ in 
            self.gameState = .placing
            self.boardNode.isHidden = true
            self.instructionLabel.isHidden = false
            self.restart() 
        })
        alert.addAction(UIAlertAction(title: "Back to Menu", style: .destructive) { _ in
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyBoard.instantiateViewController(withIdentifier: "MenuViewController")
            (UIApplication.shared.delegate as? AppDelegate)?.window?.rootViewController = vc
        })
        present(alert, animated: true)
    }
}
