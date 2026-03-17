import SwiftUI

struct SettingsView: View {
    @ObservedObject var appModel: AppModel
    @ObservedObject var themeStore: ThemeStore

    @State private var showDeleteConfirm = false
    @State private var showThemeSelector = false

    var body: some View {
        ZStack(alignment: .top) {
            BrandColor.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerBar
                        .padding(.horizontal, 20)
                        .padding(.top, 60)
                        .padding(.bottom, 24)

                    VStack(spacing: 16) {
                        profileCard
                        preferencesCard
                        accountActionsCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 60)
                }
            }
        }
        .sheet(isPresented: $showThemeSelector) {
            ThemeSelectorView()
                .environmentObject(themeStore)
        }
        .alert("Delete Account", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                Task { await appModel.deleteAccount() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your account and all data. This action cannot be undone.")
        }
    }

    // MARK: — Header

    private var headerBar: some View {
        HStack {
            Text("Settings")
                .font(BrandTypography.screenTitle)
                .foregroundColor(BrandColor.textPrimary)
            Spacer()
        }
    }

    // MARK: — Profile Card

    private var profileCard: some View {
        RMSCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(BrandColor.tealMuted)
                        .frame(width: 56, height: 56)
                    Text(initials)
                        .font(BrandTypography.sectionTitle)
                        .foregroundColor(BrandColor.teal)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(appModel.currentUser?.displayName ?? "Guest")
                        .font(BrandTypography.bodyStrong)
                        .foregroundColor(BrandColor.textPrimary)
                    Text(appModel.currentUser?.email ?? "")
                        .font(BrandTypography.label)
                        .foregroundColor(BrandColor.textSecondary)
                }
                Spacer()
            }
            .padding(20)
        }
    }

    private var initials: String {
        let name = appModel.currentUser?.displayName ?? ""
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(1)).uppercased()
    }

    // MARK: — Preferences Card

    private var preferencesCard: some View {
        RMSCard {
            VStack(spacing: 0) {
                // Theme row
                Button {
                    showThemeSelector = true
                } label: {
                    HStack {
                        Image(systemName: "paintpalette")
                            .foregroundColor(BrandColor.teal)
                            .frame(width: 24)
                        Text("Theme")
                            .font(BrandTypography.body)
                            .foregroundColor(BrandColor.textPrimary)
                        Spacer()
                        Text(themeStore.preference.displayName)
                            .font(BrandTypography.label)
                            .foregroundColor(BrandColor.textSecondary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(BrandColor.textTertiary)
                    }
                    .padding(20)
                }
                .buttonStyle(.plain)

                Divider()
                    .background(BrandColor.divider)
                    .padding(.horizontal, 20)

                // Tone row
                HStack {
                    Image(systemName: "waveform")
                        .foregroundColor(BrandColor.gold)
                        .frame(width: 24)
                    Text("Tone")
                        .font(BrandTypography.body)
                        .foregroundColor(BrandColor.textPrimary)
                    Spacer()
                    Text(appModel.currentUser?.preferredTone.capitalized ?? "Warm")
                        .font(BrandTypography.label)
                        .foregroundColor(BrandColor.textSecondary)
                }
                .padding(20)

                Divider()
                    .background(BrandColor.divider)
                    .padding(.horizontal, 20)

                // Saved Projects row
                HStack {
                    Image(systemName: "folder")
                        .foregroundColor(BrandColor.textSecondary)
                        .frame(width: 24)
                    Text("Saved Projects")
                        .font(BrandTypography.body)
                        .foregroundColor(BrandColor.textPrimary)
                    Spacer()
                    Text("\(appModel.projects.count)")
                        .font(BrandTypography.label)
                        .foregroundColor(BrandColor.textSecondary)
                }
                .padding(20)
            }
        }
    }

    // MARK: — Account Actions Card

    private var accountActionsCard: some View {
        RMSCard {
            VStack(spacing: 0) {
                // Sign Out row
                Button {
                    Task { await appModel.signOut() }
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(BrandColor.coral)
                            .frame(width: 24)
                        Text("Sign Out")
                            .font(BrandTypography.body)
                            .foregroundColor(BrandColor.coral)
                        Spacer()
                    }
                    .padding(20)
                }
                .buttonStyle(.plain)

                Divider()
                    .background(BrandColor.divider)
                    .padding(.horizontal, 20)

                // Delete Account row
                Button {
                    showDeleteConfirm = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(BrandColor.coral.opacity(0.7))
                            .frame(width: 24)
                        Text("Delete Account")
                            .font(BrandTypography.body)
                            .foregroundColor(BrandColor.coral.opacity(0.7))
                        Spacer()
                    }
                    .padding(20)
                }
                .buttonStyle(.plain)

                Divider()
                    .background(BrandColor.divider)
                    .padding(.horizontal, 20)

                // App version row
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(BrandColor.textTertiary)
                        .frame(width: 24)
                    Text("Version")
                        .font(BrandTypography.body)
                        .foregroundColor(BrandColor.textSecondary)
                    Spacer()
                    Text(appVersion)
                        .font(BrandTypography.label)
                        .foregroundColor(BrandColor.textTertiary)
                }
                .padding(20)
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }
}

// MARK: — Theme Selector

struct ThemeSelectorView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    var body: some View {
        ZStack {
            BrandColor.background.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text("Theme")
                        .font(BrandTypography.screenTitle)
                        .foregroundColor(BrandColor.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 24)

                RMSCard {
                    VStack(spacing: 0) {
                        ForEach(Array(AppThemePreference.allCases.enumerated()), id: \.element.id) { index, preference in
                            if index > 0 {
                                Divider()
                                    .background(BrandColor.divider)
                                    .padding(.horizontal, 20)
                            }
                            Button {
                                themeStore.preference = preference
                            } label: {
                                HStack {
                                    Text(preference.displayName)
                                        .font(BrandTypography.body)
                                        .foregroundColor(BrandColor.textPrimary)
                                    Spacer()
                                    if themeStore.preference == preference {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(BrandColor.teal)
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                }
                                .padding(20)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)

                Spacer()
            }
        }
    }
}
