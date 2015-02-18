//
//  UsageAnalytics.h
//  DataParenting
//
//  Created by Nathan  Pahucki on 6/21/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UsageAnalytics : NSObject

+ (void)initializeAnalytics:(NSDictionary *)launchOptions;

+ (void)identify:(ParentUser *)user;

+ (void)trackError:(NSError *)error forOperationNamed:(NSString *)operation;

+ (void)trackError:(NSError *)error forOperationNamed:(NSString *)operation andAdditionalProperties:(NSDictionary *)props;


+ (void)trackUserSignup:(ParentUser *)user usingMethod:(NSString *)method;

+ (void)trackUserSignupError:(NSError *)error usingMethod:(NSString *)method;

+ (void)trackUserLinkedWithFacebook:(ParentUser *)user forPublish:(BOOL)publish withError:(NSError *)error;

+ (void)trackUserSignout:(ParentUser *)user;

+ (void)trackAppBecameActive;

+ (void)trackCreateBaby:(Baby *)baby;

+ (void)trackAchievementLogged:(MilestoneAchievement *)achievement sharedOnFacebook:(BOOL)shared;

+ (void)trackAchievementShared:(MilestoneAchievement *)achievement sharingMedium:(NSString*) medium;

+ (void)trackTipShared:(Tip *)achievement sharingMedium:(NSString*) medium;

+ (void)trackMeasurement:(Measurement *)measurement;

+ (void)trackSearch:(NSString *)filterString;

+ (void)trackAdClicked:(NSString *)adIdentifier;

+ (void)trackTutorialManuallyTaken;

//+ (void)trackTutorialResponse:(BOOL)viewed;

+ (void)trackSettingChange:(NSString *)settingName withValue:(id)value;

+ (void)trackPurchaseDecision:(BOOL)b forProductId:(NSString *)id;

+ (void)trackAccountThatCantPurchase;

+ (void)trackPurchaseCompleted:(NSString *)productId atPrice:(NSNumber *)price andCurrency:(NSString *)currency;

+ (void)trackPurchaseTransactionState:(SKPaymentTransaction *)transaction;

+ (void)trackUserDeniedAddressBookAccess;

+ (void)trackFollowConnectionInviteSent:(NSInteger)count;

+ (void)trackFollowConnectionInviteResponse:(BOOL)accepted;


+ (void)trackFollowConnectionRevokeInvite;

+ (void)trackFollowConnectionRemoveConnection;

+ (void)trackAppInstalled;

+ (void)trackPurchaseRestored:(NSString *)identifier;

+ (void)trackSignupDecisionOnScreen:(NSString *)string withChoice:(BOOL)choice;

+ (void)trackSignupTrigger:(NSString *)string withChoice:(BOOL)choice;
@end
