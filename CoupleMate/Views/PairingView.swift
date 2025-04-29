import SwiftUI

struct PairingView: View {
    @ObservedObject var viewModel: PairingViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("ペアリング")
                .font(.largeTitle)
                .fontWeight(.bold)

            // 招待コードの表示
            VStack {
                Text("あなたの招待コード")
                    .font(.headline)
                Text(viewModel.inviteCode)
                    .font(.title)
                    .padding()
                Button(action: {
                    viewModel.copyInviteCode()
                }) {
                    Text("コピーして共有")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)

            Divider()

            // 招待コードの入力
            VStack {
                Text("招待コードを入力")
                    .font(.headline)
                TextField("コードを入力", text: $viewModel.inputCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                Button(action: {
                    viewModel.joinPair()
                }) {
                    Text("ペアに参加する")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)

            Spacer()
        }
        .padding()
    }
}
