import Testing

private enum DotColor: Equatable { case future, unrecorded, normal, sunshine }

private func dotColor(averageStars: Double?, isFuture: Bool) -> DotColor {
    if isFuture { return .future }
    guard let avg = averageStars else { return .unrecorded }
    return avg > 4.5 ? .sunshine : .normal
}

@Suite("ColorResolver")
struct ColorResolverTests {

    @Test("未来週はfuture")
    func futureWeek() {
        #expect(dotColor(averageStars: nil, isFuture: true) == .future)
        #expect(dotColor(averageStars: 5.0, isFuture: true) == .future)
    }

    @Test("記録なし（nil）はunrecorded")
    func noRecord() {
        #expect(dotColor(averageStars: nil, isFuture: false) == .unrecorded)
    }

    @Test("平均4.5以下はnormal")
    func normalRange() {
        #expect(dotColor(averageStars: 1.0, isFuture: false) == .normal)
        #expect(dotColor(averageStars: 3.0, isFuture: false) == .normal)
        #expect(dotColor(averageStars: 4.5, isFuture: false) == .normal)
    }

    @Test("平均4.5超はsunshine")
    func sunshineRange() {
        #expect(dotColor(averageStars: 4.51, isFuture: false) == .sunshine)
        #expect(dotColor(averageStars: 4.75, isFuture: false) == .sunshine)
        #expect(dotColor(averageStars: 5.0,  isFuture: false) == .sunshine)
    }

    @Test("境界値: 4.5はnormal（sunshineでない）")
    func boundaryFourPointFive() {
        #expect(dotColor(averageStars: 4.5, isFuture: false) == .normal)
    }

    @Test("境界値: 4.5超の最小値はsunshine")
    func boundaryJustAbove() {
        #expect(dotColor(averageStars: 4.500001, isFuture: false) == .sunshine)
    }
}
