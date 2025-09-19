import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "AccentColor" asset catalog color resource.
    static let accent = DeveloperToolsSupport.ColorResource(name: "AccentColor", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "LaunchImage" asset catalog image resource.
    static let launch = DeveloperToolsSupport.ImageResource(name: "LaunchImage", bundle: resourceBundle)

    /// The "donatu" asset catalog image resource.
    static let donatu = DeveloperToolsSupport.ImageResource(name: "donatu", bundle: resourceBundle)

    /// The "portal_card_1" asset catalog image resource.
    static let portalCard1 = DeveloperToolsSupport.ImageResource(name: "portal_card_1", bundle: resourceBundle)

    /// The "portal_card_2" asset catalog image resource.
    static let portalCard2 = DeveloperToolsSupport.ImageResource(name: "portal_card_2", bundle: resourceBundle)

    /// The "portal_card_3" asset catalog image resource.
    static let portalCard3 = DeveloperToolsSupport.ImageResource(name: "portal_card_3", bundle: resourceBundle)

    /// The "portal_card_4" asset catalog image resource.
    static let portalCard4 = DeveloperToolsSupport.ImageResource(name: "portal_card_4", bundle: resourceBundle)

    /// The "portal_card_5" asset catalog image resource.
    static let portalCard5 = DeveloperToolsSupport.ImageResource(name: "portal_card_5", bundle: resourceBundle)

    /// The "portal_card_6" asset catalog image resource.
    static let portalCard6 = DeveloperToolsSupport.ImageResource(name: "portal_card_6", bundle: resourceBundle)

    /// The "portal_slide_1" asset catalog image resource.
    static let portalSlide1 = DeveloperToolsSupport.ImageResource(name: "portal_slide_1", bundle: resourceBundle)

    /// The "portal_slide_2" asset catalog image resource.
    static let portalSlide2 = DeveloperToolsSupport.ImageResource(name: "portal_slide_2", bundle: resourceBundle)

    /// The "portal_slide_3" asset catalog image resource.
    static let portalSlide3 = DeveloperToolsSupport.ImageResource(name: "portal_slide_3", bundle: resourceBundle)

    /// The "saba" asset catalog image resource.
    static let saba = DeveloperToolsSupport.ImageResource(name: "saba", bundle: resourceBundle)

    /// The "sweet" asset catalog image resource.
    static let sweet = DeveloperToolsSupport.ImageResource(name: "sweet", bundle: resourceBundle)

    /// The "tyuka" asset catalog image resource.
    static let tyuka = DeveloperToolsSupport.ImageResource(name: "tyuka", bundle: resourceBundle)

    /// The "washoku" asset catalog image resource.
    static let washoku = DeveloperToolsSupport.ImageResource(name: "washoku", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// The "AccentColor" asset catalog color.
    static var accent: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .accent)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// The "AccentColor" asset catalog color.
    static var accent: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .accent)
#else
        .init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    /// The "AccentColor" asset catalog color.
    static var accent: SwiftUI.Color { .init(.accent) }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    /// The "AccentColor" asset catalog color.
    static var accent: SwiftUI.Color { .init(.accent) }

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "LaunchImage" asset catalog image.
    static var launch: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .launch)
#else
        .init()
#endif
    }

    /// The "donatu" asset catalog image.
    static var donatu: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .donatu)
#else
        .init()
#endif
    }

    /// The "portal_card_1" asset catalog image.
    static var portalCard1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .portalCard1)
#else
        .init()
#endif
    }

    /// The "portal_card_2" asset catalog image.
    static var portalCard2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .portalCard2)
#else
        .init()
#endif
    }

    /// The "portal_card_3" asset catalog image.
    static var portalCard3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .portalCard3)
#else
        .init()
#endif
    }

    /// The "portal_card_4" asset catalog image.
    static var portalCard4: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .portalCard4)
#else
        .init()
#endif
    }

    /// The "portal_card_5" asset catalog image.
    static var portalCard5: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .portalCard5)
#else
        .init()
#endif
    }

    /// The "portal_card_6" asset catalog image.
    static var portalCard6: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .portalCard6)
#else
        .init()
#endif
    }

    /// The "portal_slide_1" asset catalog image.
    static var portalSlide1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .portalSlide1)
#else
        .init()
#endif
    }

    /// The "portal_slide_2" asset catalog image.
    static var portalSlide2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .portalSlide2)
#else
        .init()
#endif
    }

    /// The "portal_slide_3" asset catalog image.
    static var portalSlide3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .portalSlide3)
#else
        .init()
#endif
    }

    /// The "saba" asset catalog image.
    static var saba: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .saba)
#else
        .init()
#endif
    }

    /// The "sweet" asset catalog image.
    static var sweet: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .sweet)
#else
        .init()
#endif
    }

    /// The "tyuka" asset catalog image.
    static var tyuka: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tyuka)
#else
        .init()
#endif
    }

    /// The "washoku" asset catalog image.
    static var washoku: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .washoku)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "LaunchImage" asset catalog image.
    static var launch: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .launch)
#else
        .init()
#endif
    }

    /// The "donatu" asset catalog image.
    static var donatu: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .donatu)
#else
        .init()
#endif
    }

    /// The "portal_card_1" asset catalog image.
    static var portalCard1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .portalCard1)
#else
        .init()
#endif
    }

    /// The "portal_card_2" asset catalog image.
    static var portalCard2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .portalCard2)
#else
        .init()
#endif
    }

    /// The "portal_card_3" asset catalog image.
    static var portalCard3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .portalCard3)
#else
        .init()
#endif
    }

    /// The "portal_card_4" asset catalog image.
    static var portalCard4: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .portalCard4)
#else
        .init()
#endif
    }

    /// The "portal_card_5" asset catalog image.
    static var portalCard5: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .portalCard5)
#else
        .init()
#endif
    }

    /// The "portal_card_6" asset catalog image.
    static var portalCard6: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .portalCard6)
#else
        .init()
#endif
    }

    /// The "portal_slide_1" asset catalog image.
    static var portalSlide1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .portalSlide1)
#else
        .init()
#endif
    }

    /// The "portal_slide_2" asset catalog image.
    static var portalSlide2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .portalSlide2)
#else
        .init()
#endif
    }

    /// The "portal_slide_3" asset catalog image.
    static var portalSlide3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .portalSlide3)
#else
        .init()
#endif
    }

    /// The "saba" asset catalog image.
    static var saba: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .saba)
#else
        .init()
#endif
    }

    /// The "sweet" asset catalog image.
    static var sweet: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .sweet)
#else
        .init()
#endif
    }

    /// The "tyuka" asset catalog image.
    static var tyuka: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tyuka)
#else
        .init()
#endif
    }

    /// The "washoku" asset catalog image.
    static var washoku: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .washoku)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

