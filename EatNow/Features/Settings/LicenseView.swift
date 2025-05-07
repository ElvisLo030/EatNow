import SwiftUI

struct LicenseView: View {
    @State private var licenseText: String = "載入中..."
    
    var body: some View {
        ScrollView {
            Text(licenseText)
                .padding()
                .font(.system(.body, design: .monospaced))
        }
        .navigationTitle("GNU GPL v3 License")
        .onAppear {
            loadLicenseText()
        }
    }
    
    private func loadLicenseText() {
        if let path = Bundle.main.path(forResource: "LICENSE-App", ofType: nil) {
            do {
                licenseText = try String(contentsOfFile: path, encoding: .utf8)
            } catch {
                licenseText = "無法載入許可證內容：\(error.localizedDescription)"
            }
        } else {
            licenseText = "無法找到許可證文件"
        }
    }
}

struct LicenseView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LicenseView()
        }
    }
}