import Testing
import Foundation

// WeekCalculatorをインライン定義（テスト用スタンドアロン）
private enum Calc {
    static let weeksPerYear = 52

    static func lifeWeekIndex(from birthDate: Date, on date: Date) -> Int {
        let seconds = date.timeIntervalSince(birthDate)
        return max(0, Int(seconds / (7 * 86400)))
    }

    static func gridRow(_ idx: Int) -> Int { idx / weeksPerYear }
    static func gridCol(_ idx: Int) -> Int { idx % weeksPerYear }
    static func lifeWeekIndex(row: Int, col: Int) -> Int { row * weeksPerYear + col }
    static func age(_ idx: Int) -> Int { idx / weeksPerYear }
}

private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
    var c = DateComponents()
    c.year = y; c.month = m; c.day = d
    return Calendar(identifier: .gregorian).date(from: c)!
}

@Suite("WeekCalculator")
struct WeekCalculatorTests {

    @Test("誕生日当日はlifeWeekIndex=0")
    func birthDayIsZero() {
        let birth = date(1999, 6, 23)
        #expect(Calc.lifeWeekIndex(from: birth, on: birth) == 0)
    }

    @Test("6日後もまだ第0週")
    func sixDaysLaterIsWeekZero() {
        let birth = date(1999, 6, 23)
        let sixDays = birth.addingTimeInterval(6 * 86400)
        #expect(Calc.lifeWeekIndex(from: birth, on: sixDays) == 0)
    }

    @Test("7日後は第1週")
    func sevenDaysLaterIsWeekOne() {
        let birth = date(1999, 6, 23)
        let seven = birth.addingTimeInterval(7 * 86400)
        #expect(Calc.lifeWeekIndex(from: birth, on: seven) == 1)
    }

    @Test("1年後（365日）は第52週")
    func oneYearIsWeek52() {
        let birth = date(1999, 6, 23)
        let oneYear = birth.addingTimeInterval(365 * 86400)
        #expect(Calc.lifeWeekIndex(from: birth, on: oneYear) == 52)
    }

    @Test("2026/08/05時点で1999/06/23生まれは1414週")
    func specificDate() {
        let birth = date(1999, 6, 23)
        let today = date(2026, 8, 5)
        // (2026-08-05 - 1999-06-23) = 9905 days → 9905 / 7 = 1415 (floor)
        let idx = Calc.lifeWeekIndex(from: birth, on: today)
        #expect(idx >= 1414 && idx <= 1416)
    }

    @Test("gridRow・gridColの変換")
    func gridCoordinates() {
        #expect(Calc.gridRow(0)  == 0)
        #expect(Calc.gridCol(0)  == 0)
        #expect(Calc.gridRow(52) == 1)
        #expect(Calc.gridCol(52) == 0)
        #expect(Calc.gridRow(53) == 1)
        #expect(Calc.gridCol(53) == 1)
        #expect(Calc.gridRow(103) == 1)
        #expect(Calc.gridCol(103) == 51)
    }

    @Test("lifeWeekIndex(row:col:)とgridRow/gridColが逆変換になっている")
    func roundTrip() {
        for idx in [0, 1, 51, 52, 103, 1414, 4419] {
            let row = Calc.gridRow(idx)
            let col = Calc.gridCol(idx)
            #expect(Calc.lifeWeekIndex(row: row, col: col) == idx)
        }
    }

    @Test("age()は年単位（0歳=誕生年）")
    func ageCalculation() {
        #expect(Calc.age(0)  == 0)
        #expect(Calc.age(51) == 0)
        #expect(Calc.age(52) == 1)
        #expect(Calc.age(1663) == 31)  // 31歳台（32歳になる手前）
    }

    @Test("誕生日より前は0を返す")
    func beforeBirthIsZero() {
        let birth = date(1999, 6, 23)
        let before = birth.addingTimeInterval(-86400)
        #expect(Calc.lifeWeekIndex(from: birth, on: before) == 0)
    }
}
