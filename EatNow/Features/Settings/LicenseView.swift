import SwiftUI

struct LicenseView: View {
    @State private var licenseText: AttributedString = AttributedString("載入中...")
    @State private var isLoading: Bool = true
    @State private var loadError: String? = nil
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("正在從GitHub載入許可證...")
                    .padding()
            } else if let error = loadError {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    
                    Text("載入許可證時發生錯誤")
                        .font(.headline)
                    
                    Text(error)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 16) {
                        Button("重試") {
                            loadLicenseText()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("前往GitHub查看") {
                            openGitHubRepo()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.top, 10)
                }
                .padding()
            } else {
                Text(licenseText)
                    .padding()
            }
        }
        .navigationTitle("LICENSE")
        .onAppear {
            loadLicenseText()
        }
    }
    
    private func openGitHubRepo() {
        if let url = URL(string: "https://github.com/ElvisLo030/EatNow") {
            openURL(url)
        }
    }
    
    private func loadLicenseText() {
        isLoading = true
        loadError = nil
        
        let url = URL(string: "https://raw.githubusercontent.com/ElvisLo030/EatNow/refs/heads/main/LICENSE")!
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    loadError = "網絡錯誤：\(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    loadError = "伺服器錯誤：無法獲取許可證內容"
                    return
                }
                
                if let data = data, let mdString = String(data: data, encoding: .utf8) {
                    if #available(iOS 15.0, *) {
                        // 使用iOS 15的Markdown解析功能
                        do {
                            let attributedString = try AttributedString(markdown: mdString, options: AttributedString.MarkdownParsingOptions(
                                interpretedSyntax: .inlineOnlyPreservingWhitespace
                            ))
                            licenseText = attributedString
                        } catch {
                            // 如果Markdown解析失敗，顯示原始文本
                            licenseText = AttributedString(mdString)
                            print("Markdown解析錯誤: \(error)")
                        }
                    } else {
                        // iOS 15以下版本使用純文本
                        licenseText = AttributedString(mdString)
                    }
                } else {
                    loadError = "資料解析錯誤：無法解析許可證內容"
                }
            }
        }.resume()
    }
}

struct LicenseView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LicenseView()
        }
    }
}