//
//  UsageAnalytics.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 6/21/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <UXCam/UXCam.h>
#import "Heap.h"
#import "NSDate+Utils.h"
#import "AppsFlyerTracker.h"
#import "Mixpanel.h"


static id safe(id object) {
    return object ?: [NSNull null];
}

static BOOL isRelease;

@implementation UsageAnalytics

+ (void)initializeAnalytics:(NSDictionary *)launchOptions {
# if DEBUG || TARGET_IPHONE_SIMULATOR
    isRelease = NO;
#else
    isRelease = YES;
#endif
    NSLog(@"RUNNING IN RELEASE?:%d", isRelease);

    if (isRelease) {
        [Heap setAppId:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"DP.HeapAppId"]];
        [Heap changeInterval:30];

        [AppsFlyerTracker sharedTracker].appsFlyerDevKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"DP.AppsFlyerDevKey"];
        [AppsFlyerTracker sharedTracker].appleAppID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"DP.AppleStoreId"];
        [AppsFlyerTracker sharedTracker].isHTTPS = YES;
        [[AppsFlyerTracker sharedTracker] trackAppLaunch];

        NSString *uxCamKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"DP.UXCamKey"];
        [UXCam startApplicationWithKey:uxCamKey];

        NSString *mixPanelKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"DP.MixPanelKey"];
        [Mixpanel sharedInstanceWithToken:mixPanelKey];

    } else {
        //[Optimizely enableEditor];
    }

    [Optimizely                                                        startOptimizelyWithAPIToken:
            [[NSBundle mainBundle] objectForInfoDictionaryKey:@"DP.OptimizelyToken"] launchOptions:launchOptions];


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
            [UXCam tagUsersName:user.objectId additionalData:user.email];
            [UXCam addTag:user.isMale ? @"male" : @"female"];
            [UXCam addTag:user.email ? @"anonymous" : @"signedup"];
            if (user.screenName) [UXCam tagScreenName:user.screenName];

            for (NSString *key in props) {
                [Optimizely setValue:key forCustomTag:props[key]];
            }

            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel identify:user.objectId];
            [mixpanel.people set:props];
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
        [[Mixpanel sharedInstance] track:@"Error" properties:combinedAttributes];
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
                NSDictionary *props = @{
                        @"user.id" : safe(user.objectId),
                        @"method" : safe(method),
                        @"numberOfAchievements" : @(number)
                };
                [Heap track:@"userSignedUp" withProperties:props];
                [[Mixpanel sharedInstance] track:@"userSignup" properties:props];
                [[AppsFlyerTracker sharedTracker] trackEvent:@"userSignedUp" withValue:[@(number) stringValue]];
                [FBAppEvents logEvent:FBAppEventNameCompletedRegistration parameters:props];
            } else {
                NSLog(@"[USAGE ANALYTICS]: trackUserSignup - User:%@ Method:%@ Number of Achievements:%d", user, method, number);
            }
        }];
    } else {
        if (isRelease) {
            NSDictionary *props = @{
                    @"user.id" : safe(user.objectId),
                    @"method" : safe(method)
            };
            [Heap track:@"userSignedUp" withProperties:props];
            [[AppsFlyerTracker sharedTracker] trackEvent:@"userSignedUp" withValue:@"0"];
            [FBAppEvents logEvent:FBAppEventNameCompletedRegistration parameters:props];
            [Optimizely trackEvent:@"userSignup"];
            [[Mixpanel sharedInstance] track:@"userSignup" properties:props];
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
            [[Mixpanel sharedInstance] track:@"userLinkedWithFacebook" properties:props];
            [FBAppEvents logEvent:@"userLinkedWithFacebook" parameters:props];
            [[AppsFlyerTracker sharedTracker] trackEvent:@"userLinkedWithFacebook" withValue:@""];
            [Optimizely trackEvent:@"userLinkedWithFacebook"];
        } else {
            NSLog(@"[USAGE ANALYTICS]: trackUserLinkedWithFacebook - User:%@ Publish:%d", user, publish);
        }
    }
}

+ (void)trackUserSignout:(ParentUser *)user {
    if (isRelease) {
        [Heap track:@"userSignedOut" withProperties:@{@"user.id" : safe(user.objectId)}];
        [[Mixpanel sharedInstance] track:@"userSignedOut" properties:@{@"user.id" : safe(user.objectId)}];
        [FBAppEvents logEvent:@"userSignedOut" parameters:@{@"user.id" : safe(user.objectId)}];
        [[AppsFlyerTracker sharedTracker] trackEvent:@"userSignedOut" withValue:@""];
        [Optimizely trackEvent:@"userSignedOut"];
    } else {
        NSLog(@"[USAGE ANALYTICS]: trackUserSignout - User:%@", user);
    }
}

+ (void)trackAppBecameActive {
    if (isRelease) {
        [FBAppEvents activateApp];
        [Heap track:@"activateApp"];
        [[Mixpanel sharedInstance] track:@"activateApp"];
        [[AppsFlyerTracker sharedTracker] trackEvent:@"activateApp" withValue:@""];
    } else {
        NSLog(@"[USAGE ANALYTICS]: trackAppBecameActive");
    }
}

+ (void)trackCreateBaby:(Baby *)baby {

    if (isRelease) {
        NSDictionary *props = @{
                @"baby.id" : baby.objectId,
                @"baby.name" : safe(baby.name),
                @"baby.daysSinceBirth" : @(baby.daysSinceBirth)
        };
        [Heap track:@"babyCreated" withProperties:props];
        [[Mixpanel sharedInstance] track:@"babyCreated" properties:props];
        [FBAppEvents logEvent:@"babyCreated" parameters:props];
        [[AppsFlyerTracker sharedTracker] trackEvent:@"babyCreated" withValue:props.description];
        [Optimizely trackEvent:@"babyCreated"];
    } else {
        NSLog(@"[USAGE ANALYTICS]: trackCreateBaby - Baby:%@", baby);
    }
}


+ (void)trackAchievementLogged:(MilestoneAchievement *)achievement sharedOnFacebook:(BOOL)shared {
    if (isRelease) {
        if (achievement.isPostponed) {
            NSDictionary *props = @{
                    @"user.id" : safe(achievement.baby.parentUser.objectId),
                    @"baby.id" : safe(achievement.baby.objectId),
                    @"milestoneId" : safe(achievement.standardMilestone.objectId)
            };
            [Heap track:@"milestonePostponed" withProperties:props];
            [[Mixpanel sharedInstance] track:@"milestonePostponed" properties:props];
            [[Mixpanel sharedInstance].people increment:@"milestonesPostponed" by:@(1)];
            [Optimizely trackEvent:@"milestonePostponed"];
        } else if (achievement.isSkipped) {
            NSDictionary *props = @{
                    @"user.id" : safe(achievement.baby.parentUser.objectId),
                    @"baby.id" : safe(achievement.baby.objectId),
                    @"milestoneId" : safe(achievement.standardMilestone.objectId)
            };
            [Heap track:@"milestoneSkipped" withProperties:props];
            [[Mixpanel sharedInstance] track:@"milestoneSkipped" properties:props];
            [[Mixpanel sharedInstance].people increment:@"milestonesSkipped" by:@(1)];
            [Optimizely trackEvent:@"milestoneSkipped"];
        } else {
            NSDictionary *props = @{
                    @"user.id" : safe(achievement.baby.parentUser.objectId),
                    @"baby.id" : safe(achievement.baby.objectId),
                    @"achievement.isStandard" : achievement.standardMilestone ? @"Y" : @"N",
                    @"achievement.standardMilestoneId" : safe(achievement.standardMilestone.objectId),
                    @"achievement.title" : safe(achievement.displayTitle),
                    @"achievement.attachmentType" : safe(achievement.attachmentType),
                    @"achievement.hasAttachment" : achievement.attachmentType ? @"Y" : @"N",
                    @"achievement.hasCustomTitle" : achievement.customTitle ? @"Y" : @"N",
                    @"achievement.hasComment" : achievement.comment ? @"Y" : @"N",
                    @"sharedOnFacebook" : shared ? @"Y" : @"N"
            };
            [Heap track:@"achievementLogged" withProperties:props];
            [[Mixpanel sharedInstance] track:@"achievementLogged" properties:props];
            [[Mixpanel sharedInstance].people increment:@"achievementsLogged" by:@(1)];
            [FBAppEvents logEvent:@"achievementLogged" parameters:props];
            [Optimizely trackEvent:@"achievementLogged"];
        }
    } else {
        NSLog(@"[USAGE ANALYTICS]: trackAchievementLogged - Achievement:%@", achievement);
    }
}


+ (void)trackMeasurement:(Measurement *)measurement {
    if (isRelease) {
        NSDictionary *props = @{
                @"user.id" : safe(measurement.baby.parentUser.objectId),
                @"baby.id" : safe(measurement.baby.objectId),
                @"measurement.type" : safe(measurement.type)
        };
        [Heap track:@"measurementLogged" withProperties:props];
        [[Mixpanel sharedInstance] track:@"measurementLogged" properties:props];
        [Optimizely trackEvent:@"measurementLogged"];
    } else {
        NSLog(@"[USAGE ANALYTICS]: trackMeasurement - Measurement:%@", measurement);
    }
}

+ (void)trackSearch:(NSString *)filterString {
    if (isRelease) {
        [Heap track:@"searchExecuted" withProperties:@{@"filterString" : filterString}];
        [FBAppEvents logEvent:FBAppEventNameSearched parameters:@{FBAppEventParameterNameSearchString : filterString}];
        [[Mixpanel sharedInstance] track:@"searchExecuted" properties:@{@"filterString" : filterString}];
        [Optimizely trackEvent:@"searchExecuted"];
    } else {
        NSLog(@"[USAGE ANALYTICS]: trackSearch - Filter:%@", filterString);
    }
}

+ (void)trackAdClicked:(NSString *)adIdentifier {
    if (isRelease) {
        [Heap track:@"adClicked" withProperties:@{@"adIdentifier" : adIdentifier}];
        [[Mixpanel sharedInstance] track:@"adClicked" properties:@{@"adIdentifier" : adIdentifier}];
        [[AppsFlyerTracker sharedTracker] trackEvent:@"adIdentifier" withValue:adIdentifier];
        [FBAppEvents logEvent:@"adClicked" parameters:@{@"adIdentifier" : adIdentifier}];
        [Optimizely trackEvent:@"adClicked"];
    } else {
        NSLog(@"[USAGE ANALYTICS]: trackAdClick - AdId:%@", adIdentifier);
    }
}

+ (void)trackTutorialResponse:(BOOL)viewed {
    if (isRelease) {
        [Heap track:@"respondedToTutoriaPrompt" withProperties:@{@"viewed" : @(viewed)}];
        [[Mixpanel sharedInstance] track:@"respondedToTutoriaPrompt" properties:@{@"viewed" : @(viewed)}];
        [FBAppEvents logEvent:FBAppEventNameCompletedTutorial];
        [Optimizely trackEvent:viewed ? @"tutorialViewed" : @"tutorialSkipped"];
    } else {
        NSLog(@"[USAGE ANALYTICS]: respondedToTutoriaPrompt - viewed:%d", viewed);
    }
}

+ (void)trackSettingChange:(NSString *)settingName withValue:(id)value {
    if (isRelease) {
        [Heap track:@"settingChange" withProperties:@{@"settingName" : settingName, @"value" : value}];
        [[Mixpanel sharedInstance] track:@"settingChange" properties:@{@"settingName" : settingName, @"value" : value}];
    } else {
        NSLog(@"[USAGE ANALYTICS]: setting - setting:%@ value:%@", settingName, value);
    }

}

+ (void)trackPurchaseDecision:(BOOL)b forProductId:(NSString *)productId {
    if (isRelease) {
        NSDictionary *props = @{@"productId" : safe(productId), @"clickedYes" : @(b)};
        [Heap track:@"purchaseDecision" withProperties:props];
        [[Mixpanel sharedInstance] track:@"purchaseDecision" properties:props];

        [[AppsFlyerTracker sharedTracker] trackEvent:@"purchaseDecision" withValue:productId];
        [FBAppEvents logEvent:@"purchaseDecision" parameters:props];
        if (b) {
            [FBAppEvents logEvent:FBAppEventNameAddedToCart parameters:props];
            [Optimizely trackEvent:@"decidedToPurchase"];
        }

    } else {
        NSLog(@"[USAGE ANALYTICS]: purchaseDecision - productId:%@", productId);
    }
}

+ (void)trackAccountThatCantPurchase {
    if (isRelease) {
        [Heap track:@"accountCantPurchase"];
        [[Mixpanel sharedInstance] track:@"accountCantPurchase"];
    } else {
        NSLog(@"[USAGE ANALYTICS]: accountCantPurchase");
    }
}

+ (void)trackPurchaseCompleted:(NSString *)productId atPrice:(NSNumber *)price andCurrency:(NSString *)currency {
    if (isRelease) {
        NSDictionary *props = @{@"productId" : productId, @"price" : price, @"currency" : currency};
        [Heap track:@"purchaseCompleted" withProperties:props];
        [[Mixpanel sharedInstance].people trackCharge:price withProperties:props];
        [FBAppEvents logPurchase:[price doubleValue] currency:currency parameters:@{@"productId" : productId}];
        [Optimizely trackEvent:@"purchaseCompleted"];
    } else {
        NSLog(@"[USAGE ANALYTICS]: trackPurchaseCompleted - productId:%@ price:%@ currency:%@", productId, price, currency);
    }
}

+ (void)trackPurchaseTransactionState:(SKPaymentTransaction *)transaction {

    NSString *stateString = @"";
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
        default:
            stateString = @"Unknown";
            break;
    }

    NSDictionary *props = @{
            @"state" : stateString,
            @"productId" : safe(transaction.payment.productIdentifier),
            @"transactionId" : safe(transaction.transactionIdentifier)
    };

    if (isRelease) {
        [Heap track:@"purchaseTransactionState" withProperties:props];
        [[Mixpanel sharedInstance] track:@"purchaseTransactionState" properties:props];
        [FBAppEvents logEvent:@"purchaseTransactionState" parameters:props];
        if (transaction.transactionState == SKPaymentTransactionStatePurchasing) {
            [FBAppEvents logEvent:FBAppEventNameInitiatedCheckout parameters:props];
        }
    } else {
        NSLog(@"[USAGE ANALYTICS]: purchaseTransactionState - txId:%@ state:%@ productId:%@", transaction.transactionIdentifier, stateString, transaction.payment.productIdentifier);
    }
}

@end
