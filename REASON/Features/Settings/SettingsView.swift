import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appModel: AppModel
    @EnvironmentObject private var themeStore: ThemeStore

    var body: some View {
        List {
            Section("Account") {
                VStack(alignment: .leading, spacing: 6) {
                    Text(appModel.currentUser?.displayName ?? "Guest")
                        .font(BrandTypography.bodyStrong)
                    Text(appModel.currentUser?.email ?? "Not signed in")
                        .font(BrandTypography.caption)
                        .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                }
                NavigationLink("Theme") {
                    ThemeSelectorView()
                }
                Button("Sign Out") {
                    Task {
                        await appModel.signOut()
                    }
                }
                Button("Delete Account Scaffold", role: .destructive) {
                    Task {
                        await appModel.deleteAccount()
                    }
                }
            }

            Section("Preferences") {
                LabeledContent("Theme", value: themeStore.preference.displayName)
                LabeledContent("Saved Projects", value: "\(appModel.projects.count)")
                LabeledContent("Tone", value: appModel.currentUser?.preferredTone.capitalized ?? "Warm")
            }

            Section("Scaffolding Notes") {
                Text("Supabase auth, storage syncing, and live AI endpoint parsing are structured in the codebase and ready for the final production integration pass.")
                    .font(BrandTypography.caption)
                    .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Settings")
    }
}

struct ThemeSelectorView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    var body: some View {
        List {
            ForEach(AppThemePreference.allCases, id: \.id) { preference in
                Button {
                    themeStore.preference = preference
                } label: {
                    HStack {
                        Text(preference.displayName)
                        Spacer()
                        if themeStore.preference == preference {
                            Image(systemName: "checkmark")
                                .foregroundStyle(BrandColor.teal)
                        }
                    }
                }
                .foregroundStyle(.primary)
            }
        }
        .navigationTitle("Theme")
    }
}
