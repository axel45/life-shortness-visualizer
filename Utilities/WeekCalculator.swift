import Foundation

enum WeekCalculator {

    static func lifeWeekIndex(from birthDate: Date, on date: Date = Date()) -> Int {
        let seconds = date.timeIntervalSince(birthDate)
        return max(0, Int(seconds / (7 * 86400)))
    }

    static func weekStartDate(lifeWeekIndex: Int, birthDate: Date) -> Date {
        birthDate.addingTimeInterval(Double(lifeWeekIndex) * 7 * 86400)
    }

    static func weekEndDate(lifeWeekIndex: Int, birthDate: Date) -> Date {
        weekStartDate(lifeWeekIndex: lifeWeekIndex, birthDate: birthDate)
            .addingTimeInterval(6 * 86400)
    }

    static func gridRow(_ lifeWeekIndex: Int) -> Int {
        lifeWeekIndex / Constants.weeksPerYear
    }

    static func gridCol(_ lifeWeekIndex: Int) -> Int {
        lifeWeekIndex % Constants.weeksPerYear
    }

    static func lifeWeekIndex(row: Int, col: Int) -> Int {
        row * Constants.weeksPerYear + col
    }

    static func age(lifeWeekIndex: Int) -> Int {
        lifeWeekIndex / Constants.weeksPerYear
    }

    static func formattedDateRange(lifeWeekIndex: Int, birthDate: Date) -> String {
        let start = weekStartDate(lifeWeekIndex: lifeWeekIndex, birthDate: birthDate)
        let end = weekEndDate(lifeWeekIndex: lifeWeekIndex, birthDate: birthDate)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日"
        return "\(formatter.string(from: start)) 〜 \(formatter.string(from: end))"
    }
}
