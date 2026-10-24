import SwiftUI

public struct MushafPageView: View {
    public let verses: [Verse]
    @State private var selectedVerse: Verse?

    public init(verses: [Verse]) {
        self.verses = verses
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Mushaf Page Frame
                VStack(spacing: 16) {
                    // Continuous Mushaf Arabic Text
                    Text(attributedMushafText)
                        .font(.custom("Amiri-Regular", size: 24, relativeTo: .title3))
                        .lineSpacing(16)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(20)
                }
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.green.opacity(0.2), lineWidth: 1.5)
                        )
                )
                .padding(.horizontal)

                // Quick Verse Selector Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(verses) { verse in
                            Button {
                                selectedVerse = verse
                            } label: {
                                Text("Ayah \(verse.verseNumber)")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color(uiColor: .tertiarySystemFill))
                                    .foregroundStyle(.primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .sheet(item: $selectedVerse) { verse in
            NavigationStack {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Ayah \(verse.verseKey)")
                            .font(.headline)
                        Spacer()
                    }

                    Text(verse.textUthmani)
                        .font(.title2)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .multilineTextAlignment(.trailing)

                    Divider()

                    Text("Translation")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)

                    Text(verse.translationText)
                        .font(.body)

                    Spacer()
                }
                .padding(20)
                .navigationTitle("Verse Details")
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium])
        }
    }

    private var attributedMushafText: AttributedString {
        var result = AttributedString("")
        for verse in verses {
            var verseString = AttributedString("\(verse.textUthmani) ")
            verseString.font = .system(size: 24, weight: .regular)

            var markerString = AttributedString(" ۝\(verse.verseNumber) ")
            markerString.font = .system(size: 18, weight: .bold)
            markerString.foregroundColor = .green

            result.append(verseString)
            result.append(markerString)
        }
        return result
    }
}
