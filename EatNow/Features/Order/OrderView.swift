import SwiftUI

struct OrderView: View {
    @StateObject private var currentOrder = CurrentOrder()
    @State private var showingOrderHistory = false
    @State private var showingStoreSelection = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 歡迎訊息
                VStack(spacing: 8) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("開始點餐")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text("選擇您喜愛的店家")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // 主要按鈕
                VStack(spacing: 16) {
                    // 點餐按鈕
                    Button(action: {
                        showingStoreSelection = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            
                            Text("開始點餐")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    // 歷史點餐按鈕
                    Button(action: {
                        showingOrderHistory = true
                    }) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.title2)
                            
                            Text("歷史點餐")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
            .navigationTitle("點餐")
            .navigationBarTitleDisplayMode(.large)
        }
        .fullScreenCover(isPresented: $showingOrderHistory) {
            OrderHistoryView()
        }
        .sheet(isPresented: $showingStoreSelection) {
            StoreSelectionView(currentOrder: currentOrder)
                .onDisappear {
                    // 重置狀態，準備下次點餐
                    currentOrder.clearOrder()
                }
        }
    }
}

#Preview {
    OrderView()
}
