import SwiftUI

struct BirthDateInputView: View {
    let repository: RepositoryProtocol
    let onComplete: (Date, Int) -> Void

    @State private var birthDate: Date = Calendar.current.date(
        byAdding: .year, value: -30, to: Date()
    ) ?? Date()
    @State private var lifeExpectancy: Int = Constants.defaultLifeExpectancy

    private var remainingWeeks: Int {
        let currentIndex = WeekCalculator.lifeWeekIndex(from: birthDate)
        let totalWeeks = lifeExpectancy * Constants.weeksPerYear
        return max(0, totalWeeks - currentIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 8) {
                    Text("あなたについて教えてください")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    Text("人生グリッドの基準となります")
                        .font(.subheadline)
                        .foregroundStyle(Color(white: 0.5))
                }

                Spacer().frame(height: 36)

                // 生年月日
                VStack(spacing: 8) {
                    sectionLabel("生年月日")

                    DatePicker(
                        "",
                        selection: $birthDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .frame(maxWidth: .infinity)
                }

                Spacer().frame(height: 32)

                // 想定寿命
                VStack(spacing: 16) {
                    sectionLabel("何歳まで生きると思いますか？")

                    HStack(spacing: 32) {
                        Button {
                            if lifeExpectancy > 60 { lifeExpectancy -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(lifeExpectancy > 60 ? Color.yellow : Color(white: 0.3))
                        }

                        VStack(spacing: 4) {
                            Text("\(lifeExpectancy)歳")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .monospacedDigit()
                                .contentTransition(.numericText())
                                .animation(.spring(duration: 0.2), value: lifeExpectancy)
                        }

                        Button {
                            if lifeExpectancy < 120 { lifeExpectancy += 1 }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(lifeExpectancy < 120 ? Color.yellow : Color(white: 0.3))
                        }
                    }

                    Text("残り \(remainingWeeks.formatted()) 週")
                        .font(.subheadline)
                        .foregroundStyle(Color.yellow.opacity(0.8))
                        .contentTransition(.numericText())
                        .animation(.spring(duration: 0.2), value: remainingWeeks)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
                .background(Color(white: 0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)

                Spacer()

                Button {
                    Task { await saveAndContinue() }
                } label: {
                    Text("次へ")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.yellow)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(Color(white: 0.5))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
    }

    private func saveAndContinue() async {
        let profile = UserProfile(birthDate: birthDate, lifeExpectancy: lifeExpectancy)
        do {
            try await repository.saveUserProfile(profile)
            onComplete(birthDate, lifeExpectancy)
        } catch {
            print("saveUserProfile error: \(error)")
        }
    }
}
