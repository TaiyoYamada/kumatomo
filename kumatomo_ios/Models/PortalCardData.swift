import Foundation

struct PortalCardData: Identifiable {
    let id = UUID()
    let title: String
    let iconName: String
    let imageName: String    // Asset name for the card image (e.g., "portal_card_1")
    let externalURL: String  // URL to open when card is tapped
}

let samplePortalCards: [PortalCardData] = [
    PortalCardData(
        title: "防災",
        iconName: "exclamationmark.triangle.fill",
        imageName: "portal_card_1",
        externalURL: "https://portal.bousai.pref.kumamoto.jp/"
    ),
    PortalCardData(
        title: "観光",
        iconName: "airplane",
        imageName: "portal_card_2",
        externalURL: "https://kumamoto.guide/"
    ),
    PortalCardData(
        title: "結婚・子育て",
        iconName: "face.smiling",
        imageName: "portal_card_3",
        externalURL: "https://www.hapimon.jp/"
    ),
    PortalCardData(
        title: "熊本県公式",
        iconName: "building.columns",
        imageName: "portal_card_4",
        externalURL: "https://www.pref.kumamoto.jp/"
    ),
    PortalCardData(
        title: "医療",
        iconName: "cross.case.fill",
        imageName: "portal_card_6",
        externalURL: "https://www.iryou.teikyouseido.mhlw.go.jp/znk-web/juminkanja/S2310/initialize?pref=43"
    )
]
//
//let portalSlideshowImages: [String] = [
//    "portal_slide_1", // TODO: Add actual slideshow image to Assets.xcassets
//    "portal_slide_2", // TODO: Add actual slideshow image to Assets.xcassets  
//    "portal_slide_3", // TODO: Add actual slideshow image to Assets.xcassets
//    "portal_slide_4", // TODO: Add actual slideshow image to Assets.xcassets
//    "portal_slide_5"  // TODO: Add actual slideshow image to Assets.xcassets
//]
