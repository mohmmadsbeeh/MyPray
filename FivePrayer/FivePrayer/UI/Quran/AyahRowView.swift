import SwiftUI

public struct AyahRowView: View {
    public let verse: Verse
    public var onPlayVerseAudio: ((Verse) -> Void)?

    public init(verse: Verse, onPlayVerseAudio: ((Verse) -> Void)? = nil) {
        self.verse = verse
        self.onPlayVerseAudio = onPlayVerseAudio
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Verse Header: Key badge & controls
            HStack {
                Text(verse.verseKey)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.15))
                    .foregroundStyle(Color.green)
                    .clipShape(Capsule())

                Spacer()

                if verse.audioUrl != nil {
                    Button {
                        onPlayVerseAudio?(verse)
                    } label: {
                        Image(systemName: "play.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.green)
                    }
                }
            }

            // Arabic Text (Right-to-Left Uthmani script)
            Text(verse.textUthmani)
                .font(.custom("Amiri-Regular", size: 26, relativeTo: .title2))
                .lineSpacing(12)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundStyle(.primary)

            // Translation Text (English)
            if !verse.translationText.isEmpty {
                Text(verse.translationText)
                    .font(.body)
                    .lineSpacing(5)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
}
