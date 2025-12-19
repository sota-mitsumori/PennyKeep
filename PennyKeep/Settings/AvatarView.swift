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
        
        // Calculate a stable hash from the initials string
        let hash = stableHash(initials)
        let index = abs(hash) % colors.count
        return colors[index]
    }
    
    // Stable hash function that produces the same result for the same input
    private func stableHash(_ string: String) -> Int {
        var hash = 0
        for char in string.utf8 {
            hash = ((hash << 5) &- hash) &+ Int(char)
        }
        return hash
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
