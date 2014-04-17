//
//  Contants.h
//  Milestones
//
//  Created by Nathan  Pahucki on 1/27/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#ifndef Milestones_Contants_h
#define Milestones_Contants_h


// User object constants
extern NSString *const kDDUserScreenName;
extern NSString *const kDDUserIsMale;
extern NSString *const kDDUserEmail;


#pragma mark Segue Names
extern NSString *const kDDSegueEnterScreenName;
extern NSString *const kDDSegueNoteMilestone;
extern NSString *const kDDSegueCreateCustomMilestone;
extern NSString *const kDDSegueShowMilestoneDetails;
extern NSString *const kDDSegueShowSettings;


#pragma mark Notification Names
extern NSString *const kDDNotificationCurrentBabyChanged;   // User data is NSDictionary with Baby object keyed by @""
extern NSString *const kDDNotificationMilestoneNoted;       // User data is NSDictionary with StandardMilestone object keyed by @""
extern NSString *const kDDNotificationMilestoneNotedAndSaved;       // User data is NSDictionary with StandardMilestone object keyed by @""


#pragma mark Application Colors


@interface UIColor (DataDads)

+(UIColor *) appBlueColor;
+(UIColor *) appBlueActivatedColor;
+(UIColor *) appGreyTextColor;
@end

#pragma mark Application Fonts

typedef enum _AppFontType : NSUInteger {
  Light = 1,
  LightItalic,
  Medium,
  MediumItalic,
  Book,
  BookItalic,
  Bold,
  BoldItalic
}  AppFontType;

@interface UIFont (DataDads)
+(UIFont *) fontForAppWithType:(AppFontType) type andSize:(int) size;
@end




#endif
