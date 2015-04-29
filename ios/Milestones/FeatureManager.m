//
// Created by Nathan  Pahucki on 4/29/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "FeatureManager.h"
#import "VideoFeature.h"
#import "AdFreeFeature.h"

@implementation FeatureManager


+ (void)ensureFeatureUnlocked:(DDApplicationFeatureType)featureType withBlock:(PFBooleanResultBlock)block {
    id <DDApplicationFeature> feature = nil;
    switch (featureType) {
        case DDApplicationFeatureAdRemoval:
            feature = [[AdFreeFeature alloc] init];
            break;
        case DDApplicationFeatureVideoSupport:
            feature = [[VideoFeature alloc] init];
            break;
        default:
            [NSException raise:@"Unknown Feature Type" format:@"The feature type %d is invalid", featureType];
    }

    [[feature checkForUnlockStatus] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
        BOOL result = ((NSNumber *) task.result).boolValue;
        block(result, task.error);
        return nil;
    }];
}

@end