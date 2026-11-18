import CadenceCore
import SwiftUI

/// A styled surface panel applying the Blood Moon visual tokens.
public struct CadenceCard<Content: View>: View {
    private let content: Content
    private let cornerRadius: Double

    public init(cornerRadius: Double = RadiusScale.lg, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    public var body: some View {
        content
            .padding(SpacingScale.lg)
            .background(Color.cadenceSurfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.cadenceBorder, lineWidth: 1.0)
            )
    }
}
