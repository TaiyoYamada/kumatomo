#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"com.taiyo.kumatomo.app";

/// The "AccentColor" asset catalog color resource.
static NSString * const ACColorNameAccentColor AC_SWIFT_PRIVATE = @"AccentColor";

/// The "LaunchImage" asset catalog image resource.
static NSString * const ACImageNameLaunchImage AC_SWIFT_PRIVATE = @"LaunchImage";

/// The "donatu" asset catalog image resource.
static NSString * const ACImageNameDonatu AC_SWIFT_PRIVATE = @"donatu";

/// The "portal_card_1" asset catalog image resource.
static NSString * const ACImageNamePortalCard1 AC_SWIFT_PRIVATE = @"portal_card_1";

/// The "portal_card_2" asset catalog image resource.
static NSString * const ACImageNamePortalCard2 AC_SWIFT_PRIVATE = @"portal_card_2";

/// The "portal_card_3" asset catalog image resource.
static NSString * const ACImageNamePortalCard3 AC_SWIFT_PRIVATE = @"portal_card_3";

/// The "portal_card_4" asset catalog image resource.
static NSString * const ACImageNamePortalCard4 AC_SWIFT_PRIVATE = @"portal_card_4";

/// The "portal_card_5" asset catalog image resource.
static NSString * const ACImageNamePortalCard5 AC_SWIFT_PRIVATE = @"portal_card_5";

/// The "portal_card_6" asset catalog image resource.
static NSString * const ACImageNamePortalCard6 AC_SWIFT_PRIVATE = @"portal_card_6";

/// The "portal_slide_1" asset catalog image resource.
static NSString * const ACImageNamePortalSlide1 AC_SWIFT_PRIVATE = @"portal_slide_1";

/// The "portal_slide_2" asset catalog image resource.
static NSString * const ACImageNamePortalSlide2 AC_SWIFT_PRIVATE = @"portal_slide_2";

/// The "portal_slide_3" asset catalog image resource.
static NSString * const ACImageNamePortalSlide3 AC_SWIFT_PRIVATE = @"portal_slide_3";

/// The "saba" asset catalog image resource.
static NSString * const ACImageNameSaba AC_SWIFT_PRIVATE = @"saba";

/// The "sweet" asset catalog image resource.
static NSString * const ACImageNameSweet AC_SWIFT_PRIVATE = @"sweet";

/// The "tyuka" asset catalog image resource.
static NSString * const ACImageNameTyuka AC_SWIFT_PRIVATE = @"tyuka";

/// The "washoku" asset catalog image resource.
static NSString * const ACImageNameWashoku AC_SWIFT_PRIVATE = @"washoku";

#undef AC_SWIFT_PRIVATE
