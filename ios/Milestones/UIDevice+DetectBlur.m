//
// Created by Nathan  Pahucki on 3/5/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "UIDevice+DetectBlur.h"


#include <sys/sysctl.h>

#if TARGET_IPHONE_SIMULATOR
@interface UIDevice()
- (long long)_graphicsQuality;
@end
#endif


@implementation UIDevice (DetectBlur)

- (BOOL)isBlurAvailable {
    // Blur is not available pre-iOS 8
    if ([self osMajorVersion] < 8) {
        return FALSE;
    }

    // Check for 'reduce transparency'. This function only exists on iOS 8
    // but we already checked that we are at least on iOS 8
    if (UIAccessibilityIsReduceTransparencyEnabled()) {
        return FALSE;
    }

    // Thanks to Daniel Martin on Stackoverflow
    if (![self blurSupported]) {
        return FALSE;
    }

#if TARGET_IPHONE_SIMULATOR
    // Ask the private API - safe enough to do on a simulator build
    // again, many thanks to the following post on Stackoverflow
    // http://stackoverflow.com/questions/27878769/check-if-device-supports-blur
    if ([[UIDevice currentDevice] _graphicsQuality] != 100) {
        return FALSE;
    }
#endif

    // Blur is available and enabled!
    return TRUE;
}

// Attribution: Daniel Martin
// http://stackoverflow.com/questions/27878769/check-if-device-supports-blur
- (BOOL)blurSupported {
    NSSet *unsupportedDevices = [NSSet setWithObjects:@"iPad",
                                                      @"iPad1,1",
                                                      @"iPhone1,1",
                                                      @"iPhone1,2",
                                                      @"iPhone2,1",
                                                      @"iPhone3,1",
                                                      @"iPhone3,2",
                                                      @"iPhone3,3",
                                                      @"iPod1,1",
                                                      @"iPod2,1",
                                                      @"iPod2,2",
                                                      @"iPod3,1",
                                                      @"iPod4,1",
                                                      @"iPad2,1",
                                                      @"iPad2,2",
                                                      @"iPad2,3",
                                                      @"iPad2,4",
                                                      @"iPad3,1",
                                                      @"iPad3,2",
                                                      @"iPad3,3", nil];
    return ![unsupportedDevices containsObject:[[UIDevice currentDevice] platform]];
}

- (int)osMajorVersion {
    NSArray *vComp = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
    return [vComp[0] intValue];
}


// The code below is from the UIDevice-Hardware category by the great Erica Sadun

/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook, 6.x Edition
 BSD License, Use at your own risk
 */

#pragma mark sysctlbyname utils

- (NSString *)getSysInfoByName:(char *)typeSpecifier {
    size_t size;
    sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);

    char *answer = malloc(size);
    sysctlbyname(typeSpecifier, answer, &size, NULL, 0);

    NSString *results = [NSString stringWithCString:answer encoding:NSUTF8StringEncoding];

    free(answer);
    return results;
}

- (NSString *)platform {
    return [self getSysInfoByName:"hw.machine"];
}

@end