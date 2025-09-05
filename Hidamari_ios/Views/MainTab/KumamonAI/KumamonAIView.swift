import SwiftUI

struct KumamonAIView: View {
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                Text("くまモンAI")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("AI チャット機能は準備中です")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                
                Spacer()
            }
            .navigationTitle("くまモンAI")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    KumamonAIView()
}