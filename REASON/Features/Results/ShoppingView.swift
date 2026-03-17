import SwiftUI

struct ShoppingView: View {
    let analysis: SpaceAnalysis
    @Binding var selectedBudgetTier: BudgetTier
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            BrandColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

                // Tier picker strip
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(analysis.budgetRecommendations) { rec in
                            let isSelected = selectedBudgetTier == rec.budgetTier
                            Button { selectedBudgetTier = rec.budgetTier } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(rec.budgetTier.displayName)
                                        .font(BrandTypography.label)
                                        .foregroundColor(BrandColor.textSecondary)
                                    Text(rec.estimatedTotalSpend.formatted(.currency(code: "USD")))
                                        .font(BrandTypography.sectionTitle)
                                        .foregroundColor(BrandColor.textPrimary)
                                }
                                .padding(12)
                                .frame(width: 160, height: 80, alignment: .topLeading)
                                .background(isSelected ? BrandColor.surfaceElevated : BrandColor.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            isSelected ? BrandColor.teal : BrandColor.stroke,
                                            lineWidth: isSelected ? 1.5 : 0.5
                                        )
                                )
                            }
                            .buttonStyle(BudgetCardPressStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 16)

                // Full product list
                if analysis.budgetRecommendations.isEmpty {
                    Spacer()
                    Text("No shopping suggestions available for this analysis.")
                        .font(BrandTypography.body)
                        .foregroundColor(BrandColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            let items = analysis.budgetRecommendations
                                .first(where: { $0.budgetTier == selectedBudgetTier })?.items ?? []

                            if items.isEmpty {
                                Text("No items for this tier.")
                                    .font(BrandTypography.body)
                                    .foregroundColor(BrandColor.textSecondary)
                                    .padding(.top, 40)
                            } else {
                                ForEach(items) { item in
                                    RMSCard {
                                        HStack(alignment: .top, spacing: 12) {
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(item.itemTitle)
                                                    .font(BrandTypography.bodyStrong)
                                                    .foregroundColor(BrandColor.textPrimary)
                                                if let price = item.price {
                                                    Text(price.formatted(.currency(code: "USD")))
                                                        .font(BrandTypography.sectionTitle)
                                                        .foregroundColor(BrandColor.gold)
                                                }
                                                Text(item.reasonText)
                                                    .font(BrandTypography.body)
                                                    .foregroundColor(BrandColor.textSecondary)
                                                Text(item.expectedImpact)
                                                    .font(BrandTypography.label)
                                                    .foregroundColor(BrandColor.teal)
                                            }
                                            Spacer()
                                            Button {
                                                UIApplication.shared.open(item.amazonURL)
                                            } label: {
                                                Text("Open")
                                                    .font(BrandTypography.label)
                                                    .foregroundColor(BrandColor.textPrimary)
                                                    .padding(.horizontal, 12)
                                                    .frame(height: 32)
                                                    .background(BrandColor.teal)
                                                    .clipShape(Capsule())
                                            }
                                        }
                                        .padding(16)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var headerBar: some View {
        HStack {
            Text("Shopping Tools")
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
}
