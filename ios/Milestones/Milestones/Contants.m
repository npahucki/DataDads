//
//  Contants.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/27/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


#pragma mark - Field Names
NSString *const kDDUserScreenName = @"screenName";
NSString *const kDDUserEmail = @"email";

#pragma mark - Segues
NSString *const kDDSegueEnterScreenName = @"enterScreenName";
NSString *const kDDSegueNoteMilestone = @"noteMilestone";
NSString *const kDDSegueCreateCustomMilestone = @"createCustomMilesone";
NSString *const kDDSegueShowMilestoneDetails = @"showMilestoneDetails";
NSString *const kDDSegueShowSettings = @"showSettings";


#pragma mark - Events
NSString *const kDDNotificationCurrentBabyChanged = @"currentBabyChanged";
NSString *const kDDNotificationMilestoneNotedAndSaved = @"milestoneNotedAndSaved";


#pragma mark - Application Colors
@implementation UIColor (DataDads)

+(UIColor *) appBlueColor {return UIColorFromRGB(0x3C92CF);} // 60 146 207
+(UIColor *) appBlueActivatedColor {return UIColorFromRGB(0x2E709E);} // 46 112 158
+(UIColor *) appGreyTextColor {return UIColorFromRGB(0xA9A9B1);} // 169 169 177

@end