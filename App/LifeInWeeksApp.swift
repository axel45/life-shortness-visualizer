import SwiftUI
import SwiftData

@main
struct LifeInWeeksApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(
                for: UserProfile.self, LifeStage.self, Category.self, WeekRecord.self, CategoryRating.self,
                configurations: ModelConfiguration(cloudKitDatabase: .automatic)
            )
        } catch {
            fatalError("ModelContainer init failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(modelContainer: modelContainer)
        }
        .modelContainer(modelContainer)
    }
}

struct RootView: View {
    let modelContainer: ModelContainer
    @State private var isOnboardingComplete = UserDefaults.standard.bool(forKey: UserDefaultsKey.onboardingCompleted)
    @State private var onboardingStep: OnboardingStep = .splash
    @State private var onboardingBirthDate: Date = Date()

    private var repository: RepositoryProtocol {
        SwiftDataRepository(modelContext: modelContainer.mainContext)
    }

    var body: some View {
        if isOnboardingComplete {
            MainTabView(repository: repository)
        } else {
            onboardingFlow
        }
    }

    @ViewBuilder
    private var onboardingFlow: some View {
        switch onboardingStep {
        case .splash:
            SplashView {
                withAnimation(.easeInOut(duration: 0.4)) { onboardingStep = .birthDate }
            }
        case .birthDate:
            BirthDateInputView(repository: repository) { birthDate in
                onboardingBirthDate = birthDate
                withAnimation(.easeInOut(duration: 0.4)) { onboardingStep = .gridGeneration }
            }
        case .gridGeneration:
            GridGenerationView(birthDate: onboardingBirthDate) {
                withAnimation(.easeInOut(duration: 0.4)) { onboardingStep = .wallpaperGuide }
            }
        case .categorySetup:
            CategorySetupView(
                repository: repository,
                onComplete: { completeOnboarding() },
                onSkip: { completeOnboarding() }
            )
        case .wallpaperGuide:
            WallpaperGuideView(
                onComplete: { withAnimation { onboardingStep = .categorySetup } },
                onSkip: { withAnimation { onboardingStep = .categorySetup } }
            )
        }
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: UserDefaultsKey.onboardingCompleted)
        withAnimation { isOnboardingComplete = true }
    }
}

enum OnboardingStep {
    case splash, birthDate, gridGeneration, categorySetup, wallpaperGuide
}

struct MainTabView: View {
    let repository: RepositoryProtocol
    @State private var selectedWeekForRecord: Int = 0
    @State private var selectedTab: Int = 0
    @State private var isRecordSheetPresented = false

    var body: some View {
        TabView(selection: $selectedTab) {
            GridView(repository: repository, onWeekSelected: { selectedWeekForRecord = $0 })
                .tabItem { Label("人生カレンダー", systemImage: "circle.grid.3x3.fill") }
                .tag(0)
            Color.clear
                .tabItem { Label("記録", systemImage: "pencil.circle.fill") }
                .tag(1)
            StatsSheet(repository: repository)
                .tabItem { Label("統計", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(2)
            SettingsView(repository: repository)
                .tabItem { Label("設定", systemImage: "gearshape") }
                .tag(3)
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == 1 {
                selectedTab = 0  // stay on calendar tab; show sheet instead
                isRecordSheetPresented = true
            }
        }
        .sheet(isPresented: $isRecordSheetPresented) {
            WeekDetailSheet(lifeWeekIndex: selectedWeekForRecord, repository: repository)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .preferredColorScheme(.dark)
    }
}
