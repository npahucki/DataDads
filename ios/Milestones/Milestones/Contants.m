//
//  Contants.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/27/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#pragma mark - Segue Names
NSString *const kDDSegueEnterScreenName = @"enterScreenName";
NSString *const kDDSegueNoteMilestone = @"noteMilestone";
NSString *const kDDSegueShowAchievementDetails = @"showAchievementDetails";
NSString *const kDDSegueShowSettings = @"showSettings";
NSString *const kDDSegueShowLoginScreen = @"showLoginScreen";
NSString *const kDDSegueEnterBabyInfo = @"enterBabyInfo";
NSString *const kDDSegueShowFullScreenImage = @"showFullScreenImage";
NSString *const kDDSegueShowWebView = @"showWebView";








#pragma mark - Events
NSString *const kDDNotificationCurrentBabyChanged = @"currentBabyChanged";
NSString *const kDDNotificationMilestoneNotedAndSaved = @"milestoneNotedAndSaved";
NSString *const kDDNotificationUserSignedUp = @"userSignedUp";
NSString *const kDDNotificationPushReceieved = @"notificationPushReceived";






#pragma mark - Application Colors
@implementation UIColor (DataDads)

+(UIColor *) appNormalColor {return UIColorFromRGB(0x1A8E9F);} // 26 142 159
+(UIColor *) appSelectedColor {return UIColorFromRGB(0x1F717E);} // 31 113 126
+(UIColor *) appGreyTextColor {return UIColorFromRGB(0xA9A9B1);} // 169 169 177
@end

@implementation UIFont (DataDads)


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
+(UIFont *) fontForAppWithType:(AppFontType) type andSize:(int) size {
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


