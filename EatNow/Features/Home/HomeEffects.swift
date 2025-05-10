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
    
    private var lastCheckedCount = 0
    
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
            
            // 連續戳50次顯示提示
            if count == 50 {
                DispatchQueue.main.async {
                    self.showWarningMessage = true
                    // 3秒後自動隱藏提示
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.showWarningMessage = false
                    }
                }
            }
            
            // 更新按鈕紅色等級
            if count >= 100 {
                let redLevel = min(Double(count - 100) / 400.0, 1.0)
                DispatchQueue.main.async {
                    self.buttonRedLevel = redLevel
                    self.buttonColor = self.getButtonColor(count: count)
                }
                
                // 500次時觸發爆炸特效
                if count == 500 {
                    DispatchQueue.main.async {
                        self.showExplosion = true
                        // 2秒後關閉爆炸特效
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self.showExplosion = false
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.buttonColor = .accentColor
                }
            }
        }
    }
    
    // 觸發煙花特效
    func triggerFireworks() {
        DispatchQueue.main.async {
            self.showFireworks = true
            // 2秒後關閉煙花特效
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.showFireworks = false
            }
        }
    }
    
    // 重置所有特效
    func resetEffects() {
        DispatchQueue.main.async {
            self.buttonRedLevel = 0
            self.buttonColor = .accentColor
            self.showWarningMessage = false
            self.showExplosion = false
            self.lastCheckedCount = 0
        }
    }
}

// MARK: - 視圖特效
// 煙花特效 - iOS 18優化版
struct FireworksView: View {
    @State private var particles: [FireworkParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(x: particle.x, y: particle.y)
                        .opacity(particle.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                generateParticles(in: geometry.size)
            }
            .contentTransition(.symbolEffect(.replace))
        }
    }
    
    func generateParticles(in size: CGSize) {
        // 清空現有粒子
        particles = []
        
        // 兩側發射點位置
        let leftSide = CGPoint(x: 0, y: size.height / 2)
        let rightSide = CGPoint(x: size.width, y: size.height / 2)
        
        // 從左側發射粒子
        generateParticlesFromSide(side: leftSide, direction: 1, size: size)
        
        // 從右側發射粒子
        generateParticlesFromSide(side: rightSide, direction: -1, size: size)
        
        // 從底部發射額外的粒子
        let bottomPoints = [
            CGPoint(x: size.width * 0.25, y: size.height),
            CGPoint(x: size.width * 0.75, y: size.height)
        ]
        
        for point in bottomPoints {
            for _ in 0..<30 {
                // 底部粒子向上發射角度範圍
                let angle = Double.random(in: -0.6...0.6) + .pi * 1.5
                let distance = CGFloat.random(in: 50...size.height * 0.7)
                let speed = Double.random(in: 0.8...1.5)
                let size = CGFloat.random(in: 5...15)
                let color = [Color.red, Color.blue, Color.green, Color.yellow, Color.orange, Color.purple, Color.pink].randomElement()!
                
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
                let delay = Double.random(in: 0...0.3)
                
                withAnimation(.easeOut(duration: 1.0 * speed).delay(delay)) {
                    particles[particleIndex].x = targetX
                    particles[particleIndex].y = targetY
                }
                
                withAnimation(.easeIn(duration: 1.2 * speed).delay(delay + 0.3)) {
                    particles[particleIndex].opacity = 0
                }
            }
        }
    }
    
    // 從側面生成向中間發射的粒子
    private func generateParticlesFromSide(side: CGPoint, direction: CGFloat, size: CGSize) {
        for _ in 0..<40 {
            // 側面粒子發射角度範圍 (向中間發射)
            let angle = Double.random(in: -0.5...0.5) + (direction > 0 ? 0 : .pi)
            let distance = CGFloat.random(in: size.width * 0.3...size.width * 0.9)
            let speed = Double.random(in: 0.8...1.5)
            let particleSize = CGFloat.random(in: 5...15)
            
            // 更加多彩的顏色
            let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
            let color = colors.randomElement()!
            
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
            let delay = Double.random(in: 0...0.3)
            
            // 移動動畫
            withAnimation(.easeOut(duration: 1.0 * speed).delay(delay)) {
                particles[particleIndex].x = targetX
                particles[particleIndex].y = targetY
            }
            
            // 淡出動畫
            withAnimation(.easeIn(duration: 1.2 * speed).delay(delay + 0.3)) {
                particles[particleIndex].opacity = 0
            }
        }
    }
}

// 爆炸特效 - iOS 18優化版
struct ExplosionView: View {
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 1.0
    @State private var particles: [ExplosionParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 爆炸波紋
                Circle()
                    .fill(Color.red)
                    .frame(width: 300, height: 300)
                    .scaleEffect(scale)
                    .opacity(opacity * 0.8)
                    .blur(radius: 20)
                    .position(x: geometry.size.width/2, y: geometry.size.height/2)
                
                Circle()
                    .fill(Color.orange)
                    .frame(width: 200, height: 200)
                    .scaleEffect(scale * 1.2)
                    .opacity(opacity * 0.9)
                    .blur(radius: 10)
                    .position(x: geometry.size.width/2, y: geometry.size.height/2)
                
                // 爆炸符號
                Text("💥")
                    .font(.system(size: 100))
                    .scaleEffect(scale * 2)
                    .opacity(opacity)
                    .position(x: geometry.size.width/2, y: geometry.size.height/2)
                
                // 爆炸碎片
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(x: geometry.size.width/2 + particle.x, 
                                  y: geometry.size.height/2 + particle.y)
                        .opacity(particle.opacity)
                        .rotationEffect(.degrees(particle.rotation))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                // 爆炸動畫
                withAnimation(.spring(duration: 0.3, bounce: 0.4)) {
                    scale = 1.0
                }
                
                withAnimation(.easeOut(duration: 1.5).delay(0.5)) {
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
        
        // 產生80個碎片
        for _ in 0..<80 {
            let angle = Double.random(in: 0..<2*Double.pi)
            let distance = CGFloat.random(in: 50...min(size.width, size.height)/2)
            let x = cos(angle) * distance
            let y = sin(angle) * distance
            let size = CGFloat.random(in: 5...20)
            let rotation = Double.random(in: 0...360)
            let color = [Color.red, Color.orange, Color.yellow, Color.white].randomElement()!
            
            let particle = ExplosionParticle(
                x: 0,
                y: 0,
                targetX: x,
                targetY: y,
                size: size,
                color: color,
                opacity: 1.0,
                rotation: rotation
            )
            particles.append(particle)
            
            // 動畫
            let idx = particles.count - 1
            withAnimation(.easeOut(duration: Double.random(in: 0.5...1.5))) {
                particles[idx].x = x
                particles[idx].y = y
                particles[idx].opacity = 0
            }
        }
    }
}

// 警告提示視圖 - iOS 18優化版
struct WarningMessageView: View {
    var message: String
    @State private var bounceOffset: CGFloat = 0
    @State private var opacity: Double = 0
    
    var body: some View {
        Text(message)
            .font(.title3.bold())
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.yellow)
                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
            )
            .foregroundColor(.black)
            .offset(y: bounceOffset)
            .opacity(opacity)
            .onAppear {
                // 先顯示
                withAnimation(.easeIn(duration: 0.2)) {
                    opacity = 1
                }
                
                // 再彈跳
                withAnimation(.easeInOut(duration: 0.3).repeatCount(3)) {
                    bounceOffset = -15
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
                        bounceOffset = 0
                    }
                }
            }
            .phaseAnimator([0, 1, 2], trigger: opacity) { content, phase in
                content
                    .scaleEffect(phase == 1 ? 1.05 : 1)
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

// 爆炸粒子模型
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