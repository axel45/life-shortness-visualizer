import SwiftUI

struct BirthDateInputView: View {
    let repository: RepositoryProtocol
    let onComplete: (Date) -> Void

    @State private var birthDate: Date = Calendar.current.date(
        byAdding: .year, value: -30, to: Date()
    ) ?? Date()

    private var remainingWeeks: Int {
        let currentIndex = WeekCalculator.lifeWeekIndex(from: birthDate)
        let totalWeeks = Constants.defaultLifeExpectancy * Constants.weeksPerYear
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

                Spacer().frame(height: 24)

                Text("残り \(remainingWeeks) 週")
                    .font(.subheadline)
                    .foregroundStyle(Color.yellow.opacity(0.8))
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 0.2), value: remainingWeeks)

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
        let profile = UserProfile(birthDate: birthDate, lifeExpectancy: Constants.defaultLifeExpectancy)
        do {
            try await repository.saveUserProfile(profile)
            onComplete(birthDate)
        } catch {
            print("saveUserProfile error: \(error)")
        }
    }
}
