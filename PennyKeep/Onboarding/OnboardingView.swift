import SwiftUI

/// First-launch flow: Welcome → Currency → Account.
struct OnboardingView: View {
    @EnvironmentObject var authManager: SupabaseAuthManager
    @EnvironmentObject var appSettings: AppSettings

    /// Called when the user finishes onboarding (signed in or skipped).
    let onFinish: () -> Void

    @State private var path: [Step] = []
    @State private var selectedCurrency = AppSettings.localeDefaultCurrency

    enum Step: Hashable {
        case currency
        case account
    }

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeStep {
                path.append(.currency)
            }
            .navigationDestination(for: Step.self) { step in
                switch step {
                case .currency:
                    CurrencyStep(selectedCurrency: $selectedCurrency) {
                        appSettings.selectedCurrency = selectedCurrency
                        path.append(.account)
                    }
                case .account:
                    AccountStep(onSkip: onFinish)
                }
            }
        }
        .onChange(of: authManager.isSignedIn) { _, signedIn in
            if signedIn { onFinish() }
        }
    }
}

// MARK: - Welcome

private struct WelcomeStep: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 20) {
                AppLogoView(size: 112)
                VStack(spacing: 8) {
                    Text("PennyKeep")
                        .font(.largeTitle.bold())
                    Text("Track your spending.\nJust snap a receipt.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            Spacer()
            Button("Get Started", action: onContinue)
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Currency

private struct CurrencyStep: View {
    @Binding var selectedCurrency: String
    let onContinue: () -> Void

    @State private var searchText = ""

    private var filteredCurrencies: [CurrencyItem] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return currencyItems }
        return currencyItems.filter {
            $0.code.localizedCaseInsensitiveContains(query) || $0.name.localizedCaseInsensitiveContains(query)
        }
    }

    private var selectedItem: CurrencyItem? {
        currencyItems.first { $0.code == selectedCurrency }
    }

    var body: some View {
        List {
            // Keep the current selection visible at the top without scrolling.
            Section {
                if let selectedItem {
                    currencyRow(selectedItem)
                }
            } header: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Choose your currency")
                        .font(.title.bold())
                        .foregroundStyle(.primary)
                    Text("You can change this later in Settings.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .textCase(nil)
                .padding(.bottom, 12)
                .listRowInsets(EdgeInsets())
            }

            Section("All Currencies") {
                ForEach(filteredCurrencies) { currency in
                    currencyRow(currency)
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search currencies")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button("Continue", action: onContinue)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.bar)
        }
    }

    private func currencyRow(_ currency: CurrencyItem) -> some View {
        Button {
            selectedCurrency = currency.code
        } label: {
            HStack {
                Text(currency.code)
                    .font(.body.monospaced().weight(.semibold))
                    .frame(width: 52, alignment: .leading)
                Text(currency.name)
                Spacer()
                if currency.code == selectedCurrency {
                    Image(systemName: "checkmark")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .foregroundStyle(.primary)
            .contentShape(Rectangle())
        }
    }
}

// MARK: - Account

private struct AccountStep: View {
    let onSkip: () -> Void

    @State private var authMode: AuthMode?

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 20) {
                Image(systemName: "arrow.triangle.2.circlepath.icloud")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 96, height: 96)
                    .background(Color.accentColor.opacity(0.12), in: Circle())
                VStack(spacing: 8) {
                    Text("Back up & sync")
                        .font(.title.bold())
                    Text("Create a free account to back up your data and keep it in sync across your devices.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            Spacer()
            VStack(spacing: 12) {
                Button("Create Account") { authMode = .signUp }
                    .buttonStyle(PrimaryButtonStyle())
                Button("Sign In") { authMode = .signIn }
                    .buttonStyle(SecondaryButtonStyle())
                Button("Continue without an account", action: onSkip)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $authMode) { mode in
            AuthView(mode: mode)
        }
    }
}

extension AuthMode: Identifiable {
    var id: Self { self }
}

#Preview {
    OnboardingView(onFinish: {})
        .environmentObject(SupabaseAuthManager())
        .environmentObject(AppSettings())
}
