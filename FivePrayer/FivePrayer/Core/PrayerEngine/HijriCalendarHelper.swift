import Foundation

public struct HijriDate: Sendable {
    public let day: Int
    public let month: Int
    public let year: Int
    public let monthNameEnglish: String
    public let monthNameArabic: String
    public let formattedEnglish: String
    public let formattedArabic: String

    public static let monthNamesEnglish = [
        1: "Muharram", 2: "Safar", 3: "Rabi' al-Awwal", 4: "Rabi' al-Thani",
        5: "Jumada al-Awwal", 6: "Jumada al-Thani", 7: "Rajab", 8: "Sha'ban",
        9: "Ramadan", 10: "Shawwal", 11: "Dhu al-Qi'dah", 12: "Dhu al-Hijjah"
    ]

    public static let monthNamesArabic = [
        1: "مُحَرَّم", 2: "صَفَر", 3: "رَبِيع الأَوَّل", 4: "رَبِيع الآخِر",
        5: "جُمَادَى الأُولَى", 6: "جُمَادَى الآخِرَة", 7: "رَجَب", 8: "شَعْبَان",
        9: "رَمَضَان", 10: "شَوَّال", 11: "ذُو القَعْدَة", 12: "ذُو الحِجَّة"
    ]
}

public final class HijriCalendarHelper {
    private static let islamicCalendar = Calendar(identifier: .islamicUmmAlQura)

    public static func hijriDate(for date: Date = Date()) -> HijriDate {
        let components = islamicCalendar.dateComponents([.day, .month, .year], from: date)
        let day = components.day ?? 1
        let month = components.month ?? 1
        let year = components.year ?? 1448

        let monthEnglish = HijriDate.monthNamesEnglish[month] ?? "Muharram"
        let monthArabic = HijriDate.monthNamesArabic[month] ?? "محرم"

        let formattedEnglish = "\(day) \(monthEnglish) \(year) AH"
        let formattedArabic = "\(day) \(monthArabic) \(year) هـ"

        return HijriDate(
            day: day,
            month: month,
            year: year,
            monthNameEnglish: monthEnglish,
            monthNameArabic: monthArabic,
            formattedEnglish: formattedEnglish,
            formattedArabic: formattedArabic
        )
    }

    public static func formattedHijriString(for date: Date = Date(), inArabic: Bool = false) -> String {
        let hijri = hijriDate(for: date)
        return inArabic ? hijri.formattedArabic : hijri.formattedEnglish
    }
}
