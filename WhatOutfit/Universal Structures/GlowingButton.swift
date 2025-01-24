struct GlowingButton: View {
    @State private var glowPosition: CGFloat = 0
    let text: String
    let action: () -> Void
    var showArrow: Bool = true
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .frame(maxWidth: .infinity)
                if showArrow {
                    Image(systemName: "arrow.right")
                }
            }
            .padding()
            .background(Color.black)
            .foregroundColor(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.white, lineWidth: 1)
            )
            .overlay(
                GeometryReader { geometry in
                    let path = Path { path in
                        path.addRoundedRect(in: CGRect(x: 0, y: 0, width: geometry.size.width, height: geometry.size.height), cornerRadius: 25)
                    }
                    
                    path.trim(from: max(glowPosition - 0.2, 0), to: min(glowPosition + 0.2, 1))
                        .stroke(
                            Color.white,
                            style: StrokeStyle(
                                lineWidth: 2,
                                lineCap: .round
                            )
                        )
                        .shadow(color: .white, radius: 4)
                }
            )
            .cornerRadius(25)
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                glowPosition = 1.0
            }
        }
    }
}

// Usage:
GlowingButton(text: "Continue", action: validateAndLogin)
    .frame(maxWidth: .infinity)
    .padding(.horizontal, 24)

// Without arrow:
GlowingButton(text: "Submit", action: submitForm, showArrow: false)
    .frame(maxWidth: .infinity)
    .padding(.horizontal, 24)