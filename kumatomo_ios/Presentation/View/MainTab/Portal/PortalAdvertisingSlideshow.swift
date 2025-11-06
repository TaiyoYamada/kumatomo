import SwiftUI

struct PortalAdvertisingSlideshow: View {
    @State private var currentSlideIndex: Int = 0
    @State private var timer: Timer?
    @State private var hasValidImages: Bool = false
    @Environment(NetworkMonitor.self) private var networkMonitor

    // ここは管理者画面から登録できるようにする予定
    private let slideImages = ["portal_slide_1", "portal_slide_2", "portal_slide_3"]

    private let slideDuration: TimeInterval = 3.5

    var body: some View {
        Group {
            if slideImages.isEmpty {
                emptyStateView
            } else {
                TabView(selection: $currentSlideIndex) {
                    ForEach(0..<slideImages.count, id: \.self) { index in
                        slideImageView(for: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: slideImages.count > 1 ? .automatic : .never))
                .frame(height: 200)
                .overlay(alignment: .topTrailing) {
                    if !networkMonitor.isConnected {
                        networkStatusIndicator
                    }
                }
            }
        }
        .onAppear {
            validateImages()
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: currentSlideIndex) { _, _ in
            restartTimer()
        }
        .onChange(of: networkMonitor.isConnected) { _, isConnected in
            if isConnected && hasValidImages {
                restartTimer()
            } else {
                stopTimer()
            }
        }
    }


    private func startTimer() {

        guard slideImages.count > 1 && hasValidImages else { return }

        timer = PortalErrorHandler.shared.createTimer(
            interval: slideDuration,
            repeats: true
        ) { _ in
            withAnimation(.easeInOut(duration: 1.5)) {
                currentSlideIndex = (currentSlideIndex + 1) % slideImages.count
            }
        }

        if timer == nil {
            PortalErrorHandler.shared.logError(.timerError, "Failed to create slideshow timer")
        }
    }


    private func stopTimer() {
        PortalErrorHandler.shared.invalidateTimer(timer)
        timer = nil
    }


    private func restartTimer() {
        stopTimer()
        startTimer()
    }



    private func validateImages() {
        let validation = PortalErrorHandler.shared.validateAssets(slideImages)
        hasValidImages = validation.isValid

        if !validation.missingAssets.isEmpty {
            for missingAsset in validation.missingAssets {
                PortalErrorHandler.shared.logError(.assetNotFound(missingAsset), "Slideshow image missing")
            }
        }
    }


    @ViewBuilder
    private func slideImageView(for index: Int) -> some View {
        let imageName = slideImages[index]

        if PortalErrorHandler.shared.validateImageAsset(imageName) {
            Image(imageName)
                .resizable()
                .aspectRatio(16/9, contentMode: .fill)
                .clipped()
                .cornerRadius(12)
        } else {
            placeholderView(for: index, imageName: imageName, isError: true)
        }
    }


    @ViewBuilder
    private func placeholderView(for index: Int, imageName: String, isError: Bool = false) -> some View {
        Rectangle()
            .fill(LinearGradient(
                gradient: Gradient(colors: isError ?
                    [.red.opacity(0.2), .orange.opacity(0.2)] :
                    [.orange.opacity(0.3), .purple.opacity(0.3)]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: isError ? "exclamationmark.triangle" : "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.8))

                    Text(isError ? "画像が見つかりません" : "スライド \(index + 1)")
                        .font(.headline)
                        .foregroundColor(.white)

                    if isError {
                        Text("アセット: \(imageName)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    } else {
                        Text("TODO: \(imageName)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding()
            }
            .aspectRatio(16/9, contentMode: .fill)
            .clipped()
            .cornerRadius(12)
    }


    private var emptyStateView: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.1))
            .frame(height: 200)
            .overlay {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)

                    Text("スライドショーが設定されていません")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("画像を追加してください")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .cornerRadius(12)
    }


    private var networkStatusIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "wifi.slash")
                .font(.caption)
            Text("オフライン")
                .font(.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.red.opacity(0.8))
        .foregroundColor(.white)
        .cornerRadius(8)
        .padding(8)
    }
}
