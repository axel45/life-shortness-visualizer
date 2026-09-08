import SwiftUI
import UIKit

struct WeekDetailSheet: View {
    let lifeWeekIndex: Int
    let repository: RepositoryProtocol
    var onSave: (() -> Void)? = nil  // Fix 15: callback to refresh parent grid

    @State private var viewModel: WeekDetailViewModel
    @Environment(\.dismiss) private var dismiss

    init(lifeWeekIndex: Int, repository: RepositoryProtocol, onSave: (() -> Void)? = nil) {
        self.lifeWeekIndex = lifeWeekIndex
        self.repository = repository
        self.onSave = onSave
        _viewModel = State(initialValue: WeekDetailViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text(viewModel.dateRange)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(viewModel.age)歳")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
                .padding(.vertical, 16)

                Divider()

                if viewModel.categories.isEmpty {
                    emptyState
                } else {
                    categoryList
                }

                Spacer()
            }
            .navigationTitle("週の記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完了") {
                        dismiss()
                        onSave?()  // Fix 15: notify parent to reload
                    }
                }
            }
        }
        .task { await viewModel.load(lifeWeekIndex: lifeWeekIndex) }
        .alert("エラー", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var categoryList: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(viewModel.categories) { category in
                    CategoryRatingRow(
                        category: category,
                        currentStars: viewModel.stars(for: category),
                        onStarTap: { stars in
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            // Fix 16: optimistic update - set stars immediately on main thread
                            viewModel.setStarsOptimistic(stars, for: category)
                            Task { await viewModel.setStars(stars, for: category) }
                        }
                    )
                }
            }
            .padding(20)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("カテゴリーが未設定です")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("設定から目標カテゴリーを追加してください")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.top, 48)
    }
}

struct CategoryRatingRow: View {
    let category: Category
    let currentStars: Int
    let onStarTap: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(category.name)
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        onStarTap(star == currentStars ? 0 : star)
                    } label: {
                        Image(systemName: star <= currentStars ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundStyle(star <= currentStars ? .yellow : .gray)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                }
                Spacer()
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
