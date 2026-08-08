import SwiftUI
import Charts

struct StatsSheet: View {
    let repository: RepositoryProtocol
    @State private var viewModel: StatsViewModel

    init(repository: RepositoryProtocol) {
        self.repository = repository
        _viewModel = State(initialValue: StatsViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    lifeConsumedSection
                    Divider()
                    ForEach(viewModel.categorieStats) { stat in
                        CategoryStatCard(stat: stat)
                    }
                }
                .padding(20)
            }
            .navigationTitle("統計")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task { await viewModel.load() }
        .alert("エラー", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var lifeConsumedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("累計記録")
                .font(.headline)
            HStack {
                Text("人生消費率")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.1f%%", viewModel.lifeConsumedPercent))
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
            }
            ProgressView(value: viewModel.lifeConsumedPercent, total: 100)
                .tint(.yellow)
        }
    }
}

struct CategoryStatCard: View {
    let stat: CategoryStat

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(stat.name)
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                    Text("\(stat.streak)週連続")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if stat.weeklyData.isEmpty {
                Text("記録がまだありません")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(height: 80)
            } else {
                Chart(stat.weeklyData, id: \.weekIndex) { data in
                    LineMark(
                        x: .value("週", data.weekIndex),
                        y: .value("評価", data.average)
                    )
                    .foregroundStyle(.yellow)
                }
                .chartYScale(domain: 0...5)
                .frame(height: 80)
            }

            HStack {
                Text("平均")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "★ %.1f", stat.totalAverage))
                    .font(.caption.bold())
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
