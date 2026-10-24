import Foundation

// MARK: - Surah (Chapter) Model

public struct Surah: Identifiable, Codable, Hashable, Sendable {
    public let id: Int
    public let nameSimple: String
    public let nameArabic: String
    public let versesCount: Int
    public let revelationPlace: String
    public let revelationOrder: Int
    public let translatedName: String

    enum CodingKeys: String, CodingKey {
        case id
        case nameSimple = "name_simple"
        case nameArabic = "name_arabic"
        case versesCount = "verses_count"
        case revelationPlace = "revelation_place"
        case revelationOrder = "revelation_order"
        case translatedName = "translated_name"
    }

    public init(
        id: Int,
        nameSimple: String,
        nameArabic: String,
        versesCount: Int,
        revelationPlace: String,
        revelationOrder: Int,
        translatedName: String
    ) {
        self.id = id
        self.nameSimple = nameSimple
        self.nameArabic = nameArabic
        self.versesCount = versesCount
        self.revelationPlace = revelationPlace
        self.revelationOrder = revelationOrder
        self.translatedName = translatedName
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.nameSimple = try container.decode(String.self, forKey: .nameSimple)
        self.nameArabic = try container.decode(String.self, forKey: .nameArabic)
        self.versesCount = try container.decode(Int.self, forKey: .versesCount)
        self.revelationPlace = try container.decode(String.self, forKey: .revelationPlace)
        self.revelationOrder = (try? container.decode(Int.self, forKey: .revelationOrder)) ?? id

        if let translatedContainer = try? container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .translatedName),
           let name = try? translatedContainer.decode(String.self, forKey: DynamicCodingKeys(stringValue: "name")!) {
            self.translatedName = name
        } else {
            self.translatedName = (try? container.decode(String.self, forKey: .translatedName)) ?? ""
        }
    }
}

private struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    init?(stringValue: String) { self.stringValue = stringValue }
    var intValue: Int?
    init?(intValue: Int) { return nil }
}

public struct ChaptersResponse: Codable, Sendable {
    public let chapters: [Surah]
}

// MARK: - Verse & Word Models

public struct Verse: Identifiable, Codable, Hashable, Sendable {
    public let id: Int
    public let verseNumber: Int
    public let verseKey: String
    public let textUthmani: String
    public let translationText: String
    public let words: [QuranWord]
    public let audioUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case verseNumber = "verse_number"
        case verseKey = "verse_key"
        case textUthmani = "text_uthmani"
        case translations
        case words
        case audio
    }

    public init(
        id: Int,
        verseNumber: Int,
        verseKey: String,
        textUthmani: String,
        translationText: String,
        words: [QuranWord],
        audioUrl: String? = nil
    ) {
        self.id = id
        self.verseNumber = verseNumber
        self.verseKey = verseKey
        self.textUthmani = textUthmani
        self.translationText = translationText
        self.words = words
        self.audioUrl = audioUrl
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.verseNumber = try container.decode(Int.self, forKey: .verseNumber)
        self.verseKey = try container.decode(String.self, forKey: .verseKey)
        self.textUthmani = (try? container.decode(String.self, forKey: .textUthmani)) ?? ""
        self.words = (try? container.decode([QuranWord].self, forKey: .words)) ?? []

        // Extract translation text from translations array
        if let translations = try? container.decode([RawTranslation].self, forKey: .translations),
           let first = translations.first {
            // Strip HTML tags if any (e.g. <sup> footnotes)
            self.translationText = first.text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        } else {
            self.translationText = ""
        }

        if let rawAudio = try? container.decode(RawVerseAudio.self, forKey: .audio) {
            self.audioUrl = rawAudio.url
        } else {
            self.audioUrl = nil
        }
    }
}

public struct RawTranslation: Codable, Hashable, Sendable {
    public let id: Int?
    public let text: String
}

public struct RawVerseAudio: Codable, Hashable, Sendable {
    public let url: String?
}

public struct VersesResponse: Codable, Sendable {
    public let verses: [Verse]
}

public struct QuranWord: Identifiable, Codable, Hashable, Sendable {
    public let id: Int
    public let position: Int
    public let audioUrl: String?
    public let charTypeName: String
    public let textUthmani: String
    public let translation: String?
    public let transliteration: String?

    enum CodingKeys: String, CodingKey {
        case id
        case position
        case audioUrl = "audio_url"
        case charTypeName = "char_type_name"
        case textUthmani = "text_uthmani"
        case translation
        case transliteration
    }

    public init(
        id: Int,
        position: Int,
        audioUrl: String?,
        charTypeName: String,
        textUthmani: String,
        translation: String?,
        transliteration: String?
    ) {
        self.id = id
        self.position = position
        self.audioUrl = audioUrl
        self.charTypeName = charTypeName
        self.textUthmani = textUthmani
        self.translation = translation
        self.transliteration = transliteration
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.position = try container.decode(Int.self, forKey: .position)
        self.audioUrl = try? container.decode(String.self, forKey: .audioUrl)
        self.charTypeName = (try? container.decode(String.self, forKey: .charTypeName)) ?? "word"
        self.textUthmani = (try? container.decode(String.self, forKey: .textUthmani)) ?? ""

        if let transContainer = try? container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .translation) {
            self.translation = try? transContainer.decode(String.self, forKey: DynamicCodingKeys(stringValue: "text")!)
        } else {
            self.translation = nil
        }

        if let translitContainer = try? container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .transliteration) {
            self.transliteration = try? translitContainer.decode(String.self, forKey: DynamicCodingKeys(stringValue: "text")!)
        } else {
            self.transliteration = nil
        }
    }
}

// MARK: - Reciters & Audio

public struct Reciter: Identifiable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let style: String
    public let recitationId: Int

    public static let availableReciters: [Reciter] = [
        Reciter(id: 7, name: "Mishary Rashid Alafasy", style: "Murattal", recitationId: 7),
        Reciter(id: 1, name: "Abdul Basit Abdus Samad", style: "Murattal", recitationId: 1),
        Reciter(id: 6, name: "Mahmoud Khalil Al-Husary", style: "Murattal", recitationId: 6),
        Reciter(id: 4, name: "Abu Bakr Al-Shatri", style: "Murattal", recitationId: 4),
        Reciter(id: 3, name: "Abdur-Rahman as-Sudais", style: "Murattal", recitationId: 3)
    ]
}

public struct ChapterAudioResponse: Codable, Sendable {
    public let audioFile: ChapterAudioFile

    enum CodingKeys: String, CodingKey {
        case audioFile = "audio_file"
    }
}

public struct ChapterAudioFile: Codable, Sendable {
    public let id: Int
    public let chapterId: Int
    public let audioUrl: String
    public let duration: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case chapterId = "chapter_id"
        case audioUrl = "audio_url"
        case duration
    }
}
