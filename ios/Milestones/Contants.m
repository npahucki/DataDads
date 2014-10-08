//
//  Contants.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/27/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//




#pragma mark - Segue Names
NSString *const kDDSegueEnterScreenName = @"enterScreenName";
NSString *const kDDSegueNoteMilestone = @"noteMilestone";
NSString *const kDDSegueNoteCustomMilestone = @"noteCustomMilestone";
NSString *const kDDSegueShowAchievementDetails = @"showAchievementDetails";
NSString *const kDDSegueShowNotificationDetails = @"showNotificationDetails";
NSString *const kDDSegueShowSettings = @"showSettings";
NSString *const kDDSegueShowLoginScreen = @"showLoginScreen";
NSString *const kDDSegueEnterBabyInfo = @"enterBabyInfo";
NSString *const kDDSegueShowFullScreenImage = @"showFullScreenImage";
NSString *const kDDSegueShowWebView = @"showWebView";


#pragma mark - Events
NSString *const kDDNotificationCurrentBabyChanged = @"currentBabyChanged";
NSString *const kDDNotificationMilestoneNotedAndSaved = @"milestoneNotedAndSaved";
NSString *const kDDNotificationAchievementNotedAndSaved = @"achievementNotedAndSaved";
NSString *const kDDNotificationMeasurementNotedAndSaved = @"measurementNotedAndSaved";
NSString *const kDDNotificationUserSignedUp = @"userSignedUp";
NSString *const kDDNotificationUserLoggedIn = @"userLoggedIn";

NSString *const kDDNotificationUserLoggedOut = @"userLoggedOut";
NSString *const kDDNotificationPushReceieved = @"notificationPushReceived";
NSString *const kDDNotificationNeedDataRefreshNotification = @"needDataRefresh";
NSString *const kDataObjectNeedsAction = @"dataObjectNeedsAction"; // request to take some action

NSString *const kDDNotificationAchievementNeedsDeleteAction = @"achievementNeedsDeleteAction";
NSString *const kDDNotificationMilestoneNeedsPostponeAction = @"milestoneNeedsPostponeAction";
NSString *const kDDNotificationMilestoneNeedsIgnoreAction = @"milestoneNeedsIgnoreAction";
NSString *const kDDNotificationProductPurchased = @"productPurchased";


NSString *const kDDURLTermsAndConditions = @"http://dataparenting.com/terms-conditions-and-privacy/";
NSString *const kDDURLPrivacyPolicy = @"http://dataparenting.com/terms-conditions-and-privacy/#privacy";
NSString *const kDDURLSupport = @"http://dataparenting.com/milestones-app-support/";


#pragma mark - Application Colors

@implementation UIColor (DataParenting)

+ (UIColor *)appNormalColor {
    return UIColorFromRGB(0x1A8E9F);
} // 26 142 159
+ (UIColor *)appSelectedColor {
    return UIColorFromRGB(0x1F717E);
} // 31 113 126
+ (UIColor *)appGreyTextColor {
    return UIColorFromRGB(0x56565a);
} // 169 169 177
+ (UIColor *)appInputGreyTextColor {
    return UIColorFromRGB(0x9d9da4);
}


+ (UIColor *)appInputBorderActiveColor {
    return UIColorFromRGB(0x22B9CF);
}

+ (UIColor *)appInputBorderNormalColor {
    return UIColorFromRGB(0xCFCFD3);
}

+ (UIColor *)appBackgroundColor {
    return UIColorFromRGBWithAlpha(0xFBFBFB, .95);
}

+ (UIColor *)appTitleHeaderColor {
    return UIColorFromRGB(0x56565a);
}

+ (UIColor *)appHeaderBackgroundActiveColor {
    return UIColorFromRGBWithAlpha(0xDCE7E9, .95);
}

+ (UIColor *)appHeaderActiveTextColor {
    return [UIColor appNormalColor];
}

+ (UIColor *)appHeaderCounterBackgroundActiveColor {
    return UIColorFromRGB(0x1a8e9f);
}

+ (UIColor *)appHeaderCounterActiveTextColor {
    return UIColorFromRGB(0xFBFBFB);
}

+ (UIColor *)appHeaderBackgroundNormalColor {
    return [UIColor appBackgroundColor];
}

+ (UIColor *)appHeaderNormalTextColor {
    return UIColorFromRGB(0x8e8e8e);
}

+ (UIColor *)appHeaderBorderNormalColor {
    return UIColorFromRGB(0xCFCFD3);
}

+ (UIColor *)appHeaderCounterNormalTextColor {
    return [UIColor appNormalColor];
}

@end

@implementation UIFont (DataParenting)


/*
 Family Name: Gotham Rounded
 GothamRounded-BookItalic
 GothamRounded-MediumItalic
 GothamRounded-BoldItalic
 GothamRounded-Light
 GothamRounded-Medium
 GothamRounded-Bold
 GothamRounded-LightItalic
 GothamRounded-Book
 */
+ (UIFont *)fontForAppWithType:(AppFontType)type andSize:(CGFloat)size {
    switch (type) {
        default:
        case Light:
            return [UIFont fontWithName:@"GothamRounded-Light" size:size];
        case LightItalic:
            return [UIFont fontWithName:@"GothamRounded-LightItalic" size:size];
        case Medium:
            return [UIFont fontWithName:@"GothamRounded-Medium" size:size];
        case MediumItalic:
            return [UIFont fontWithName:@"GothamRounded-MediumItalic" size:size];
        case Book:
            return [UIFont fontWithName:@"GothamRounded-Book" size:size];
        case BookItalic:
            return [UIFont fontWithName:@"GothamRounded-BookItalic" size:size];
        case Bold:
            return [UIFont fontWithName:@"GothamRounded-Bold" size:size];
        case BoldItalic:
            return [UIFont fontWithName:@"GothamRounded-BoldItalic" size:size];
    }
}
@end


