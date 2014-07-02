//
//  UsageAnalytics.h
//  DataParenting
//
//  Created by Nathan  Pahucki on 6/21/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UsageAnalytics : NSObject

+(void) initializeConnection;
+(void) idenfity:(ParentUser*) user withBaby:(Baby*) baby;

+(void) trackError:(NSError*)error forOperationNamed:(NSString*) operation;
+(void) trackError:(NSError*)error forOperationNamed:(NSString*) operation andAdditionalProperties:(NSDictionary*) props;


+(void) trackUserSignup:(ParentUser*) user usingMethod:(NSString*) method;
+(void) trackUserSignupError:(NSError*)error usingMethod:(NSString*) method;

+(void) trackUserLinkedWithFacebook:(ParentUser*) user forPublish:(BOOL) publish withError:(NSError*) error;

+(void) trackUserSignout:(ParentUser*) user;
+(void) trackAchievementLogged:(MilestoneAchievement *) achievement sharedOnFacebook:(BOOL) shared; 
+(void) trackMeasurement:(Measurement *) measurement;
+(void) trackSearch:(NSString *) filterString;




@end
