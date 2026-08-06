import SwiftUI
import UserNotifications

struct SettingsView: View {
    let repository: RepositoryProtocol
    @State private var userProfile: UserProfile?
    @State private var lifeStages: [LifeStage] = []
    @State private var categories: [Category] = []
    @State private var notificationsEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKey.notificationsEnabled)
    @State private var showDeleteConfirm = false
    @State private var showWallpaperGuide = false
    @State private var lifeStageErrorMessage: String? = nil
    @State private var editingStage: LifeStage? = nil

    var body: some View {
        NavigationStack {
            List {
                profileSection
                lifeStagesSection
                categoriesSection
                notificationSection
                wallpaperSection
                dangerSection
            }
            .navigationTitle("設定")
            .alert("すべてのデータを削除", isPresented: $showDeleteConfirm) {
                Button("削除する", role: .destructive) {
                    Task { await deleteAll() }
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("この操作は元に戻せません。すべての記録・設定が削除されます。")
            }
            .sheet(isPresented: $showWallpaperGuide) {
                WallpaperGuideView(onComplete: { showWallpaperGuide = false }, onSkip: { showWallpaperGuide = false })
            }
            .sheet(item: $editingStage) { stage in
                LifeStageEditSheet(
                    stage: stage,
                    otherStages: lifeStages.filter { $0.id != stage.id },
                    onSave: { updated in
                        Task {
                            try? await repository.saveLifeStage(updated)
                            lifeStages = (try? await repository.fetchLifeStages()) ?? []
                        }
                    },
                    onDelete: { toDelete in
                        Task {
                            try? await repository.deleteLifeStage(toDelete)
                            lifeStages = (try? await repository.fetchLifeStages()) ?? []
                        }
                    }
                )
            }
        }
        .task { await loadData() }
    }

    private var profileSection: some View {
        Section("プロフィール") {
            if let profile = userProfile {
                LabeledContent("生年月日", value: formattedDate(profile.birthDate))
                HStack {
                    Text("想定寿命")
                    Spacer()
                    Stepper("\(profile.lifeExpectancy)歳", value: Binding(
                        get: { profile.lifeExpectancy },
                        set: { newVal in
                            profile.lifeExpectancy = newVal
                            Task { try? await repository.saveUserProfile(profile) }
                        }
                    ), in: 50...120)
                }
            }
        }
    }

    private var lifeStagesSection: some View {
        Section("ライフステージ") {
            if let error = lifeStageErrorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.orange)
            }
            ForEach(lifeStages) { stage in
                Button {
                    editingStage = stage
                } label: {
                    HStack {
                        Circle()
                            .fill(Color(hex: stage.colorHex))
                            .frame(width: 12, height: 12)
                        Text(stage.name)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("\(stage.startAge)〜\(stage.endAge)歳")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .onDelete { indexSet in
                Task {
                    for i in indexSet {
                        try? await repository.deleteLifeStage(lifeStages[i])
                    }
                    lifeStages = (try? await repository.fetchLifeStages()) ?? []
                }
            }
        }
    }

    private func validateLifeStage(name: String, startAge: Int, endAge: Int) -> String? {
        if name.trimmingCharacters(in: .whitespaces).isEmpty { return "ステージ名を入力してください" }
        if name.count > 20 { return "ステージ名は20文字以内で入力してください" }
        if startAge < 0 || startAge > 84 { return "開始年齢は0〜84歳で入力してください" }
        if endAge <= startAge { return "終了年齢は開始年齢より大きくしてください" }
        let overlap = lifeStages.first { s in s.startAge < endAge && startAge < s.endAge }
        if let overlap { return "「\(overlap.name)」と年齢が重複しています" }
        return nil
    }

    private var categoriesSection: some View {
        Section("カテゴリー（最大5個）") {
            ForEach(categories) { category in
                Text(category.name)
            }
            .onDelete { indexSet in
                Task {
                    for i in indexSet {
                        try? await repository.deleteCategory(categories[i])
                    }
                    categories = (try? await repository.fetchCategories()) ?? []
                }
            }
        }
    }

    private var notificationSection: some View {
        Section("通知") {
            Toggle("週次リマインダー", isOn: $notificationsEnabled)
                .onChange(of: notificationsEnabled) { _, enabled in
                    UserDefaults.standard.set(enabled, forKey: UserDefaultsKey.notificationsEnabled)
                    if enabled {
                        requestNotificationPermission()
                    } else {
                        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                    }
                }
            if notificationsEnabled {
                Text("毎週日曜日 20:00 に通知します")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("通知設定を開く") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.subheadline)
            }
        }
    }

    private var wallpaperSection: some View {
        Section("壁紙") {
            Button("壁紙設定ガイドを見る") {
                showWallpaperGuide = true
            }
            Text("オフラインでも動作します")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var dangerSection: some View {
        Section {
            Button("すべてのデータを削除", role: .destructive) {
                showDeleteConfirm = true
            }
        }
    }

    private func loadData() async {
        userProfile = try? await repository.fetchUserProfile()
        lifeStages = (try? await repository.fetchLifeStages()) ?? []
        categories = (try? await repository.fetchCategories()) ?? []
    }

    private func deleteAll() async {
        try? await repository.deleteAllData()
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateStyle = .long
        return f.string(from: date)
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else {
                DispatchQueue.main.async {
                    notificationsEnabled = false
                    UserDefaults.standard.set(false, forKey: UserDefaultsKey.notificationsEnabled)
                }
                return
            }
            scheduleWeeklyNotification()
        }
    }

    private func scheduleWeeklyNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Life in Weeks"
        content.body = "今週の記録がまだ未入力です。1分で振り返りましょう"
        content.sound = .default

        var components = DateComponents()
        components.weekday = 1  // Sunday
        components.hour = 20
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly-reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

struct LifeStageEditSheet: View {
    let stage: LifeStage
    let otherStages: [LifeStage]
    let onSave: (LifeStage) -> Void
    let onDelete: (LifeStage) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var startAge: Int
    @State private var endAge: Int
    @State private var color: Color
    @State private var errorMessage: String? = nil

    init(stage: LifeStage, otherStages: [LifeStage], onSave: @escaping (LifeStage) -> Void, onDelete: @escaping (LifeStage) -> Void) {
        self.stage = stage
        self.otherStages = otherStages
        self.onSave = onSave
        self.onDelete = onDelete
        _name = State(initialValue: stage.name)
        _startAge = State(initialValue: stage.startAge)
        _endAge = State(initialValue: stage.endAge)
        _color = State(initialValue: Color(hex: stage.colorHex))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("ステージ名") {
                    TextField("名前（最大20文字）", text: $name)
                }
                Section("年齢") {
                    Stepper("開始: \(startAge)歳", value: $startAge, in: 0...84)
                    Stepper("終了: \(endAge)歳", value: $endAge, in: (startAge + 1)...120)
                        .onChange(of: startAge) { _, newStart in
                            if endAge <= newStart { endAge = newStart + 1 }
                        }
                }
                Section("カラー") {
                    ColorPicker("色を選択", selection: $color, supportsOpacity: false)
                }
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .navigationTitle("ライフステージ編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") { saveStage() }
                        .bold()
                }
            }
        }
    }

    private func saveStage() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            errorMessage = "ステージ名を入力してください"
            return
        }
        if trimmed.count > Constants.maxLifeStageName {
            errorMessage = "ステージ名は\(Constants.maxLifeStageName)文字以内で入力してください"
            return
        }
        if endAge <= startAge {
            errorMessage = "終了年齢は開始年齢より大きくしてください"
            return
        }
        if let overlap = otherStages.first(where: { $0.startAge < endAge && startAge < $0.endAge }) {
            errorMessage = "「\(overlap.name)」と年齢が重複しています"
            return
        }
        stage.name = trimmed
        stage.startAge = startAge
        stage.endAge = endAge
        stage.colorHex = color.toHex()
        stage.updatedAt = Date()
        onSave(stage)
        dismiss()
    }
}
