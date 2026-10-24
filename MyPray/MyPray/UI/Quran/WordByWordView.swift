import SwiftUI

public struct WordByWordView: View {
    public let verse: Verse

    public init(verse: Verse) {
        self.verse = verse
    }

    public var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            // Verse Header
            HStack {
                Text("Ayah \(verse.verseKey)")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.15))
                    .foregroundStyle(.green)
                    .clipShape(Capsule())

                Spacer()
            }

            // Word-by-Word wrapped flow
            FlowLayout(spacing: 10) {
                ForEach(verse.words.filter { $0.charTypeName == "word" }) { word in
                    wordCard(for: word)
                }
            }
            .environment(\.layoutDirection, .rightToLeft)

            // Full verse translation beneath
            if !verse.translationText.isEmpty {
                Text(verse.translationText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    private func wordCard(for word: QuranWord) -> some View {
        VStack(spacing: 4) {
            Text(word.textUthmani)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.primary)

            if let translit = word.transliteration, !translit.isEmpty {
                Text(translit)
                    .font(.system(size: 11, weight: .regular))
                    .italic()
                    .foregroundStyle(.secondary)
            }

            if let trans = word.translation, !trans.isEmpty {
                Text(trans)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.green)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(uiColor: .tertiarySystemFill))
        )
    }
}

// Custom Flexible Flow Layout for SwiftUI
public struct FlowLayout: Layout {
    public var spacing: CGFloat = 8

    public init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width && currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            height = max(height, currentY + rowHeight)
        }

        return CGSize(width: width, height: height)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
