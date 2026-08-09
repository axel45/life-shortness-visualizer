import SwiftUI
import UIKit

struct RecordView: View {
    let lifeWeekIndex: Int
    let repository: RepositoryProtocol

    @State private var viewModel: WeekDetailViewModel

    init(lifeWeekIndex: Int, repository: RepositoryProtocol) {
        self.lifeWeekIndex = lifeWeekIndex
        self.repository = repository
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
        }
        .task { await viewModel.load(lifeWeekIndex: lifeWeekIndex) }
        .onChange(of: lifeWeekIndex) { _, newIndex in
            Task { await viewModel.load(lifeWeekIndex: newIndex) }
        }
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
