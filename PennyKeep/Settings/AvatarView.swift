import SwiftUI

struct AvatarView: View {
    let name: PersonNameComponents?
    let email: String?
    let size: CGFloat
    
    init(name: PersonNameComponents?, email: String?, size: CGFloat = 50) {
        self.name = name
        self.email = email
        self.size = size
    }
    
    private var initials: String {
        if let name = name {
            let givenInitial = name.givenName?.prefix(1).uppercased() ?? ""
            let familyInitial = name.familyName?.prefix(1).uppercased() ?? ""
            if !givenInitial.isEmpty || !familyInitial.isEmpty {
                return givenInitial + familyInitial
            }
        }
        
        // Fallback to email initial if name is not available
        if let email = email, let firstChar = email.prefix(1).uppercased().first {
            return String(firstChar)
        }
        
        return "?"
    }
    
    private var backgroundColor: Color {
        // Generate a consistent color based on initials
        let colors: [Color] = [
            .blue, .green, .orange, .purple, .pink, .red, .teal, .indigo
        ]
        
        let hash = initials.hashValue
        let index = abs(hash) % colors.count
        return colors[index]
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: size, height: size)
            
            Text(initials)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

struct AvatarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AvatarView(
                name: PersonNameComponents(givenName: "John", familyName: "Doe"),
                email: "john.doe@example.com",
                size: 50
            )
            
            AvatarView(
                name: PersonNameComponents(givenName: "Jane", familyName: "Smith"),
                email: nil,
                size: 60
            )
            
            AvatarView(
                name: nil,
                email: "user@example.com",
                size: 40
            )
        }
        .padding()
    }
}
