import SwiftUI
import SpriteKit

@main
struct SuperfamilieApp: App {
    var body: some Scene {
        WindowGroup {
            SuperfamilieView()
        }
    }
}

enum Hero: String, CaseIterable {
    case achim = "Achim"
    case angie = "Angie"
    case leni = "Leni"
    case connor = "Connor"
}

struct SuperfamilieView: View {
    @State private var hero: Hero = .achim
    @State private var showMenu = true

    var body: some View {
        ZStack {
            PixelGameView(hero: hero, showMenu: $showMenu)
                .ignoresSafeArea()

            if showMenu {
                MenuView(hero: $hero, showMenu: $showMenu)
            }
        }
    }
}

struct MenuView: View {
    @Binding var hero: Hero
    @Binding var showMenu: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.48, blue: 0.78),
                    Color(red: 0.38, green: 0.72, blue: 0.92)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("SUPERFAMILIE")
                    .font(.system(size: 42, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)

                Text("STADT-ABENTEUER")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))

                Text("FIGUR AUSWÄHLEN")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)

                HStack(spacing: 14) {
                    ForEach(Hero.allCases, id: \.self) { item in
                        Button {
                            hero = item
                        } label: {
                            VStack(spacing: 8) {
                                PixelHeroPreview(hero: item, selected: hero == item)
                                    .frame(width: 100, height: 130)

                                Text(item.rawValue)
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.white)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button {
                    showMenu = false
                } label: {
                    Text("SPIEL STARTEN")
                        .font(.system(size: 22, weight: .black, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 38)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.12, green: 0.32, blue: 0.46))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.white, lineWidth: 2)
                        )
                }
            }
            .padding(24)
        }
    }
}

struct PixelHeroPreview: View {
    let hero: Hero
    let selected: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.20))

            PixelHeroView(hero: hero)
                .scaleEffect(1.35)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    selected ? Color.yellow : Color.white.opacity(0.3),
                    lineWidth: selected ? 4 : 1
                )
        )
    }
}

struct PixelHeroView: View {
    let hero: Hero

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                let skin: Color = .orange
                let hair: Color = {
                    switch hero {
                    case .achim:
                        return .gray
                    case .angie:
                        return Color(red: 0.65, green: 0.05, blue: 0.35)
                    case .leni:
                        return Color(red: 0.72, green: 0.12, blue: 0.38)
                    case .connor:
                        return Color(red: 0.55, green: 0.35, blue: 0.18)
                    }
                }()

                Rectangle()
                    .fill(hair)
                    .frame(width: w * 0.42, height: h * 0.22)
                    .position(x: w * 0.50, y: h * 0.20)

                Rectangle()
                    .fill(skin)
                    .frame(width: w * 0.30, height: h * 0.25)
                    .position(x: w * 0.50, y: h * 0.34)

                Rectangle()
                    .fill(.black)
                    .frame(width: w * 0.38, height: h * 0.30)
                    .position(x: w * 0.50, y: h * 0.62)

                Rectangle()
                    .fill(.blue)
                    .frame(width: w * 0.14, height: h * 0.25)
                    .position(x: w * 0.40, y: h * 0.90)

                Rectangle()
                    .fill(.blue)
                    .frame(width: w * 0.14, height: h * 0.25)
                    .position(x: w * 0.60, y: h * 0.90)

                Rectangle()
                    .fill(.white)
                    .frame(width: w * 0.17, height: h * 0.08)
                    .position(x: w * 0.40, y: h * 0.99)

                Rectangle()
                    .fill(.white)
                    .frame(width: w * 0.17, height: h * 0.08)
                    .position(x: w * 0.60, y: h * 0.99)
            }
        }
    }
}

struct PixelGameView: UIViewRepresentable {
    let hero: Hero
    @Binding var showMenu: Bool

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.ignoresSiblingOrder = true
        view.isMultipleTouchEnabled = true

        let scene = GameScene(size: view.bounds.size)
        scene.scaleMode = .resizeFill
        scene.selectedHero = hero
        scene.menuBinding = Binding(
            get: { showMenu },
            set: { showMenu = $0 }
        )

        view.presentScene(scene)
        return view
    }

    func updateUIView(_ view: SKView, context: Context) {
        guard let scene = view.scene as? GameScene else { return }
        scene.selectedHero = hero
        scene.menuBinding = Binding(
            get: { showMenu },
            set: { showMenu = $0 }
        )
    }
}

final class GameScene: SKScene {

    var selectedHero: Hero = .achim
    var menuBinding: Binding<Bool>?

    private var player = SKNode()
    private var nala = SKNode()

    private var cameraNode = SKCameraNode()

    private var velocity = CGVector(dx: 0, dy: 0)

    private var leftTouches = Set<ObjectIdentifier>()
    private var rightTouches = Set<ObjectIdentifier>()

    private var onGround = false

    private let gravity: CGFloat = -1250
    private let moveSpeed: CGFloat = 300
    private let jumpPower: CGFloat = 900

    private var platforms: [CGRect] = []

    private var ballNodes: [SKShapeNode] = []

    private var nalaUnlocked = false

    private var score = 18
    private var lives = 3

    private var scoreLabel = SKLabelNode()
    private var livesLabel = SKLabelNode()

    private var world: SKNode?

    override func didMove(to view: SKView) {
        backgroundColor = ColorBridge.sky

        view.isMultipleTouchEnabled = true

        setupCamera()
        buildWorld()
        buildPlayer()
        buildHUD()
        buildControls()
    }

    private func setupCamera() {
        camera = cameraNode
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(cameraNode)
    }

    private func buildWorld() {
        let root = SKNode()
        root.name = "world"
        addChild(root)
        world = root

        buildSkyline(root)
        buildGround(root)
        buildPlatforms(root)
        buildCoins(root)
        buildEnemies(root)
        buildNalaHut(root)
        buildHome(root)
    }

    private func buildSkyline(_ parent: SKNode) {

        for i in 0..<18 {
            let x = CGFloat(i) * 360

            let height: CGFloat =
                220 + CGFloat((i * 53) % 180)

            let building = SKShapeNode(
                rectOf: CGSize(
                    width: 270,
                    height: height
                )
            )

            let colors: [SKColor] = [
                .systemBlue,
                .systemOrange,
                .systemPink,
                .systemTeal,
                .systemIndigo
            ]

            building.fillColor = colors[i % colors.count]
            building.strokeColor = .clear

            building.position = CGPoint(
                x: x,
                y: 230 + height / 2
            )

            parent.addChild(building)

            for row in 0..<4 {
                for col in 0..<3 {
                    let window = SKShapeNode(
                        rectOf: CGSize(
                            width: 28,
                            height: 40
                        )
                    )

                    window.fillColor = .cyan
                    window.strokeColor = .white
                    window.lineWidth = 3

                    window.position = CGPoint(
                        x: x - 80 + CGFloat(col) * 80,
                        y: 190 + CGFloat(row) * 75
                    )

                    parent.addChild(window)
                }
            }

            let roof = SKShapeNode(
                path: roofPath(width: 310, height: 100)
            )

            roof.fillColor = .systemRed
            roof.strokeColor = .clear

            roof.position = CGPoint(
                x: x,
                y: 230 + height
            )

            parent.addChild(roof)
        }

        for i in 0..<30 {
            let x = CGFloat(i) * 230 + 80

            let tree = SKShapeNode(
                circleOfRadius: 52
            )

            tree.fillColor = .systemGreen
            tree.strokeColor = .clear

            tree.position = CGPoint(
                x: x,
                y: 270
            )

            parent.addChild(tree)

            let trunk = SKShapeNode(
                rectOf: CGSize(
                    width: 26,
                    height: 90
                )
            )

            trunk.fillColor = .brown
            trunk.strokeColor = .clear

            trunk.position = CGPoint(
                x: x,
                y: 220
            )

            parent.addChild(trunk)
        }

        for i in 0..<15 {
            let x = CGFloat(i) * 430 + 180

            let lamp = SKShapeNode(
                rectOf: CGSize(
                    width: 9,
                    height: 140
                )
            )

            lamp.fillColor = .black
            lamp.strokeColor = .clear

            lamp.position = CGPoint(
                x: x,
                y: 210
            )

            parent.addChild(lamp)

            let light = SKShapeNode(
                circleOfRadius: 13
            )

            light.fillColor = .yellow
            light.strokeColor = .white
            light.lineWidth = 2

            light.position = CGPoint(
                x: x,
                y: 285
            )

            parent.addChild(light)
        }
    }

    private func buildGround(_ parent: SKNode) {

        let grass = SKShapeNode(
            rectOf: CGSize(
                width: 6200,
                height: 34
            )
        )

        grass.fillColor = .systemGreen
        grass.strokeColor = .clear

        grass.position = CGPoint(
            x: 3100,
            y: 165
        )

        parent.addChild(grass)

        let road = SKShapeNode(
            rectOf: CGSize(
                width: 6200,
                height: 260
            )
        )

        road.fillColor = SKColor(
            red: 0.08,
            green: 0.10,
            blue: 0.13,
            alpha: 1
        )

        road.strokeColor = .clear

        road.position = CGPoint(
            x: 3100,
            y: 35
        )

        parent.addChild(road)

        platforms.append(
            CGRect(
                x: -100,
                y: 165,
                width: 6400,
                height: 35
            )
        )
    }

    private func buildPlatforms(_ parent: SKNode) {

        let data: [(CGFloat, CGFloat, CGFloat)] = [
            (650, 400, 260),
            (1280, 470, 270),
            (1900, 390, 260),
            (2500, 500, 300),
            (3250, 430, 270),
            (4000, 520, 300),
            (4750, 420, 270)
        ]

        for item in data {

            let x = item.0
            let y = item.1
            let width = item.2

            let platform = SKShapeNode(
                rectOf: CGSize(
                    width: width,
                    height: 32
                )
            )

            platform.fillColor = SKColor(
                red: 0.35,
                green: 0.18,
                blue: 0.08,
                alpha: 1
            )

            platform.strokeColor = .systemGreen
            platform.lineWidth = 7

            platform.position = CGPoint(
                x: x,
                y: y
            )

            parent.addChild(platform)

            platforms.append(
                CGRect(
                    x: x - width / 2,
                    y: y - 16,
                    width: width,
                    height: 32
                )
            )
        }
    }

    private func buildCoins(_ parent: SKNode) {

        for x in stride(
            from: CGFloat(430),
            through: CGFloat(5400),
            by: CGFloat(260)
        ) {

            let coin = SKShapeNode(
                circleOfRadius: 16
            )

            coin.fillColor = .yellow
            coin.strokeColor = .orange
            coin.lineWidth = 4

            coin.position = CGPoint(
                x: x,
                y: 260
            )

            coin.name = "coin"

            parent.addChild(coin)
        }

        addCoinLine(parent, x: 760, y: 360, count: 3)
        addCoinLine(parent, x: 1950, y: 470, count: 3)
        addCoinLine(parent, x: 4250, y: 375, count: 3)
    }

    private func addCoinLine(
        _ parent: SKNode,
        x: CGFloat,
        y: CGFloat,
        count: Int
    ) {

        for i in 0..<count {

            let coin = SKShapeNode(
                circleOfRadius: 16
            )

            coin.fillColor = .yellow
            coin.strokeColor = .orange
            coin.lineWidth = 4

            coin.position = CGPoint(
                x: x + CGFloat(i) * 45,
                y: y
            )

            coin.name = "coin"

            parent.addChild(coin)
        }
    }

    private func buildEnemies(_ parent: SKNode) {

        addTennisBall(parent, x: 1220, y: 208)
        addTennisBall(parent, x: 2180, y: 208)
        addTennisBall(parent, x: 3150, y: 208)
        addTennisBall(parent, x: 4450, y: 208)
    }

    private func addTennisBall(
        _ parent: SKNode,
        x: CGFloat,
        y: CGFloat
    ) {

        let ball = SKShapeNode(
            circleOfRadius: 25
        )

        ball.fillColor = .white
        ball.strokeColor = .systemGreen
        ball.lineWidth = 4

        ball.position = CGPoint(
            x: x,
            y: y
        )

        ball.name = "tennisBall"

        parent.addChild(ball)
        ballNodes.append(ball)

        let seam = SKShapeNode()

        let path = CGMutablePath()

        path.move(
            to: CGPoint(x: -12, y: -17)
        )

        path.addCurve(
            to: CGPoint(x: 12, y: 17),
            control1: CGPoint(x: -25, y: -5),
            control2: CGPoint(x: 25, y: 5)
        )

        seam.path = path
        seam.strokeColor = .systemGreen
        seam.lineWidth = 3

        ball.addChild(seam)
    }

    private func buildNalaHut(_ parent: SKNode) {

        let hut = SKShapeNode(
            rectOf: CGSize(
                width: 260,
                height: 150
            )
        )

        hut.fillColor = .systemOrange
        hut.strokeColor = .black
        hut.lineWidth = 5

        hut.position = CGPoint(
            x: 2500,
            y: 240
        )

        hut.name = "nalaHut"

        parent.addChild(hut)

        let sign = SKLabelNode(
            fontNamed: "Menlo-Bold"
        )

        sign.text = "NALA"
        sign.fontSize = 22
        sign.fontColor = .white

        sign.position = CGPoint(
            x: 0,
            y: -5
        )

        hut.addChild(sign)
    }

    private func buildHome(_ parent: SKNode) {

        let house = SKShapeNode(
            rectOf: CGSize(
                width: 300,
                height: 190
            )
        )

        house.fillColor = .systemOrange
        house.strokeColor = .black
        house.lineWidth = 5

        house.position = CGPoint(
            x: 5700,
            y: 260
        )

        parent.addChild(house)

        let roof = SKShapeNode(
            path: roofPath(
                width: 360,
                height: 130
            )
        )

        roof.fillColor = .systemRed
        roof.strokeColor = .black
        roof.lineWidth = 5

        roof.position = CGPoint(
            x: 5700,
            y: 355
        )

        parent.addChild(roof)

        let label = SKLabelNode(
            fontNamed: "Menlo-Bold"
        )

        label.text = "ZUHAUSE"
        label.fontSize = 20
        label.fontColor = .white

        label.position = CGPoint(
            x: 5700,
            y: 330
        )

        parent.addChild(label)
    }

    private func buildPlayer() {

        player.removeFromParentChildren()

        player = SKNode()
        player.position = CGPoint(
            x: 160,
            y: 268
        )

        player.name = "player"

        addChild(player)

        drawHero()
    }

    private func drawHero() {

        player.removeAllChildren()

        let body = SKShapeNode(
            rectOf: CGSize(
                width: 46,
                height: 72
            )
        )

        body.fillColor = .black
        body.strokeColor = .clear
        body.position = CGPoint(x: 0, y: 0)

        player.addChild(body)

        let head = SKShapeNode(
            rectOf: CGSize(
                width: 40,
                height: 42
            )
        )

        head.fillColor = .orange
        head.strokeColor = .clear
        head.position = CGPoint(
            x: 0,
            y: 54
        )

        player.addChild(head)

        let hair = SKShapeNode(
            rectOf: CGSize(
                width: 44,
                height: 16
            )
        )

        switch selectedHero {
        case .achim:
            hair.fillColor = .gray
        case .angie:
            hair.fillColor = .systemPink
        case .leni:
            hair.fillColor = .systemPurple
        case .connor:
            hair.fillColor = .brown
        }

        hair.strokeColor = .clear
        hair.position = CGPoint(
            x: 0,
            y: 78
        )

        player.addChild(hair)

        let leg1 = SKShapeNode(
            rectOf: CGSize(
                width: 15,
                height: 45
            )
        )

        leg1.fillColor = .blue
        leg1.strokeColor = .clear
        leg1.position = CGPoint(
            x: -12,
            y: -57
        )

        player.addChild(leg1)

        let leg2 = SKShapeNode(
            rectOf: CGSize(
                width: 15,
                height: 45
            )
        )

        leg2.fillColor = .blue
        leg2.strokeColor = .clear
        leg2.position = CGPoint(
            x: 12,
            y: -57
        )

        player.addChild(leg2)

        let shoe1 = SKShapeNode(
            rectOf: CGSize(
                width: 24,
                height: 9
            )
        )

        shoe1.fillColor = .white
        shoe1.strokeColor = .clear
        shoe1.position = CGPoint(
            x: -13,
            y: -80
        )

        player.addChild(shoe1)

        let shoe2 = SKShapeNode(
            rectOf: CGSize(
                width: 24,
                height: 9
            )
        )

        shoe2.fillColor = .white
        shoe2.strokeColor = .clear
        shoe2.position = CGPoint(
            x: 13,
            y: -80
        )

        player.addChild(shoe2)
    }

    private func buildHUD() {

        scoreLabel = SKLabelNode(
            fontNamed: "Menlo-Bold"
        )

        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .yellow
        scoreLabel.horizontalAlignmentMode = .left

        scoreLabel.position = CGPoint(
            x: 120,
            y: size.height - 65
        )

        scoreLabel.zPosition = 1000

        cameraNode.addChild(scoreLabel)

        livesLabel = SKLabelNode(
            fontNamed: "Menlo-Bold"
        )

        livesLabel.fontSize = 24
        livesLabel.fontColor = .white
        livesLabel.horizontalAlignmentMode = .left

        livesLabel.position = CGPoint(
            x: 120,
            y: size.height - 100
        )

        livesLabel.zPosition = 1000

        cameraNode.addChild(livesLabel)

        updateHUD()
    }

    private func updateHUD() {

        scoreLabel.text = "🪙 \(score)"
        livesLabel.text = "❤️ \(lives)"
    }

    private func buildControls() {

        let left = SKShapeNode(
            circleOfRadius: 80
        )

        left.fillColor = SKColor(
            red: 0.02,
            green: 0.10,
            blue: 0.18,
            alpha: 0.95
        )

        left.strokeColor = .white
        left.lineWidth = 3

        left.position = CGPoint(
            x: 120,
            y: 105
        )

        left.name = "left"
        left.zPosition = 2000

        cameraNode.addChild(left)

        let leftLabel = SKLabelNode(
            text: "◀"
        )

        leftLabel.fontSize = 48
        leftLabel.fontColor = .white
        leftLabel.verticalAlignmentMode = .center

        left.addChild(leftLabel)

        let right = SKShapeNode(
            circleOfRadius: 80
        )

        right.fillColor = left.fillColor
        right.strokeColor = .white
        right.lineWidth = 3

        right.position = CGPoint(
            x: 315,
            y: 105
        )

        right.name = "right"
        right.zPosition = 2000

        cameraNode.addChild(right)

        let rightLabel = SKLabelNode(
            text: "▶"
        )

        rightLabel.fontSize = 48
        rightLabel.fontColor = .white
        rightLabel.verticalAlignmentMode = .center

        right.addChild(rightLabel)

        let jump = SKShapeNode(
            circleOfRadius: 80
        )

        jump.fillColor = left.fillColor
        jump.strokeColor = .white
        jump.lineWidth = 3

        jump.position = CGPoint(
            x: size.width - 140,
            y: 105
        )

        jump.name = "jump"
        jump.zPosition = 2000

        cameraNode.addChild(jump)

        let jumpLabel = SKLabelNode(
            text: "▲"
        )

        jumpLabel.fontSize = 48
        jumpLabel.fontColor = .white
        jumpLabel.verticalAlignmentMode = .center

        jump.addChild(jumpLabel)

        let menu = SKShapeNode(
            roundedRectOf: CGSize(
                width: 100,
                height: 50
            ),
            cornerRadius: 20
        )

        menu.fillColor = SKColor(
            red: 0.02,
            green: 0.10,
            blue: 0.18,
            alpha: 0.85
        )

        menu.strokeColor = .white
        menu.lineWidth = 2

        menu.position = CGPoint(
            x: 70,
            y: size.height - 45
        )

        menu.name = "menu"
        menu.zPosition = 2000

        cameraNode.addChild(menu)

        let menuLabel = SKLabelNode(
            text: "MENÜ"
        )

        menuLabel.fontSize = 18
        menuLabel.fontColor = .white
        menuLabel.verticalAlignmentMode = .center

        menu.addChild(menuLabel)
    }

    override func touchesBegan(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {

        for touch in touches {

            let point = touch.location(in: cameraNode)
            let id = ObjectIdentifier(touch)

            if let node = cameraNode.atPoint(point).name {

                switch node {

                case "left":
                    leftTouches.insert(id)

                case "right":
                    rightTouches.insert(id)

                case "jump":

                    if onGround {
                        velocity.dy = jumpPower
                        onGround = false
                    }

                case "menu":
                    menuBinding?.wrappedValue = true

                default:
                    break
                }
            }
        }
    }

    override func touchesEnded(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {

        for touch in touches {

            let id = ObjectIdentifier(touch)

            leftTouches.remove(id)
            rightTouches.remove(id)
        }
    }

    override func touchesCancelled(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {

        for touch in touches {

            let id = ObjectIdentifier(touch)

            leftTouches.remove(id)
            rightTouches.remove(id)
        }
    }

    override func update(_ currentTime: TimeInterval) {

        let dt: CGFloat = 1.0 / 60.0

        var horizontal: CGFloat = 0

        if !leftTouches.isEmpty {
            horizontal -= 1
        }

        if !rightTouches.isEmpty {
            horizontal += 1
        }

        velocity.dx = horizontal * moveSpeed

        velocity.dy += gravity * dt

        let oldY = player.position.y

        player.position.x += velocity.dx * dt
        player.position.y += velocity.dy * dt

        handlePlatformCollision(
            oldY: oldY
        )

        collectCoins()
        updateTennisBalls(dt: dt)
        updateNala()

        cameraFollow()

        if player.position.y < -100 {
            respawn()
        }

        if player.position.x > 5650 {
            win()
        }

        updateHUD()
    }

    private func handlePlatformCollision(
        oldY: CGFloat
    ) {

        onGround = false

        let bottom = player.position.y - 85
        let oldBottom = oldY - 85

        for rect in platforms {

            let playerLeft = player.position.x - 20
            let playerRight = player.position.x + 20

            let overlapsX =
                playerRight > rect.minX &&
                playerLeft < rect.maxX

            let crossedTop =
                oldBottom >= rect.maxY &&
                bottom <= rect.maxY

            if overlapsX && crossedTop && velocity.dy <= 0 {

                player.position.y =
                    rect.maxY + 85

                velocity.dy = 0
                onGround = true

                break
            }
        }
    }

    private func collectCoins() {

        guard let world else { return }

        for node in world.children {

            guard node.name == "coin" else {
                continue
            }

            let dx = node.position.x - player.position.x
            let dy = node.position.y - player.position.y

            if abs(dx) < 45 && abs(dy) < 65 {

                node.removeFromParent()
                score += 1
            }
        }
    }

    private func updateTennisBalls(
        dt: CGFloat
    ) {

        guard let world else { return }

        for ball in ballNodes {

            guard ball.parent != nil else {
                continue
            }

            ball.position.x +=
                sin(CGFloat(NSDate().timeIntervalSince1970) * 2.0)
                * 0.6

            let dx = ball.position.x - player.position.x
            let dy = ball.position.y - player.position.y

            if abs(dx) < 48 && abs(dy) < 65 {

                if velocity.dy < 0 && player.position.y > ball.position.y {

                    ball.removeFromParent()
                    score += 5
                    velocity.dy = jumpPower * 0.55

                } else if abs(dx) < 40 {

                    loseLife()
                }
            }
        }

        ballNodes.removeAll {
            $0.parent == nil
        }
    }

    private func updateNala() {

        guard let world else { return }

        if !nalaUnlocked {

            if player.position.x > 2600 {

                nalaUnlocked = true
                createNala()
            }

            return
        }

        nala.position.x +=
            (player.position.x - 110 - nala.position.x) * 0.08

        nala.position.y = 229

        for ball in ballNodes {

            guard ball.parent != nil else {
                continue
            }

            let dx = ball.position.x - nala.position.x

            if abs(dx) < 260 {

                ball.removeFromParent()

                score += 5
            }
        }

        ballNodes.removeAll {
            $0.parent == nil
        }
    }

    private func createNala() {

        nala.removeFromParent()
        nala = SKNode()

        nala.position = CGPoint(
            x: player.position.x - 120,
            y: 229
        )

        nala.zPosition = 100

        addChild(nala)

        let body = SKShapeNode(
            rectOf: CGSize(
                width: 72,
                height: 42
            )
        )

        body.fillColor = .brown
        body.strokeColor = .black
        body.lineWidth = 2

        nala.addChild(body)

        let head = SKShapeNode(
            circleOfRadius: 28
        )

        head.fillColor = .brown
        head.strokeColor = .black
        head.lineWidth = 2

        head.position = CGPoint(
            x: 42,
            y: 10
        )

        nala.addChild(head)

        let whiteFace = SKShapeNode(
            circleOfRadius: 13
        )

        whiteFace.fillColor = .white
        whiteFace.strokeColor = .clear

        whiteFace.position = CGPoint(
            x: 50,
            y: 5
        )

        nala.addChild(whiteFace)

        let eye = SKShapeNode(
            circleOfRadius: 4
        )

        eye.fillColor = .black
        eye.strokeColor = .clear

        eye.position = CGPoint(
            x: 55,
            y: 14
        )

        nala.addChild(eye)

        for x in [-22, 22] {

            let leg = SKShapeNode(
                rectOf: CGSize(
                    width: 10,
                    height: 32
                )
            )

            leg.fillColor = .brown
            leg.strokeColor = .black
            leg.lineWidth = 1

            leg.position = CGPoint(
                x: x,
                y: -30
            )

            nala.addChild(leg)
        }
    }

    private func loseLife() {

        lives -= 1

        if lives <= 0 {

            lives = 3
            score = 18
            player.position = CGPoint(
                x: 160,
                y: 250
            )

        } else {

            respawn()
        }

        updateHUD()
    }

    private func respawn() {

        player.position = CGPoint(
            x: max(160, player.position.x - 350),
            y: 320
        )

        velocity = CGVector(
            dx: 0,
            dy: 0
        )
    }

    private func cameraFollow() {

        let targetX = player.position.x

        cameraNode.position.x =
            max(
                size.width / 2,
                min(
                    targetX,
                    5700
                )
            )
    }

    private func win() {

        let label = SKLabelNode(
            fontNamed: "Menlo-Bold"
        )

        label.text = "🏠 ZUHAUSE!"
        label.fontSize = 48
        label.fontColor = .white
        label.position = CGPoint(
            x: player.position.x,
            y: 520
        )

        label.zPosition = 5000

        addChild(label)

        leftTouches.removeAll()
        rightTouches.removeAll()
    }

    private func roofPath(
        width: CGFloat,
        height: CGFloat
    ) -> CGPath {

        let path = CGMutablePath()

        path.move(
            to: CGPoint(
                x: -width / 2,
                y: -height / 2
            )
        )

        path.addLine(
            to: CGPoint(
                x: 0,
                y: height / 2
            )
        )

        path.addLine(
            to: CGPoint(
                x: width / 2,
                y: -height / 2
            )
        )

        path.closeSubpath()

        return path
    }
}

enum ColorBridge {

    static let sky = SKColor(
        red: 0.08,
        green: 0.45,
        blue: 0.78,
        alpha: 1
    )
}

private extension SKNode {

    func removeFromParentChildren() {
        removeAllChildren()
    }
}
