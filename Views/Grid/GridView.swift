import SwiftUI

struct GridView: View {
    @State private var viewModel: GridViewModel
    private let repository: RepositoryProtocol
    var refreshTrigger: Int = 0
    var onWeekSelected: ((Int) -> Void)?

    private let dotSize: CGFloat = 6
    private let dotSpacing: CGFloat = 2

    init(repository: RepositoryProtocol, refreshTrigger: Int = 0, onWeekSelected: ((Int) -> Void)? = nil) {
        self.repository = repository
        self.refreshTrigger = refreshTrigger
        self.onWeekSelected = onWeekSelected
        _viewModel = State(initialValue: GridViewModel(repository: repository))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                if let profile = viewModel.userProfile {
                    selectedWeekDateRange(birthDate: profile.birthDate)
                }

                GeometryReader { geo in
                    let columns = max(1, Int(geo.size.width / (dotSize + dotSpacing)))
                    gridCanvas(columns: columns)
                }
                .padding(.horizontal, 8)
            }

            if viewModel.weekRecordMap.isEmpty {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                emptyStateOverlay
            }

            if viewModel.showWallpaperBanner {
                wallpaperBanner
            }
        }
        .task { await viewModel.loadData() }
        .onChange(of: refreshTrigger) { _, _ in Task { await viewModel.loadData() } }
        .onChange(of: viewModel.selectedLifeWeekIndex) { _, newIndex in
            onWeekSelected?(newIndex)
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

    private func selectedWeekDateRange(birthDate: Date) -> some View {
        let idx = viewModel.selectedLifeWeekIndex
        let start = WeekCalculator.weekStartDate(lifeWeekIndex: idx, birthDate: birthDate)
        let end = WeekCalculator.weekEndDate(lifeWeekIndex: idx, birthDate: birthDate)
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ja_JP")
        fmt.dateFormat = "yyyy年M月d日"
        let startStr = fmt.string(from: start)
        let endFmt = DateFormatter()
        endFmt.locale = Locale(identifier: "ja_JP")
        endFmt.dateFormat = "d日"
        let endStr = endFmt.string(from: end)
        return Text("\(startStr)〜\(endStr)")
            .font(.caption2)
            .foregroundStyle(Color(white: 0.6))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 4)
    }

    private func gridCanvas(columns: Int) -> some View {
        DotGridCanvas(
            rows: Constants.defaultLifeExpectancy,
            columns: columns,
            dotSize: dotSize,
            dotSpacing: dotSpacing,
            currentLifeWeekIndex: viewModel.currentLifeWeekIndex,
            selectedLifeWeekIndex: viewModel.selectedLifeWeekIndex,
            weekRecordMap: viewModel.weekRecordMap,
            centeredLayout: false,
            onTap: { viewModel.selectWeekOnly($0) },
            onSwipe: { viewModel.selectWeekOnly($0) },
            onVerticalSwipe: { viewModel.selectWeekOnly($0) }
        )
    }

    private var emptyStateOverlay: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus.circle")
                .font(.system(size: 32))
                .foregroundStyle(Color.yellow.opacity(0.7))
            Text("「記録」タブで今週の記録を入力しよう")
                .font(.subheadline)
                .foregroundStyle(Color(white: 0.6))
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(Color.black.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 40)
        .padding(.bottom, 48)
    }

    private var wallpaperBanner: some View {
        HStack {
            Text("今週の壁紙がまだ更新されていません")
                .font(.caption)
                .foregroundStyle(.white)
            Spacer()
            Button("今すぐ更新する →") {
                Task { await viewModel.generateWallpaper() }
            }
            .font(.caption.bold())
            .foregroundStyle(.yellow)
            Button {
                viewModel.dismissWallpaperBanner()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(white: 0.15))
        .overlay(alignment: .top) {
            Divider().background(Color.yellow.opacity(0.5))
        }
    }
}
