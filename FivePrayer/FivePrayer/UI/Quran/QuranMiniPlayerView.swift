import SwiftUI

public struct QuranMiniPlayerView: View {
    @ObservedObject var player = QuranAudioPlayer.shared
    @State private var isExpanded: Bool = false

    public init() {}

    public var body: some View {
        if let surah = player.currentSurah {
            VStack(spacing: 0) {
                // Thin progress track on top
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.2))
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: max(0, geo.size.width * CGFloat(player.progress)))
                    }
                }
                .frame(height: 3)

                HStack(spacing: 12) {
                    // Play icon badge
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "headphones")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.green)
                    }

                    // Surah & Reciter Name
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(surah.nameSimple)
                                .font(.subheadline.bold())
                            Text(surah.nameArabic)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text(player.currentReciter.name)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Controls
                    if player.isBuffering {
                        ProgressView()
                            .frame(width: 32, height: 32)
                    } else {
                        Button {
                            player.togglePlayPause()
                        } label: {
                            Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                .font(.title3)
                                .foregroundStyle(.primary)
                        }
                    }

                    Button {
                        player.skip(seconds: 15)
                    } label: {
                        Image(systemName: "goforward.15")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        player.stop()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Rectangle()
                        .fill(Color(uiColor: .secondarySystemBackground))
                        .shadow(color: Color.black.opacity(0.08), radius: 6, y: -2)
                )
            }
        }
    }
}
