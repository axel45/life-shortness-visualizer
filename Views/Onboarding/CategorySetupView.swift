import SwiftUI

struct CategorySetupView: View {
    let repository: RepositoryProtocol
    let onComplete: () -> Void
    let onSkip: () -> Void

    @State private var categoryNames: [String] = Category.defaultNames.map(\.name)
    @State private var newName: String = ""

    private var activeCount: Int { categoryNames.filter { !$0.isEmpty }.count }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    Text("目標カテゴリーを設定")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .padding(.top, 48)

                    Text("週ごとに評価するカテゴリーを最大5つ設定できます")
                        .font(.subheadline)
                        .foregroundStyle(Color(white: 0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 32)

                List {
                    ForEach(categoryNames.indices, id: \.self) { i in
                        HStack {
                            TextField("カテゴリー名", text: $categoryNames[i])
                                .foregroundStyle(.white)
                            Spacer()
                            Button {
                                categoryNames.remove(at: i)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                        .listRowBackground(Color(white: 0.12))
                    }

                    if activeCount < 5 {
                        HStack {
                            TextField("カテゴリーを追加", text: $newName)
                                .foregroundStyle(.white)
                                .onSubmit { addCategory() }
                            Button(action: addCategory) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.yellow)
                            }
                        }
                        .listRowBackground(Color(white: 0.12))
                    }
                }
                .scrollContentBackground(.hidden)

                VStack(spacing: 12) {
                    Button {
                        Task { await saveAndContinue() }
                    } label: {
                        Text("完了")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(categoryNames.isEmpty ? Color.gray : Color.yellow)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(categoryNames.isEmpty)

                    Button("スキップ", action: onSkip)
                        .font(.subheadline)
                        .foregroundStyle(Color(white: 0.5))
                        .frame(height: 44)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private func addCategory() {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, activeCount < 5 else { return }
        categoryNames.append(trimmed)
        newName = ""
    }

    private func saveAndContinue() async {
        let names = categoryNames.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let toSave = names.isEmpty ? Category.defaultNames.map(\.name) : names

        do {
            for (i, name) in toSave.enumerated() {
                let cat = Category(name: String(name.prefix(20)), order: i + 1)
                try await repository.saveCategory(cat)
            }
            UserDefaults.standard.set(Date(), forKey: UserDefaultsKey.onboardingCompletedAt)
            onComplete()
        } catch {
            print("CategorySetup save error: \(error)")
        }
    }
}
