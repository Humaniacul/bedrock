import CoreGraphics

// Spacing & corner-radius scale (§6). One ladder, used everywhere.

extension Theme {
    enum Spacing {
        static let xs: CGFloat   = 4
        static let sm: CGFloat   = 8
        static let md: CGFloat   = 12
        static let lg: CGFloat   = 16
        static let xl: CGFloat   = 24
        static let xxl: CGFloat  = 32
        static let xxxl: CGFloat = 48
    }

    enum Radius {
        static let sm: CGFloat   = 10
        static let md: CGFloat   = 16
        static let lg: CGFloat   = 22
        static let xl: CGFloat   = 28
        static let pill: CGFloat = 999
    }
}
