#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"fyi.feels.weather";

/// The "LaunchBackground" asset catalog color resource.
static NSString * const ACColorNameLaunchBackground AC_SWIFT_PRIVATE = @"LaunchBackground";

/// The "clear-sky" asset catalog image resource.
static NSString * const ACImageNameClearSky AC_SWIFT_PRIVATE = @"clear-sky";

/// The "clear-sky-evening" asset catalog image resource.
static NSString * const ACImageNameClearSkyEvening AC_SWIFT_PRIVATE = @"clear-sky-evening";

/// The "clear-sky-evening-ios" asset catalog image resource.
static NSString * const ACImageNameClearSkyEveningIos AC_SWIFT_PRIVATE = @"clear-sky-evening-ios";

/// The "clear-sky-morning" asset catalog image resource.
static NSString * const ACImageNameClearSkyMorning AC_SWIFT_PRIVATE = @"clear-sky-morning";

/// The "clear-sky-morning-ios" asset catalog image resource.
static NSString * const ACImageNameClearSkyMorningIos AC_SWIFT_PRIVATE = @"clear-sky-morning-ios";

/// The "cloudy" asset catalog image resource.
static NSString * const ACImageNameCloudy AC_SWIFT_PRIVATE = @"cloudy";

/// The "cloudy-ios" asset catalog image resource.
static NSString * const ACImageNameCloudyIos AC_SWIFT_PRIVATE = @"cloudy-ios";

/// The "fog" asset catalog image resource.
static NSString * const ACImageNameFog AC_SWIFT_PRIVATE = @"fog";

/// The "fog-ios" asset catalog image resource.
static NSString * const ACImageNameFogIos AC_SWIFT_PRIVATE = @"fog-ios";

/// The "heavy-rain-and-wind" asset catalog image resource.
static NSString * const ACImageNameHeavyRainAndWind AC_SWIFT_PRIVATE = @"heavy-rain-and-wind";

/// The "heavy-rain-and-wind-ios" asset catalog image resource.
static NSString * const ACImageNameHeavyRainAndWindIos AC_SWIFT_PRIVATE = @"heavy-rain-and-wind-ios";

/// The "hot35" asset catalog image resource.
static NSString * const ACImageNameHot35 AC_SWIFT_PRIVATE = @"hot35";

/// The "hot35-ios" asset catalog image resource.
static NSString * const ACImageNameHot35Ios AC_SWIFT_PRIVATE = @"hot35-ios";

#undef AC_SWIFT_PRIVATE
