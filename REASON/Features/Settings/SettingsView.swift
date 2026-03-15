import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appModel: AppModel
    @EnvironmentObject private var themeStore: ThemeStore

    var body: some View {
        List {
            Section("Account") {
                VStack(alignment: .leading, spacing: 6) {
                    Text(appModel.currentUser?.displayName ?? "Not signed in")
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
                Button("Delete Account", role: .destructive) {
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

            Section("Live Services") {
                Text("Auth, analysis, shopping suggestions, and concept previews now use live providers. Full project detail is still cached on this device while cloud sync expands.")
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
