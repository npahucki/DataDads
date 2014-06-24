//
//  Contants.h
//  Milestones
//
//  Created by Nathan  Pahucki on 1/27/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#ifndef Milestones_Contants_h
#define Milestones_Contants_h

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


#pragma mark DD Error Codes
typedef enum _DDErrorCodeType : NSUInteger {
  kDDErrorUserRefusedFacebookPermissions = 300
}  DDErrorCodeType;

#pragma mark Segue Names
extern NSString *const kDDSegueEnterScreenName;
extern NSString *const kDDSegueNoteMilestone;
extern NSString *const kDDSegueShowSettings;
extern NSString *const kDDSegueShowAchievementDetails;
extern NSString *const kDDSegueShowLoginScreen;
extern NSString *const kDDSegueEnterBabyInfo;
extern NSString *const kDDSegueShowFullScreenImage;
extern NSString *const kDDSegueShowWebView;



#pragma mark Notification Names
extern NSString *const kDDNotificationCurrentBabyChanged;
extern NSString *const kDDNotificationMilestoneNotedAndSaved;
extern NSString *const kDDNotificationMeasurementNotedAndSaved;
extern NSString *const kDDNotificationUserSignedUp;
extern NSString *const kDDNotificationPushReceieved;


#pragma mark Application Colors


@interface UIColor (DataDads)

+(UIColor *) appNormalColor;
+(UIColor *) appSelectedColor;
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
