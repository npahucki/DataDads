//
//  UsageAnalytics.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 6/21/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "Heap.h"
#import "NSDate+Utils.h"
#import "AppsFlyerTracker.h"


static id safe(id object) {
    return object ?: [NSNull null];
}

static BOOL isRelease;

@implementation UsageAnalytics

+ (void)initializeAnalytics {
# if DEBUG || TARGET_IPHONE_SIMULATOR
    isRelease = NO;
#else
    isRelease = YES;
#endif

    if (isRelease) {
        [Heap setAppId:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"DP.HeapAppId"]];
        [Heap changeInterval:30];
        [AppsFlyerTracker sharedTracker].appsFlyerDevKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"DP.AppsFlyerDevKey"];
        [AppsFlyerTracker sharedTracker].appleAppID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"DP.AppleStoreId"];
        [AppsFlyerTracker sharedTracker].isHTTPS = YES;
        [[AppsFlyerTracker sharedTracker] trackAppLaunch];
    }
}

+ (void)idenfity:(ParentUser *)user withBaby:(Baby *)baby {
    if (user) {
        NSMutableDictionary *props = [@{
                @"user.id" : safe(user.objectId),
                @"user.anonymous" : user.email ? @"N" : @"Y",
                @"user.screenName" : safe(user.screenName),
                @"user.linkedToFacebook" : [PFFacebookUtils isLinkedWithUser:user] ? @"Y" : @"N",
                @"user.emailVerified" : [user objectForKey:@"emailVerified"] ? @"Y" : @"N",
                @"user.sex" : user.isMale ? @"M" : @"F"
        } mutableCopy];
        // Don't add if null, this causes problems in Heap!
        if (user.email) props[@"email"] = user.email;
        if (baby) {
            props[@"baby.id"] = safe(baby.objectId);
            props[@"baby.sex"] = baby.isMale ? @"M" : @"F";
        }

        if (isRelease) {
            [AppsFlyerTracker sharedTracker].customerUserID = user.objectId;
            [Heap identify:props];
        } else {
            NSLog(@"[USAGE ANALYTICS]: Identify - %@", props);
        }
    }
}

+ (void)trackError:(NSError *)error forOperationNamed:(NSString *)operation {
    [self trackError:error forOperationNamed:operation andAdditionalProperties:nil];
}

+ (void)trackError:(NSError *)error forOperationNamed:(NSString *)operation andAdditionalProperties:(NSDictionary *)props {
    NSMutableDictionary *combinedAttributes = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
    if (props) [combinedAttributes addEntriesFromDictionary:props];
    combinedAttributes[@"error.id"] = @(error.code);
    combinedAttributes[@"error.domain"] = safe(error.domain);
    combinedAttributes[@"operation"] = operation;
    combinedAttributes[@"timestamp"] = [[NSDate date] asISO8601String];

    if (isRelease) {
        [Heap track:[NSString stringWithFormat:@"Error"] withProperties:combinedAttributes];
    } else {
        NSLog(@"[USAGE ANALYTICS]: trackError - Error Properties:%@", combinedAttributes);
    }
}


+ (void)trackUserSignup:(ParentUser *)user usingMethod:(NSString *)method {
    // We want to track the number of milestones.
    if (Baby.currentBaby) {
        PFQuery *query = [MilestoneAchievement query];
        [query whereKey:@"baby" equalTo:Baby.currentBaby];
        [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {

            if (isRelease) {
                [Heap track:@"userSignedUp" withProperties:@{
                        @"user.id" : safe(user.objectId),
                        @"method" : safe(method),
                        @"numberOfAchievements" : @(number)
                }];
                [[AppsFlyerTracker sharedTracker] trackEvent:@"userSignedUp" withValue:[@(number) stringValue]];
            } else {
                NSLog(@"[USAGE ANALYTICS]: trackUserSignup - User:%@ Method:%@ Number of Achievements:%d", user, method, number);
            }
        }];
    } else {
        if (isRelease) {
            [Heap track:@"userSignedUp" withProperties:@{
                    @"user.id" : safe(user.objectId),
                    @"method" : safe(method)
            }];
            [[AppsFlyerTracker sharedTracker] trackEvent:@"userSignedUp" withValue:@"0"];
        } else {
            NSLog(@"[USAGE ANALYTICS]: trackUserSignup - User:%@ Method:%@", user, method);
        }
    }
}

+ (void)trackUserSignupError:(NSError *)error usingMethod:(NSString *)method {
    [self trackError:error forOperationNamed:@"userSignup" andAdditionalProperties:@{@"method" : method}];
}

+ (void)trackUserLinkedWithFacebook:(ParentUser *)user forPublish:(BOOL)publish withError:(NSError *)error {
    NSDictionary *props = @{@"user.id" : safe(user.objectId),
            @"forPublish" : publish ? @"Y" : @"N",
    };

    if (error) {
        [self trackError:error forOperationNamed:@"userLinkedWithFacebook" andAdditionalProperties:props];
    } else {
        if (isRelease) {
            [Heap track:@"userLinkedWithFacebook" withProperties:props];
            [[AppsFlyerTracker sharedTracker] trackEvent:@"userLinkedWithFacebook" withValue:@""];
        } else {
            NSLog(@"[USAGE ANALYTICS]: trackUserLinkedWithFacebook - User:%@ Publish:%d", user, publish);
        }
    }
}

+ (void)trackUserSignout:(ParentUser *)user {
    if (isRelease) {
        [Heap track:@"userSignedOut" withProperties:@{@"user.id" : safe(user.objectId)}];
        [[AppsFlyerTracker sharedTracker] trackEvent:@"userSignedOut" withValue:@""];
    } else {
        NSLog(@"[USAGE ANALYTICS]: trackUserSignout - User:%@", user);
    }
}

+ (void)trackAchievementLogged:(MilestoneAchievement *)achievement sharedOnFacebook:(BOOL)shared {
    if (isRelease) {
        if (achievement.isPostponed) {
            [Heap track:@"milestonePostponed" withProperties:@{
                    @"user.id" : safe(achievement.baby.parentUser.objectId),
                    @"baby.id" : safe(achievement.baby.objectId),
                    @"milestoneId" : safe(achievement.standardMilestone.objectId)
            }];
        } else if (achievement.isSkipped) {
            [Heap track:@"milestoneSkipped" withProperties:@{
                    @"user.id" : safe(achievement.baby.parentUser.objectId),
                    @"baby.id" : safe(achievement.baby.objectId),
                    @"milestoneId" : safe(achievement.standardMilestone.objectId)
            }];
        } else {
            [Heap track:@"achievementLogged" withProperties:@{
                    @"user.id" : safe(achievement.baby.parentUser.objectId),
                    @"baby.id" : safe(achievement.baby.objectId),
                    @"achievement.isStandard" : achievement.standardMilestone ? @"Y" : @"N",
                    @"achievement.standardMilestoneId" : safe(achievement.standardMilestone.objectId),
                    @"achievement.attachmentType" : safe(achievement.attachmentType),
                    @"achievement.hasAttachment" : achievement.attachmentType ? @"Y" : @"N",
                    @"achievement.hasCustomTitle" : achievement.customTitle ? @"Y" : @"N",
                    @"achievement.hasComment" : achievement.comment ? @"Y" : @"N",
                    @"sharedOnFacebook" : shared ? @"Y" : @"N"
            }];
        }
    } else {
        NSLog(@"[USAGE ANALYTICS]: trackAchievementLogged - Achievement:%@", achievement);
    }
}


+ (void)trackMeasurement:(Measurement *)measurement {
    if (isRelease) {
        [Heap track:@"measurementLogged" withProperties:@{
                @"user.id" : safe(measurement.baby.parentUser.objectId),
                @"baby.id" : safe(measurement.baby.objectId),
                @"measurement.type" : safe(measurement.type)
        }];
    } else {
        NSLog(@"[USAGE ANALYTICS]: trackMeasurement - Measurement:%@", measurement);
    }
}

+ (void)trackSearch:(NSString *)filterString {
    if (isRelease) {
        [Heap track:@"searchExecuted" withProperties:@{@"filterString" : filterString}];
    } else {
        NSLog(@"[USAGE ANALYTICS]: trackSearch - Filter:%@", filterString);
    }
}

+ (void)trackAdClicked:(NSString *)adIdentifier {
    if (isRelease) {
        [Heap track:@"adClicked" withProperties:@{@"adIdentifier" : adIdentifier}];
        [[AppsFlyerTracker sharedTracker] trackEvent:@"adIdentifier" withValue:adIdentifier];
    } else {
        NSLog(@"[USAGE ANALYTICS]: trackAdClick - AdId:%@", adIdentifier);
    }
}

+ (void)trackTutorialResponse:(BOOL)viewed {
    if (isRelease) {
        [Heap track:@"respondedToTutoriaPrompt" withProperties:@{@"viewed" : @(viewed)}];
    } else {
        NSLog(@"[USAGE ANALYTICS]: respondedToTutoriaPrompt - viewed:%d", viewed);
    }
}

+ (void)trackSettingChange:(NSString *)settingName withValue:(id)value {
    if (isRelease) {
        [Heap track:@"settingChange" withProperties:@{@"settingName" : settingName, @"value" : value}];
    } else {
        NSLog(@"[USAGE ANALYTICS]: setting - setting:%@ value:%@", settingName, value);
    }

}

+ (void)trackPurchaseDecision:(BOOL)b forProductId:(NSString *)productId {
    if (isRelease) {
        [Heap track:@"purchaseDecision" withProperties:@{@"productId" : productId}];
    } else {
        NSLog(@"[USAGE ANALYTICS]: purchaseDecision - productId:%@", productId);
    }
}

+ (void)trackAccountThatCantPurchase {
    if (isRelease) {
        [Heap track:@"accountCantPurchase" withProperties:nil];
    } else {
        NSLog(@"[USAGE ANALYTICS]: accountCantPurchase");
    }
}

+ (void)trackPurchaseTransactionState:(SKPaymentTransaction *)transaction {
    NSString *stateString;
    switch (transaction.transactionState) {
        case SKPaymentTransactionStatePurchasing:
            stateString = @"SKPaymentTransactionStatePurchasing";
            break;
        case SKPaymentTransactionStatePurchased:
            stateString = @"SKPaymentTransactionStatePurchased";
            break;
        case SKPaymentTransactionStateFailed:
            stateString = @"SKPaymentTransactionStateFailed";
            break;
        case SKPaymentTransactionStateRestored:
            stateString = @"SKPaymentTransactionStateRestored";
            break;
    }

    if (isRelease) {
        [Heap track:@"purchaseTransactionState" withProperties:@{
                @"state" : stateString,
                @"productId" : transaction.payment.productIdentifier,
                @"transactionId" : transaction.transactionIdentifier
        }];
    } else {
        NSLog(@"[USAGE ANALYTICS]: purchaseTransactionState - state:%@ productId:%@", stateString, transaction.payment.productIdentifier);
    }
}

@end
