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
        title: "防災情報くまもと",
        iconName: "exclamationmark.triangle.fill",
        imageName: "portal_card_1",
        externalURL: "https://portal.bousai.pref.kumamoto.jp/"
    ),
    PortalCardData(
        title: "もっと、もーっと、くまもっと",
        iconName: "airplane.departure",
        imageName: "portal_card_2",
        externalURL: "https://kumamoto.guide/"
    ),
    PortalCardData(
        title: "hapiモン",
        iconName: "face.smiling",
        imageName: "portal_card_3",
        externalURL: "https://www.hapimon.jp/"
    ),
    PortalCardData(
        title: "熊本県公式サイト",
        iconName: "building.columns",
        imageName: "portal_card_4",
        externalURL: "https://www.pref.kumamoto.jp/"
    ),
    PortalCardData(
        title: "KUMAMOTO LIFE",
        iconName: "house.fill",
        imageName: "portal_card_5",
        externalURL: "https://www.kumamoto-life.jp/"
    ),
    PortalCardData(
        title: "医療情報ネット ナビィ　熊本",
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
