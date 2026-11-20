import SwiftUI

// MARK: - Button styles

/// Filled accent-colored button used for the main action on a screen.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.4)
    }
}

/// Tinted button for a secondary action next to a primary one.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.accentColor)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

// MARK: - App logo

struct AppLogoView: View {
    var size: CGFloat = 80

    var body: some View {
        Image("AppLogo")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.225, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }
}

// MARK: - Form field

/// Labeled input container with an optional validation message underneath.
struct AuthField<Content: View>: View {
    let label: String
    var message: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            content
                .padding(.horizontal, 14)
                .frame(height: 50)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(message == nil ? Color.clear : Color.red.opacity(0.6), lineWidth: 1)
                )

            if let message {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: message)
    }
}

// MARK: - Validation

enum AuthValidation {
    static let minimumPasswordLength = 6

    static func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }
}

// MARK: - Currency

extension AppSettings {
    /// Currency for the device's region, falling back to USD when unsupported.
    static var localeDefaultCurrency: String {
        if let code = Locale.current.currency?.identifier,
           currencyItems.contains(where: { $0.code == code }) {
            return code
        }
        return "USD"
    }
}
