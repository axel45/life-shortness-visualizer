import SwiftUI

struct GridView: View {
    @State private var viewModel: GridViewModel
    private let repository: RepositoryProtocol

    private let columns = Constants.weeksPerYear
    private let dotSize: CGFloat = 6
    private let dotSpacing: CGFloat = 2
    private let stageBarWidth: CGFloat = 24

    init(repository: RepositoryProtocol) {
        self.repository = repository
        _viewModel = State(initialValue: GridViewModel(repository: repository))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            HStack(spacing: 8) {
                LifeStageBarView(
                    lifeStages: viewModel.lifeStages,
                    lifeExpectancy: viewModel.userProfile?.lifeExpectancy ?? 85,
                    width: stageBarWidth,
                    dotSize: dotSize,
                    dotSpacing: dotSpacing
                )
                .onTapGesture {
                    viewModel.isStatsPresented = true
                }

                gridCanvas
            }
            .padding(.horizontal, 12)

            if viewModel.weekRecordMap.isEmpty {
                // Fix 5: semi-transparent scrim behind hint
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                emptyStateOverlay
            }

            if viewModel.showWallpaperBanner {
                wallpaperBanner
            }

            fabButton
        }
        .task { await viewModel.loadData() }
        .alert("エラー", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $viewModel.isWeekDetailPresented) {
            WeekDetailSheet(
                lifeWeekIndex: viewModel.selectedLifeWeekIndex,
                repository: repository,
                onSave: { viewModel.reloadAfterSave() }
            )
        }
        .sheet(isPresented: $viewModel.isStatsPresented) {
            StatsSheet(repository: repository)
        }
    }

    private var gridCanvas: some View {
        DotGridCanvas(
            rows: viewModel.userProfile?.lifeExpectancy ?? 85,
            columns: columns,
            dotSize: dotSize,
            dotSpacing: dotSpacing,
            currentLifeWeekIndex: viewModel.currentLifeWeekIndex,
            selectedLifeWeekIndex: viewModel.selectedLifeWeekIndex,
            weekRecordMap: viewModel.weekRecordMap,
            centeredLayout: false,
            onTap: { viewModel.selectWeekOnly($0) },
            onSwipe: { viewModel.selectWeekOnly($0) }
        )
    }

    private var fabButton: some View {
        // Fix 5: Updated hint text
        Button {
            viewModel.selectCurrentWeek()
        } label: {
            Image(systemName: viewModel.isCurrentWeekRecorded ? "pencil" : "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.black)
                .frame(width: 56, height: 56)
                .background(viewModel.isCurrentWeekRecorded ? Color.white : Color.yellow)
                .clipShape(Circle())
                .animation(.spring(duration: 0.25), value: viewModel.isCurrentWeekRecorded)
        }
        .padding(.bottom, 32)
        .padding(.trailing, 24)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var emptyStateOverlay: some View {
        // Fix 5: Updated text and placed above scrim
        VStack(spacing: 8) {
            Image(systemName: "plus.circle")
                .font(.system(size: 32))
                .foregroundStyle(Color.yellow.opacity(0.7))
            // Fix 5: Changed hint text
            Text("＋ボタンを押して今週の記録を入力しよう")
                .font(.subheadline)
                .foregroundStyle(Color(white: 0.6))
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(Color.black.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 40)
        .padding(.bottom, 112)
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
