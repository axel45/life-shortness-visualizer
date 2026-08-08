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
    @State private var onboardingLifeExpectancy: Int = Constants.defaultLifeExpectancy

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
            BirthDateInputView(repository: repository) { birthDate, lifeExpectancy in
                onboardingBirthDate = birthDate
                onboardingLifeExpectancy = lifeExpectancy
                withAnimation(.easeInOut(duration: 0.4)) { onboardingStep = .gridGeneration }
            }
        case .gridGeneration:
            GridGenerationView(
                birthDate: onboardingBirthDate,
                lifeExpectancy: onboardingLifeExpectancy
            ) {
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

    var body: some View {
        TabView {
            GridView(repository: repository)
                .tabItem {
                    Label("人生カレンダー", systemImage: "circle.grid.3x3.fill")
                }
            StatsSheet(repository: repository)
                .tabItem {
                    Label("統計", systemImage: "chart.line.uptrend.xyaxis")
                }
            SettingsView(repository: repository)
                .tabItem {
                    Label("設定", systemImage: "gearshape")
                }
        }
        .preferredColorScheme(.dark)
    }
}
