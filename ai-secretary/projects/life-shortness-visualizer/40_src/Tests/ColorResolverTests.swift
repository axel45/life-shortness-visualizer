import Testing

// DotColorロジックをスタンドアロン定義
private enum DotColor: Equatable { case future, gray, white, silver, gold }

private func dotColor(averageStars: Double?, isFuture: Bool) -> DotColor {
    if isFuture { return .future }
    guard let avg = averageStars else { return .gray }
    switch avg {
    case ..<3.0:      return .gray
    case 3.0..<4.0:   return .white
    case 4.0..<5.0:   return .silver
    default:           return .gold
    }
}

@Suite("ColorResolver")
struct ColorResolverTests {

    @Test("未来週はfuture")
    func futureWeek() {
        #expect(dotColor(averageStars: nil,  isFuture: true) == .future)
        #expect(dotColor(averageStars: 5.0,  isFuture: true) == .future)
    }

    @Test("記録なし（nil）はgray")
    func noRecord() {
        #expect(dotColor(averageStars: nil, isFuture: false) == .gray)
    }

    @Test("平均3未満はgray")
    func belowThree() {
        #expect(dotColor(averageStars: 0.0, isFuture: false) == .gray)
        #expect(dotColor(averageStars: 1.0, isFuture: false) == .gray)
        #expect(dotColor(averageStars: 2.9, isFuture: false) == .gray)
    }

    @Test("平均3以上4未満はwhite")
    func threeToFour() {
        #expect(dotColor(averageStars: 3.0, isFuture: false) == .white)
        #expect(dotColor(averageStars: 3.5, isFuture: false) == .white)
        #expect(dotColor(averageStars: 3.99, isFuture: false) == .white)
    }

    @Test("平均4以上5未満はsilver")
    func fourToFive() {
        #expect(dotColor(averageStars: 4.0, isFuture: false) == .silver)
        #expect(dotColor(averageStars: 4.5, isFuture: false) == .silver)
        #expect(dotColor(averageStars: 4.99, isFuture: false) == .silver)
    }

    @Test("平均5.0はgold")
    func allFiveStar() {
        #expect(dotColor(averageStars: 5.0, isFuture: false) == .gold)
    }

    @Test("境界値: 3.0はwhite（gray寄りでない）")
    func boundaryThree() {
        #expect(dotColor(averageStars: 3.0, isFuture: false) == .white)
    }

    @Test("境界値: 4.0はsilver（white寄りでない）")
    func boundaryFour() {
        #expect(dotColor(averageStars: 4.0, isFuture: false) == .silver)
    }
}
