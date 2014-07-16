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
#define UIColorFromRGBWithAlpha(rgbValue,alphaValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:alphaValue]

# if DEBUG || TARGET_IPHONE_SIMULATOR
  #define VIEW_HOST @"dataparenting-dev.parseapp.com"
#else
  #define VIEW_HOST @"view.dataparenting.com"
#endif




#pragma mark DD Error Codes
typedef enum _DDErrorCodeType : NSUInteger {
  kDDErrorUserRefusedFacebookPermissions = 300
}  DDErrorCodeType;

#pragma mark Segue Names
extern NSString *const kDDSegueEnterScreenName;
extern NSString *const kDDSegueNoteMilestone;
extern NSString *const kDDSegueNoteCustomMilestone;
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
extern NSString *const kNeedDataRefreshNotification;  // When table data may need to be reloaded 




#pragma mark Application Colors


@interface UIColor (DataParenting)

+(UIColor *) appNormalColor;
+(UIColor *) appSelectedColor;
+(UIColor *) appGreyTextColor;
+(UIColor *) appInputGreyTextColor;
+(UIColor *) appInputBorderActiveColor;
+(UIColor *) appInputBorderNormalColor;
+(UIColor *) appBackgroundColor;
+(UIColor *) appTitleHeaderColor;

+(UIColor *) appHeaderBackgroundActiveColor;
+(UIColor *) appHeaderActiveTextColor;
+(UIColor *) appHeaderCounterBackgroundActiveColor;
+(UIColor *) appHeaderCounterActiveTextColor;

+(UIColor *) appHeaderBackgroundNormalColor;
+(UIColor *) appHeaderNormalTextColor;
+(UIColor *) appHeaderBorderNormalColor;
+(UIColor *) appHeaderCounterNormalTextColor;





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

@interface UIFont (DataParenting)
+(UIFont *) fontForAppWithType:(AppFontType) type andSize:(CGFloat) size;
@end




#endif
