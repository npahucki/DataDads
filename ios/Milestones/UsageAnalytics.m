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
#import "NSError+AsDictionary.h"


static id safe(id object) {
    return object ?: [NSNull null];
}

static NSDictionary *safeForFB(NSDictionary *dict) {
    NSMutableDictionary *fbFriendlyDictionary = [[NSMutableDictionary alloc] initWithCapacity:dict.count];
    for (id key in dict.allKeys) {
        NSString *fbKey;
        if ([key isKindOfClass:[NSString class]]) {
            fbKey = [(NSString *) key stringByReplacingOccurrencesOfString:@"." withString:@"_"];
        } else {
            fbKey = key;
        }

        id value = dict[key];
        // Skip null keys.
        if (value != [NSNull null]) {
            fbFriendlyDictionary[fbKey] = value;
        }
    }
    return fbFriendlyDictionary;
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
    [Heap setAppId:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"DP.HeapAppId"]];
    [Heap changeInterval:30];
    NSString *mixPanelKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"DP.MixPanelKey"];
    Mixpanel *mixpanel = [Mixpanel sharedInstanceWithToken:mixPanelKey launchOptions:launchOptions];
    NSString *uxCamKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"DP.UXCamKey"];
    [UXCam startApplicationWithKey:uxCamKey];

    if (isRelease) {
        [AppsFlyerTracker sharedTracker].appsFlyerDevKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"DP.AppsFlyerDevKey"];
        [AppsFlyerTracker sharedTracker].appleAppID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"DP.AppleStoreId"];
        [AppsFlyerTracker sharedTracker].isHTTPS = YES;
        [AppsFlyerTracker sharedTracker].customerUserID = mixpanel.distinctId;
        [[AppsFlyerTracker sharedTracker] trackAppLaunch];
    }
}

+ (void)identify:(ParentUser *)user {
    NSAssert([NSThread isMainThread], @"UsagaeAnalytics.identify called using a thread other than main!");
    if (user) {
        NSAssert(user.objectId != nil, @"Expected user would have objectId set already");
        BOOL isLinkedWithFB = [PFFacebookUtils isLinkedWithUser:user];
        NSMutableDictionary *props = [[NSMutableDictionary alloc] initWithDictionary:@{
                @"user.id" : safe(user.objectId),
                @"user.anonymous" : user.email ? @"N" : @"Y",
                @"user.fullName" : safe(user.fullName),
                @"user.linkedToFacebook" : isLinkedWithFB ? @"Y" : @"N",
                @"user.emailVerified" : [user objectForKey:@"emailVerified"] ? @"Y" : @"N",
                @"user.sex" : user.isMale ? @"M" : @"F"
        }];
        // Don't add if null, this causes problems in Heap!
        if (user.email) props[@"email"] = user.email;

        if (isRelease) {
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [Heap identify:props];
            [UXCam tagUsersName:user.objectId additionalData:user.email];
            [UXCam addTag:user.isMale ? @"male" : @"female"];
            [UXCam addTag:user.email ? @"anonymous" : @"signedup"];
            [mixpanel identify:mixpanel.distinctId];
            if (user.email) props[@"$email"] = user.email;
            [mixpanel.people set:props];
            [mixpanel.people setOnce:@{@"createdAt" : [NSDate date]}];
        } else {
            NSLog(@"[USAGE ANALYTICS]: Identify - %@", props);
        }
    }
}

+ (void)trackError:(NSError *)error forOperationNamed:(NSString *)operation {
    [self trackError:error forOperationNamed:operation andAdditionalProperties:nil];
}

+ (void)trackError:(NSError *)error forOperationNamed:(NSString *)operation andAdditionalProperties:(NSDictionary *)props {
    NSMutableDictionary *combinedAttributes = [error asDictionary];
    if (props) [combinedAttributes addEntriesFromDictionary:props];
    combinedAttributes[@"operation"] = operation;
    combinedAttributes[@"timestamp"] = [[NSDate date] asISO8601String];

    if (isRelease) {
        [Heap track:[NSString stringWithFormat:@"Error"] withProperties:combinedAttributes];
        [[Mixpanel sharedInstance] track:@"Error" properties:combinedAttributes];
    } else {
        NSLog(@"[USAGE ANALYTICS]: trackError - Error Properties:%@", combinedAttributes);
    }
}

+ (void)trackSignupDecisionOnScreen:(NSString *)screen withChoice:(BOOL)choice {
    if (isRelease) {
        NSDictionary *props = @{
                @"screen" : safe(screen),
                @"decision" : @(choice)
        };
        [Heap track:@"userSignUpDecision" withProperties:props];
        [[Mixpanel sharedInstance] track:@"userSignUpDecision" properties:props];
    } else {
        NSLog(@"[USAGE ANALYTICS]: userSignUpDecision - Screen:%@ Decision:%@", screen, @(choice));
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
                [FBAppEvents logEvent:FBAppEventNameCompletedRegistration parameters:safeForFB(props)];
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
            [FBAppEvents logEvent:FBAppEventNameCompletedRegistration parameters:safeForFB(props)];
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
            [FBAppEvents logEvent:@"userLinkedWithFacebook" parameters:safeForFB(props)];
            [[AppsFlyerTracker sharedTracker] trackEvent:@"userLinkedWithFacebook" withValue:@""];
        } else {
            NSLog(@"[USAGE ANALYTICS]: trackUserLinkedWithFacebook - User:%@ Publish:%d", user, publish);
        }
    }
}

+ (void)trackUserSignout:(ParentUser *)user {
    if (isRelease) {
        [Heap track:@"userSignedOut" withProperties:@{@"user.id" : safe(user.objectId)}];
        [[Mixpanel sharedInstance] track:@"userSignedOut" properties:@{@"user.id" : safe(user.objectId)}];
        [FBAppEvents logEvent:@"userSignedOut" parameters:@{@"user_id" : safe(user.objectId)}];
        [[AppsFlyerTracker sharedTracker] trackEvent:@"userSignedOut" withValue:@""];
    } else {
        NSLog(@"[USAGE ANALYTICS]: trackUserSignout - User:%@", user);
    }
}

+ (void)trackAppInstalled {
    if (isRelease) {
        [Heap track:@"installApp"];
        [[Mixpanel sharedInstance] track:@"installApp"];
    } else {
        NSLog(@"[USAGE ANALYTICS]: trackAppInstalled");
    }
}


+ (void)trackAppBecameActive {
    if (isRelease) {
        [FBAppEvents activateApp];
        [Heap track:@"activateApp"];
        [[Mixpanel sharedInstance] track:@"activateApp"];
        [[Mixpanel sharedInstance].people increment:@"timesAppActivated" by:@(1)];
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
        [FBAppEvents logEvent:@"babyCreated" parameters:safeForFB(props)];
        [[AppsFlyerTracker sharedTracker] trackEvent:@"babyCreated" withValue:props.description];

        // Add baby properties
        [[Mixpanel sharedInstance].people set:props];
        [Heap identify:props];
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
        } else if (achievement.isSkipped) {
            NSDictionary *props = @{
                    @"user.id" : safe(achievement.baby.parentUser.objectId),
                    @"baby.id" : safe(achievement.baby.objectId),
                    @"milestoneId" : safe(achievement.standardMilestone.objectId)
            };
            [Heap track:@"milestoneSkipped" withProperties:props];
            [[Mixpanel sharedInstance] track:@"milestoneSkipped" properties:props];
            [[Mixpanel sharedInstance].people increment:@"milestonesSkipped" by:@(1)];
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
            [FBAppEvents logEvent:@"achievementLogged" parameters:safeForFB(props)];
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
        [[Mixpanel sharedInstance].people increment:@"measurementsLogged" by:@(1)];
    } else {
        NSLog(@"[USAGE ANALYTICS]: trackMeasurement - Measurement:%@", measurement);
    }
}

+ (void)trackAchievementShared:(MilestoneAchievement *)achievement sharingMedium:(NSString *)medium {
    medium = [medium stringByReplacingOccurrencesOfString:@"com.apple.UIKit.activity." withString:@""];
    NSDictionary *props = @{
            @"achievement.isStandard" : achievement.standardMilestone ? @"Y" : @"N",
            @"achievement.standardMilestoneId" : safe(achievement.standardMilestone.objectId),
            @"achievement.title" : safe(achievement.displayTitle),
            @"achievement.attachmentType" : safe(achievement.attachmentType),
            @"achievement.hasAttachment" : achievement.attachmentType ? @"Y" : @"N",
            @"achievement.hasCustomTitle" : achievement.customTitle ? @"Y" : @"N",
            @"achievement.hasComment" : achievement.comment ? @"Y" : @"N",
    };

    if (isRelease) {
        [Heap track:@"achievementShared" withProperties:props];
        [[Mixpanel sharedInstance] track:@"achievementShared" properties:props];
        [[Mixpanel sharedInstance].people increment:@"achievementsShared" by:@(1)];
        [FBAppEvents logEvent:@"achievementShared" parameters:safeForFB(props)];
    } else {
        NSLog(@"[USAGE ANALYTICS]: trackAchievementShared via %@ : %@", medium, props);
    }
}

+ (void)trackTipShared:(Tip *)tip sharingMedium:(NSString *)medium {
    medium = [medium stringByReplacingOccurrencesOfString:@"com.apple.UIKit.activity." withString:@""];
    NSDictionary *props = @{
            @"tip.title" : safe(tip.title),
            @"tip.id" : safe(tip.objectId),
            @"tip.type" : tip.tipType == TipTypeGame ? @"game" : @"normal"
    };

    if (isRelease) {
        [Heap track:@"tipShared" withProperties:props];
        [[Mixpanel sharedInstance] track:@"tipShared" properties:props];
        [[Mixpanel sharedInstance].people increment:@"tipsShared" by:@(1)];
        [FBAppEvents logEvent:@"tipShared" parameters:safeForFB(props)];
    } else {
        NSLog(@"[USAGE ANALYTICS]: trackTipShared via %@: %@", medium, props);
    }

}


+ (void)trackSearch:(NSString *)filterString {
    if (isRelease) {
        [Heap track:@"searchExecuted" withProperties:@{@"filterString" : filterString}];
        [FBAppEvents logEvent:FBAppEventNameSearched parameters:@{FBAppEventParameterNameSearchString : filterString}];
        [[Mixpanel sharedInstance] track:@"searchExecuted" properties:@{@"filterString" : filterString}];
        [[Mixpanel sharedInstance].people increment:@"searchesExecuted" by:@(1)];
    } else {
        NSLog(@"[USAGE ANALYTICS]: trackSearch - Filter:%@", filterString);
    }
}

+ (void)trackAdClicked:(NSString *)adIdentifier {
    if (isRelease) {
        [Heap track:@"adClicked" withProperties:@{@"adIdentifier" : adIdentifier}];
        [[Mixpanel sharedInstance] track:@"adClicked" properties:@{@"adIdentifier" : adIdentifier}];
        [[Mixpanel sharedInstance].people increment:@"adsClicked" by:@(1)];
        [[AppsFlyerTracker sharedTracker] trackEvent:@"adIdentifier" withValue:adIdentifier];
        [FBAppEvents logEvent:@"adClicked" parameters:@{@"adIdentifier" : adIdentifier}];
    } else {
        NSLog(@"[USAGE ANALYTICS]: trackAdClick - AdId:%@", adIdentifier);
    }
}

+ (void)trackTutorialManuallyTaken {
    if (isRelease) {
        [Heap track:@"tutotialManuallyTaken"];
        [[Mixpanel sharedInstance] track:@"tutotialManuallyTaken"];
        [[Mixpanel sharedInstance].people set:@"tutotialManuallyTaken" to:@(YES)];
        [FBAppEvents logEvent:FBAppEventNameCompletedTutorial];
    } else {
        NSLog(@"[USAGE ANALYTICS]: tutotialManuallyTaken");
    }
}

//+ (void)trackTutorialResponse:(BOOL)viewed {
//    if (isRelease) {
//        [Heap track:@"respondedToTutoriaPrompt" withProperties:@{@"viewed" : @(viewed)}];
//        [[Mixpanel sharedInstance] track:@"respondedToTutoriaPrompt" properties:@{@"viewed" : @(viewed)}];
//        [[Mixpanel sharedInstance].people set:@"tutorialTaken" to:@(viewed)];
//        [FBAppEvents logEvent:FBAppEventNameCompletedTutorial];
//    } else {
//        NSLog(@"[USAGE ANALYTICS]: respondedToTutoriaPrompt - viewed:%d", viewed);
//    }
//}

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
        [[Mixpanel sharedInstance].people set:@"attemptedPurchase" to:@(YES)];
        [[AppsFlyerTracker sharedTracker] trackEvent:@"purchaseDecision" withValue:productId];
        [FBAppEvents logEvent:@"purchaseDecision" parameters:safeForFB(props)];
        if (b) {
            [FBAppEvents logEvent:FBAppEventNameAddedToCart parameters:props];
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
        NSDictionary *props = @{@"productId" : safe(productId), @"price" : safe(price), @"currency" : safe(currency)};
        [Heap track:@"purchaseCompleted" withProperties:props];
        [[Mixpanel sharedInstance].people trackCharge:price withProperties:props];
        [[Mixpanel sharedInstance].people increment:@"purchasesCompleted" by:@(1)];
        [FBAppEvents logPurchase:[price doubleValue] currency:currency parameters:@{@"productId" : productId}];
    } else {
        NSLog(@"[USAGE ANALYTICS]: trackPurchaseCompleted - productId:%@ price:%@ currency:%@", productId, price, currency);
    }
}

+ (void)trackPurchaseRestored:(NSString *)productId {
    if (isRelease) {
        NSDictionary *props = @{@"productId" : safe(productId)};
        [Heap track:@"purchaseRestored" withProperties:props];
        [[Mixpanel sharedInstance] track:@"purchaseRestored"];
    } else {
        NSLog(@"[USAGE ANALYTICS]: purchaseRestored - productId:%@", productId);
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
        [FBAppEvents logEvent:@"purchaseTransactionState" parameters:safeForFB(props)];
        if (transaction.transactionState == SKPaymentTransactionStatePurchasing) {
            [FBAppEvents logEvent:FBAppEventNameInitiatedCheckout parameters:safeForFB(props)];
        }
    } else {
        NSLog(@"[USAGE ANALYTICS]: purchaseTransactionState - txId:%@ state:%@ productId:%@", transaction.transactionIdentifier, stateString, transaction.payment.productIdentifier);
    }
}

+ (void)trackUserDeniedAddressBookAccess {
    if (isRelease) {
        [Heap track:@"userDeniedAddressBookAccess"];
        [[Mixpanel sharedInstance] track:@"userDeniedAddressBookAccess"];
        [[Mixpanel sharedInstance].people set:@"deniedAddressBookAccess" to:@(YES)];
    } else {
        NSLog(@"[USAGE ANALYTICS]: userDeniedAddressBookAccess");
    }
}

+ (void)trackFollowConnectionInviteSent:(NSInteger)count {
    if (isRelease) {
        NSDictionary *props = @{@"count" : @(count)};
        [Heap track:@"followConnectionInviteSent" withProperties:props];
        [[Mixpanel sharedInstance] track:@"followConnectionInviteSent" properties:props];
        [[Mixpanel sharedInstance].people increment:@"followInvitesSent" by:@(count)];
        [[Mixpanel sharedInstance].people increment:@"followInvitesTimesSent" by:@(1)];
    } else {
        NSLog(@"[USAGE ANALYTICS]: followConnectionInviteSent - count:%d", count);
    }
}

+ (void)trackFollowConnectionInviteResponse:(BOOL)accepted {
    if (isRelease) {
        NSDictionary *properties = @ {
                @"accepted" : @(accepted)
        };

        [Heap track:@"followConnectionInviteResponse" withProperties:properties];
        [[Mixpanel sharedInstance] track:@"followConnectionInviteResponse" properties:properties];
        [[Mixpanel sharedInstance].people increment:@"followInvitesAccepted" by:@(1)];
    } else {
        NSLog(@"[USAGE ANALYTICS]: followConnectionInviteResponse - accepted:%d", accepted);
    }
}

+ (void)trackFollowConnectionRevokeInvite {
    if (isRelease) {
        [Heap track:@"followConnectionInviteRevoked"];
        [[Mixpanel sharedInstance] track:@"followConnectionInviteRevoked"];
        [[Mixpanel sharedInstance].people increment:@"followInvitesRevoked" by:@(1)];
    } else {
        NSLog(@"[USAGE ANALYTICS]: followConnectionInviteRevoked");
    }
}

+ (void)trackFollowConnectionRemoveConnection {
    if (isRelease) {
        [Heap track:@"followConnectionBroken"];
        [[Mixpanel sharedInstance] track:@"followConnectionBroken"];
        [[Mixpanel sharedInstance].people increment:@"followConnectionsBroken" by:@(1)];
    } else {
        NSLog(@"[USAGE ANALYTICS]: followConnectionBroken");
    }
}

+ (void)trackSignupTrigger:(NSString *)trigger withChoice:(BOOL)choice {
    if (isRelease) {
        NSDictionary *properties = @ {
                @"trigger" : trigger,
                @"choice" : @(choice)
        };

        [Heap track:@"signUpDecision" withProperties:properties];
        [[Mixpanel sharedInstance] track:@"signUpDecision" properties:properties];
    } else {
        NSLog(@"[USAGE ANALYTICS]: signUpDecision - trigger:%@, decision:%d", trigger, choice);
    }
}
@end
