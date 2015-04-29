//
// Created by Nathan  Pahucki on 4/29/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "FeatureManager.h"
#import "VideoFeature.h"
#import "AdFreeFeature.h"

@implementation FeatureManager


+ (void)ensureFeatureUnlocked:(DDApplicationFeatureType)featureType withBlock:(PFBooleanResultBlock)block {

    NSString *featureUnlockCahcheKey = [NSString stringWithFormat:@"Feature-%lu-Unlock", (unsigned long) featureType];
    // TODO: What happens if they uninvite people..do we care?
    BOOL unlocked = [[NSUserDefaults standardUserDefaults] boolForKey:featureUnlockCahcheKey];

    if (unlocked) {
        block(YES, nil);
    } else {
        id <DDApplicationFeature> feature = nil;
        switch (featureType) {
            case DDApplicationFeatureAdRemoval:
                feature = [[AdFreeFeature alloc] init];
                break;
            case DDApplicationFeatureVideoSupport:
                feature = [[VideoFeature alloc] init];
                break;
            default:
                [NSException raise:@"Unknown Feature Type" format:@"The feature type %lu is invalid", (unsigned long) featureType];
        }

        [[feature checkForUnlockStatus] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
            BOOL result = ((NSNumber *) task.result).boolValue;
            if (result) [[NSUserDefaults standardUserDefaults] setBool:YES forKey:featureUnlockCahcheKey];
            block(result, task.error);
            return nil;
        }];
    }
}

@end