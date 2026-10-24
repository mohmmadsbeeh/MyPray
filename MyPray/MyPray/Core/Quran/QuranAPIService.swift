import Foundation

public actor QuranAPIService {
    public static let shared = QuranAPIService()

    private let baseURL = "https://api.quran.com/api/v4"
    private let session: URLSession
    private var chaptersCache: [Surah]?
    private var versesCache: [Int: [Verse]] = [:]

    private init() {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.timeoutIntervalForRequest = 20.0
        self.session = URLSession(configuration: config)
    }

    // MARK: - Chapters List

    public func fetchChapters() async throws -> [Surah] {
        if let cached = chaptersCache {
            return cached
        }

        guard let url = URL(string: "\(baseURL)/chapters?language=en") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(ChaptersResponse.self, from: data)
        self.chaptersCache = decoded.chapters
        return decoded.chapters
    }

    // MARK: - Verses for Chapter

    public func fetchVerses(chapterId: Int, perPage: Int = 50, page: Int = 1) async throws -> [Verse] {
        var components = URLComponents(string: "\(baseURL)/verses/by_chapter/\(chapterId)")
        components?.queryItems = [
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "words", value: "true"),
            URLQueryItem(name: "translations", value: "131"), // Dr. Mustafa Khattab (The Clear Quran)
            URLQueryItem(name: "fields", value: "text_uthmani,chapter_id"),
            URLQueryItem(name: "per_page", value: "\(perPage)"),
            URLQueryItem(name: "page", value: "\(page)")
        ]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(VersesResponse.self, from: data)
        return decoded.verses
    }

    public func fetchAllVerses(chapterId: Int, totalVerses: Int) async throws -> [Verse] {
        if let cached = versesCache[chapterId] {
            return cached
        }

        var allVerses: [Verse] = []
        let perPage = 50
        let totalPages = Int(ceil(Double(totalVerses) / Double(perPage)))

        for page in 1...max(1, totalPages) {
            let verses = try await fetchVerses(chapterId: chapterId, perPage: perPage, page: page)
            allVerses.append(contentsOf: verses)
        }

        self.versesCache[chapterId] = allVerses
        return allVerses
    }

    // MARK: - Audio Stream URL

    public func fetchChapterAudioUrl(recitationId: Int, chapterId: Int) async throws -> URL {
        guard let url = URL(string: "\(baseURL)/chapter_recitations/\(recitationId)/\(chapterId)") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(ChapterAudioResponse.self, from: data)
        var audioString = decoded.audioFile.audioUrl
        if audioString.hasPrefix("//") {
            audioString = "https:" + audioString
        }

        guard let audioURL = URL(string: audioString) else {
            throw URLError(.badURL)
        }

        return audioURL
    }
}
