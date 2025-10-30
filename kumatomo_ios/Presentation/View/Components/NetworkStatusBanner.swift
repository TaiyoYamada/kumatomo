import SwiftUI

struct NetworkStatusBanner: View {
    @Environment(NetworkMonitor.self) private var networkMonitor
    
    var body: some View {
        if !networkMonitor.isConnected {
            VStack {
                HStack {
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.white)
                    
                    Text("インターネット接続がありません")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.red)
                
                Spacer()
            }
            .transition(.move(edge: .top))
            .animation(.easeInOut, value: networkMonitor.isConnected)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct NetworkStatusBanner_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            NetworkStatusBanner()
            Spacer()
        }
    }
}
#endif
