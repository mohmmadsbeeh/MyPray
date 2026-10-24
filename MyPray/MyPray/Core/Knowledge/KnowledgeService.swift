import Foundation

public final class KnowledgeService {
    public static let shared = KnowledgeService()

    private init() {}

    public func fetchArticles(for category: KnowledgeCategory? = nil) -> [KnowledgeArticle] {
        let all = Self.defaultArticles
        if let category = category {
            return all.filter { $0.category == category }
        }
        return all
    }

    public static let defaultArticles: [KnowledgeArticle] = [
        KnowledgeArticle(
            id: "khushu_presence",
            category: .khushu,
            title: "Achieving Khushu': The Five Levels of Prayer",
            arabicSubtitle: "مَرَاتِبُ النَّاسِ فِي الصَّلَاة",
            summary: "Ibn al-Qayyim's timeless classification of human worshipers and how to elevate your heart from mere obligation to divine delight.",
            bodyMarkdown: """
            Imam Ibn al-Qayyim (رحمه الله) explained that people are on five distinct levels regarding their prayer:

            ### 1. The Punished (المُعَاقَب)
            The one who is deficient in both Wudu and the physical mechanics and timings of prayer.

            ### 2. The Questioned (المُحَاسَب)
            The one who preserves the external pillars and timings, but spends the entire prayer lost in worldly distractions and whispers (Waswas).

            ### 3. The Expiated (المُكَفَّر عَنْه)
            The worshiper who preserves the pillars and fights against inner whispers. He is in active spiritual struggle (Jihad) throughout his Salah.

            ### 4. The Rewarded (المَثُوب)
            The one who stands in prayer with his heart completely engaged in reverence, fulfilling every right with devotion.

            ### 5. The Intimate (المُقَرَّب)
            The worshiper whose heart is placed before his Lord, filled with awe, love, and gratitude. For him, Salah is the joy of his eyes (قرة عينه).

            ### Practical Keys for Khushu':
            - Arrive early and make your Wudu mindfully.
            - Pause before the opening Takbeer and remind yourself Who you are addressing.
            - Keep your gaze fixed on the spot of your prostration.
            """,
            estimatedReadTimeMinutes: 4,
            hadithReference: "Al-Wabil al-Sayyib (p. 49)",
            authorOrSource: "Imam Ibn al-Qayyim"
        ),
        KnowledgeArticle(
            id: "fiqh_sujood_sahw",
            category: .fiqh,
            title: "Mastering Sujood as-Sahw (Prostrations of Forgetfulness)",
            arabicSubtitle: "سُجُودُ السَّهْوِ وَأَحْكَامُه",
            summary: "A practical guide to correcting mistakes in prayer: when to prostrate before the Tasleem and when after.",
            bodyMarkdown: """
            Sujood as-Sahw consists of two prostrations performed to rectify unintentional omissions, additions, or doubts in Salah.

            ### When to Prostrate BEFORE the Salam:
            1. **Omission of an obligatory act (Wajib):** For example, forgetting the first Tashahhud and standing up directly.
            2. **Doubt with preference toward the lesser:** When unsure whether you prayed 3 or 4 Rakat, build upon certainty (the lesser number, 3), finish the prayer, and perform Sujood before the Salam.

            ### When to Prostrate AFTER the Salam:
            1. **Unintentional addition (Ziyadah):** For example, accidentally praying five Rakat in Dhuhr instead of four.
            2. **Doubt where certainty is reached:** If you were doubtful but became reasonably certain of the correct count, finish prayer, make Salam, then perform the two prostrations and make Salam again.
            """,
            estimatedReadTimeMinutes: 5,
            hadithReference: "Sahih al-Bukhari 1226, Sahih Muslim 571",
            authorOrSource: "Fiqh Us-Sunnah"
        ),
        KnowledgeArticle(
            id: "hadith_cleansing_river",
            category: .hadith,
            title: "The Five Prayers as a Pure Flowing River",
            arabicSubtitle: "مَثَلُ الصَّلَوَاتِ الخَمْسِ كَنَهْرٍ جَارٍ",
            summary: "How the five daily prayers cleanse the believer's spiritual record completely of daily minor sins.",
            bodyMarkdown: """
            Abu Hurairah (رضي الله عنه) reported that the Messenger of Allah (ﷺ) asked his companions:

            > *"Consider if there were a flowing river by the door of one of you in which he bathes five times a day, would any dirt remain on him?"*
            >
            > They replied: *"No dirt would remain on him at all."*
            >
            > The Prophet (ﷺ) said: *"That is the parable of the five daily prayers; through them, Allah washes away sins."*

            ### Key Reflection:
            Never underestimate any single prayer. Each Salah acts as an oasis that purifies our soul from stress, spiritual fatigue, and mistakes accumulated throughout the workday.
            """,
            estimatedReadTimeMinutes: 3,
            hadithReference: "Sahih al-Bukhari 528, Sahih Muslim 667",
            authorOrSource: "Prophetic Sunnah"
        )
    ]
}
