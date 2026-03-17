import SwiftUI

struct VisualizationView: View {
    let analysis: SpaceAnalysis
    let project: SpaceProject
    let visualizationService: VisualizationService
    @Environment(\.dismiss) private var dismiss

    @State private var concept: VisualizationConcept?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            BrandColor.background.ignoresSafeArea()
            VStack(spacing: 0) {
                headerBar
                content
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await loadConcept()
        }
    }

    private var headerBar: some View {
        HStack {
            Text("AI Concept")
                .font(BrandTypography.screenTitle)
                .foregroundColor(BrandColor.textPrimary)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(BrandColor.textSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            Spacer()
            VStack(spacing: 16) {
                ProgressView()
                    .tint(BrandColor.teal)
                Text("Generating your AI concept…")
                    .font(BrandTypography.body)
                    .foregroundColor(BrandColor.textSecondary)
            }
            Spacer()
        } else if let error = errorMessage {
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 40))
                    .foregroundColor(BrandColor.coral)
                Text(error)
                    .font(BrandTypography.body)
                    .foregroundColor(BrandColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                GhostButton(title: "Try Again") {
                    Task { await loadConcept() }
                }
            }
            Spacer()
        } else if let concept = concept {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if let url = concept.generatedImageURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 300)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                            case .failure:
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(BrandColor.surfaceElevated)
                                    .frame(height: 300)
                                    .overlay(
                                        VStack(spacing: 8) {
                                            Image(systemName: "photo")
                                                .font(.system(size: 32))
                                                .foregroundColor(BrandColor.textTertiary)
                                            Text("Image unavailable")
                                                .font(BrandTypography.label)
                                                .foregroundColor(BrandColor.textTertiary)
                                        }
                                    )
                            case .empty:
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(BrandColor.surfaceElevated)
                                    .frame(height: 300)
                                    .overlay(ProgressView().tint(BrandColor.teal))
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }

                    RMSCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                TagChip(title: "Score \(concept.projectedImprovedScore)", accent: BrandColor.teal)
                            }
                            Text(concept.conceptCaption)
                                .font(BrandTypography.sectionTitle)
                                .foregroundColor(BrandColor.textPrimary)
                            Text(concept.promptSummary)
                                .font(BrandTypography.body)
                                .foregroundColor(BrandColor.textSecondary)
                            if !concept.whatImproved.isEmpty {
                                Divider().background(BrandColor.divider)
                                Text("What Improved")
                                    .font(BrandTypography.bodyStrong)
                                    .foregroundColor(BrandColor.textPrimary)
                                ForEach(concept.whatImproved, id: \.self) { change in
                                    HStack(alignment: .top, spacing: 8) {
                                        Circle()
                                            .fill(BrandColor.teal)
                                            .frame(width: 4, height: 4)
                                            .padding(.top, 6)
                                        Text(change)
                                            .font(BrandTypography.body)
                                            .foregroundColor(BrandColor.textSecondary)
                                    }
                                }
                            }
                            if !concept.stillNeedsWork.isEmpty {
                                Divider().background(BrandColor.divider)
                                Text("Still Needs Work")
                                    .font(BrandTypography.bodyStrong)
                                    .foregroundColor(BrandColor.textPrimary)
                                ForEach(concept.stillNeedsWork, id: \.self) { item in
                                    HStack(alignment: .top, spacing: 8) {
                                        Circle()
                                            .fill(BrandColor.coral)
                                            .frame(width: 4, height: 4)
                                            .padding(.top, 6)
                                        Text(item)
                                            .font(BrandTypography.body)
                                            .foregroundColor(BrandColor.textSecondary)
                                    }
                                }
                            }
                        }
                        .padding(20)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
    }

    private func loadConcept() async {
        guard !isLoading, concept == nil else { return }
        isLoading = true
        errorMessage = nil
        do {
            concept = try await visualizationService.generateVisualization(
                for: project, analysis: analysis
            )
        } catch {
            errorMessage = "Could not generate concept. Please try again."
        }
        isLoading = false
    }
}
