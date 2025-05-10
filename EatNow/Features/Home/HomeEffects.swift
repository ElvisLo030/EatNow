import SwiftUI
import UIKit

// MARK: - 特效控制器
class EffectsController: ObservableObject {
    @Published var showFireworks = false
    @Published var showWarningMessage = false
    @Published var showExplosion = false
    @Published var buttonRedLevel: Double = 0
    @Published var buttonColor: Color = .accentColor
    @Published var warningMessage = "還沒決定好嗎？"
    
    // 預加載標記
    @Published var fireworksPreloaded = false
    
    private var lastCheckedCount = 0
    
    // 初始化時預加載煙花特效
    init() {
        // 延遲100ms預加載，避免影響啟動速度
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.1))
            self.fireworksPreloaded = true
        }
    }
    
    // 此方法只用於獲取顏色，不修改狀態
    func getButtonColor(count: Int) -> Color {
        // 連續戳100次後，按鈕逐漸變色
        if count >= 100 {
            let redLevel = min(Double(count - 100) / 400.0, 1.0)
            
            // 根據紅色等級返回顏色
            if redLevel > 0.75 {
                return .red
            } else if redLevel > 0.5 {
                return .orange
            } else if redLevel > 0.25 {
                return .yellow
            }
        }
        
        // 默認顏色
        return .accentColor
    }
    
    // 處理點擊事件的方法，可以由按鈕事件調用
    func handleButtonClick(count: Int, mode: Int) {
        if count != lastCheckedCount {
            lastCheckedCount = count
            print("處理點擊數: \(count)") // 調試用
            
            // 連續戳10次顯示提示
            if count == 10 {
                @MainActor func showWarning() {
                    self.showWarningMessage = true
                    // 3秒後自動隱藏提示
                    Task {
                        try? await Task.sleep(for: .seconds(3))
                        self.showWarningMessage = false
                    }
                }
                
                Task { @MainActor in
                    showWarning()
                }
            }
            
            // 更新按鈕紅色等級
            if count >= 100 {
                let redLevel = min(Double(count - 100) / 400.0, 1.0)
                
                @MainActor func updateButton() {
                    self.buttonRedLevel = redLevel
                    self.buttonColor = self.getButtonColor(count: count)
                }
                
                Task { @MainActor in
                    updateButton()
                }
                
                // 500次時觸發爆炸特效
                if count == 500 {
                    @MainActor func showExplosionEffect() {
                        self.showExplosion = true
                        // 5秒後關閉爆炸特效
                        Task {
                            try? await Task.sleep(for: .seconds(5))
                            self.showExplosion = false
                        }
                    }
                    
                    Task { @MainActor in
                        showExplosionEffect()
                    }
                }
            } else {
                @MainActor func resetButtonColor() {
                    self.buttonColor = .accentColor
                }
                
                Task { @MainActor in
                    resetButtonColor()
                }
            }
        }
    }
    
    // 觸發煙花特效
    func triggerFireworks() {
        @MainActor func showFireworksEffect() {
            self.showFireworks = true
            // 2秒後關閉煙花特效
            Task {
                try? await Task.sleep(for: .seconds(2))
                self.showFireworks = false
            }
        }
        
        Task { @MainActor in
            showFireworksEffect()
        }
    }
    
    // 重置所有特效
    func resetEffects() {
        @MainActor func resetAllEffects() {
            self.buttonRedLevel = 0
            self.buttonColor = .accentColor
            self.showWarningMessage = false
            self.showExplosion = false
            self.lastCheckedCount = 0
        }
        
        Task { @MainActor in
            resetAllEffects()
        }
    }
}

// MARK: - 視圖特效
// 煙花特效 - iOS 18優化版
struct FireworksView: View {
    @State private var particles: [FireworkParticle] = []
    @State private var isActive = false
    
    // 預加載控制
    @EnvironmentObject private var effectsController: EffectsController
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [particle.color.opacity(0.8), particle.color]),
                                center: .center,
                                startRadius: 0,
                                endRadius: particle.size / 2
                            )
                        )
                        .frame(width: particle.size, height: particle.size)
                        .position(x: particle.x, y: particle.y)
                        .opacity(particle.opacity)
                        // 移除模糊效果，提高性能
                        .shadow(color: particle.color.opacity(0.3), radius: particle.size * 0.1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                isActive = true
                generateParticles(in: geometry.size)
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    generateParticles(in: geometry.size)
                }
            }
            // 使用預加載機制
            .onChange(of: effectsController.fireworksPreloaded) { _, newValue in
                if newValue {
                    // 先創建粒子資源但不顯示
                    preloadParticles(in: geometry.size)
                }
            }
            .contentTransition(.symbolEffect(.replace))
        }
    }
    
    // 預加載粒子，但不顯示動畫
    private func preloadParticles(in size: CGSize) {
        // 僅創建少量粒子用於預加載
        particles = []
        
        // 只從底部中心生成少量粒子
        let centerBottom = CGPoint(x: size.width * 0.5, y: size.height)
        
        for _ in 0..<5 {
            // 修復未使用變量的警告
            _ = Double.random(in: -0.3...0.3) + .pi * 1.5
            _ = size.height * 0.3
            let size = CGFloat.random(in: 8...15)
            let color = generateRandomColor()
            
            let particle = FireworkParticle(
                x: centerBottom.x,
                y: centerBottom.y,
                size: size,
                color: color,
                opacity: 0 // 不可見的粒子
            )
            particles.append(particle)
        }
    }
    
    func generateParticles(in size: CGSize) {
        // 清空現有粒子
        particles = []
        
        // 兩側發射點位置
        let leftSide = CGPoint(x: 0, y: size.height / 2)
        let rightSide = CGPoint(x: size.width, y: size.height / 2)
        
        // 從左側發射粒子 - 減少數量
        generateParticlesFromSide(side: leftSide, direction: 1, size: size, count: 25)
        
        // 從右側發射粒子 - 減少數量
        generateParticlesFromSide(side: rightSide, direction: -1, size: size, count: 25)
        
        // 從底部發射額外的粒子 - 減少發射點和每點粒子數
        let bottomPoints = [
            CGPoint(x: size.width * 0.5, y: size.height)
        ]
        
        for point in bottomPoints {
            for _ in 0..<20 {
                // 底部粒子向上發射角度範圍
                let angle = Double.random(in: -0.7...0.7) + .pi * 1.5
                let distance = CGFloat.random(in: 50...size.height * 0.8)
                let speed = Double.random(in: 0.8...1.5)
                let size = CGFloat.random(in: 8...15) // 稍微簡化粒子大小範圍
                let color = generateRandomColor()
                
                let targetX = point.x + cos(angle) * distance
                let targetY = point.y + sin(angle) * distance
                
                let particle = FireworkParticle(
                    x: point.x,
                    y: point.y,
                    size: size,
                    color: color,
                    opacity: 1.0
                )
                particles.append(particle)
                
                // 動畫
                let particleIndex = particles.count - 1
                let delay = Double.random(in: 0...0.2) // 減少延遲時間範圍
                
                // 使用新的動畫API移動粒子 - 使用更簡單的動畫
                withAnimation(.easeOut(duration: 0.8 * speed).delay(delay)) {
                    particles[particleIndex].x = targetX
                    particles[particleIndex].y = targetY
                }
                
                // 使用漸變淡出效果
                withAnimation(.easeIn(duration: 0.9 * speed).delay(delay + 0.3)) {
                    particles[particleIndex].opacity = 0
                }
            }
        }
    }
    
    // 從側面生成向中間發射的粒子
    private func generateParticlesFromSide(side: CGPoint, direction: CGFloat, size: CGSize, count: Int) {
        for _ in 0..<count {
            // 側面粒子發射角度範圍 (向中間發射)
            let angle = Double.random(in: -0.6...0.6) + (direction > 0 ? 0 : .pi)
            let distance = CGFloat.random(in: size.width * 0.3...size.width * 0.7)
            let speed = Double.random(in: 0.8...1.5)
            let particleSize = CGFloat.random(in: 8...15)
            
            // 生成亮麗的顏色
            let color = generateRandomColor()
            
            let targetX = side.x + cos(angle) * distance
            let targetY = side.y + sin(angle) * distance
            
            let particle = FireworkParticle(
                x: side.x,
                y: side.y,
                size: particleSize,
                color: color,
                opacity: 1.0
            )
            particles.append(particle)
            
            // 設置動畫
            let particleIndex = particles.count - 1
            let delay = Double.random(in: 0...0.2) // 減少延遲範圍
            
            // 使用簡化的動畫
            withAnimation(.easeOut(duration: 0.8 * speed).delay(delay)) {
                particles[particleIndex].x = targetX
                particles[particleIndex].y = targetY
            }
            
            // 淡出動畫
            withAnimation(.easeIn(duration: 0.9 * speed).delay(delay + 0.2)) {
                particles[particleIndex].opacity = 0
            }
        }
    }
    
    // 生成亮麗隨機顏色
    private func generateRandomColor() -> Color {
        let baseColors: [Color] = [.red, .orange, .yellow, .blue, .purple, .pink]
        return baseColors.randomElement() ?? .red
    }
}

// 爆炸特效 - iOS 18優化版
struct ExplosionView: View {
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 1.0
    @State private var rotation: Double = 0
    @State private var particles: [ExplosionParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 底層閃光效果
                Circle()
                    .fill(Color.white)
                    .frame(width: 320, height: 320)
                    .scaleEffect(scale * 0.8)
                    .opacity(opacity * 0.7)
                    .blur(radius: 30)
                    .position(x: geometry.size.width/2, y: geometry.size.height/2)
                
                // 內層爆炸波紋
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [Color.white, Color.red.opacity(0.8)]),
                            center: .center,
                            startRadius: 10,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .scaleEffect(scale)
                    .opacity(opacity * 0.8)
                    .blur(radius: 20)
                    .position(x: geometry.size.width/2, y: geometry.size.height/2)
                
                // 中層波紋
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [Color.yellow, Color.orange]),
                            center: .center,
                            startRadius: 5,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(scale * 1.2)
                    .opacity(opacity * 0.9)
                    .blur(radius: 8)
                    .position(x: geometry.size.width/2, y: geometry.size.height/2)
                
                // 爆炸符號
                Text("💥")
                    .font(.system(size: 100))
                    .scaleEffect(scale * 2.2)
                    .opacity(opacity)
                    .rotationEffect(.degrees(rotation))
                    .shadow(color: .orange, radius: 20, x: 0, y: 0)
                    .position(x: geometry.size.width/2, y: geometry.size.height/2)
                
                // 爆炸碎片
                ForEach(particles) { particle in
                    particle.shape
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(x: geometry.size.width/2 + particle.x, 
                                  y: geometry.size.height/2 + particle.y)
                        .opacity(particle.opacity)
                        .rotationEffect(.degrees(particle.rotation))
                        .blur(radius: 1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                // 爆炸動畫 - 使用更自然的彈性效果
                withAnimation(.spring(duration: 0.3, bounce: 0.4, blendDuration: 0.2)) {
                    scale = 1.0
                    rotation = 15
                }
                
                // 隨機旋轉
                withAnimation(.easeInOut(duration: 0.5).repeatCount(3, autoreverses: true)) {
                    rotation = -15
                }
                
                // 淡出效果
                withAnimation(.easeOut(duration: 1.8).delay(0.5)) {
                    opacity = 0.0
                }
                
                // 產生爆炸碎片
                createExplosionParticles(in: geometry.size)
            }
            .contentTransition(.symbolEffect(.replace))
        }
    }
    
    func createExplosionParticles(in size: CGSize) {
        particles = []
        
        // 產生100個碎片 - 適量減少數量到60
        for _ in 0..<60 {
            let angle = Double.random(in: 0..<2*Double.pi)
            let distance = CGFloat.random(in: 50...min(size.width, size.height)/1.8)
            let x = cos(angle) * distance
            let y = sin(angle) * distance
            let particleSize = CGFloat.random(in: 5...20) // 稍微縮小粒子尺寸範圍
            let rotation = Double.random(in: 0...360) // 減少旋轉度數範圍
            
            // 簡化形狀選擇
            let shapes: [AnyShape] = [
                AnyShape(Circle()),
                AnyShape(Rectangle())
            ]
            
            // 簡化顏色範圍
            let colors: [Color] = [
                .red, .orange, .yellow, .white
            ]
            
            let particle = ExplosionParticle(
                x: 0,
                y: 0,
                targetX: x,
                targetY: y,
                size: particleSize,
                color: colors.randomElement()!,
                opacity: 1.0,
                rotation: rotation,
                shape: shapes.randomElement()!
            )
            particles.append(particle)
            
            // 動畫 - 使用彈簧動畫使移動更自然
            let idx = particles.count - 1
            let duration = Double.random(in: 0.5...1.2)
            
            // 簡化動畫為普通動畫，提高性能
            withAnimation(.easeOut(duration: duration)) {
                particles[idx].x = x
                particles[idx].y = y
            }
            
            withAnimation(.easeOut(duration: duration * 1.2).delay(duration * 0.2)) {
                particles[idx].opacity = 0
            }
        }
    }
}

// 警告提示視圖 - iOS 18優化版
struct WarningMessageView: View {
    var message: String
    @State private var bounceOffset: CGFloat = -100
    @State private var opacity: Double = 0
    @State private var glowIntensity: Double = 0
    
    var body: some View {
        Text(message)
            .font(.title3.bold())
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.yellow)
                    .shadow(color: Color.orange.opacity(0.4 + glowIntensity * 0.3), radius: 5 + glowIntensity * 10, x: 0, y: 3)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.orange.opacity(0.7), lineWidth: 2)
            }
            .foregroundColor(.black)
            .offset(y: bounceOffset)
            .opacity(opacity)
            .onAppear {
                // 入場動畫
                withAnimation(.spring(duration: 0.5, bounce: 0.4)) {
                    bounceOffset = 0
                    opacity = 1
                }
                
                // 脈動發光效果
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    glowIntensity = 1.0
                }
                
                // 退場時間設置 - 在控制器中控制
            }
            .keyframeAnimator(initialValue: CGFloat.zero, trigger: opacity) { content, value in
                content
                    .scaleEffect(1.0 + value * 0.05)
                    .rotationEffect(.degrees(value * 2))
            } keyframes: { _ in
                KeyframeTrack {
                    CubicKeyframe(0, duration: 0.1)
                    CubicKeyframe(1, duration: 0.1)
                    CubicKeyframe(0, duration: 0.1)
                    CubicKeyframe(1, duration: 0.1)
                    CubicKeyframe(0, duration: 0.1)
                    CubicKeyframe(0, duration: 0.5)
                }
            }
    }
}

// 煙花粒子模型
struct FireworkParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var opacity: Double
}

// 爆炸粒子模型 - 增加形狀屬性
struct ExplosionParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var targetX: CGFloat
    var targetY: CGFloat
    var size: CGFloat
    var color: Color
    var opacity: Double
    var rotation: Double
    var shape: AnyShape
}

// 形狀包裝器 - 用於動態選擇形狀
struct AnyShape: Shape, @unchecked Sendable {
    private let _path: @Sendable (CGRect) -> Path
    
    init<S: Shape>(_ shape: S) {
        self._path = { rect in
            return shape.path(in: rect)
        }
    }
    
    func path(in rect: CGRect) -> Path {
        return _path(rect)
    }
}

// 顏色混合擴展
extension Color {
    func blended(with otherColor: Color, ratio: Double = 0.5) -> Color {
        // 由於SwiftUI的Color不直接支持顏色混合，我們採用簡單的漸變替代方案
        // 當ratio為0時完全是原色，ratio為1時完全是目標色
        if ratio <= 0 { return self }
        if ratio >= 1 { return otherColor }
        
        // 對於中間值，我們根據比例返回目標顏色
        return ratio >= 0.5 ? otherColor : self
    }
} 
