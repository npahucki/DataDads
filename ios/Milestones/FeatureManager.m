//
// Created by Nathan  Pahucki on 4/29/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "FeatureManager.h"
#import "VideoFeature.h"
#import "AdFreeFeature.h"

@implementation FeatureManager


+ (BFTask *)ensureFeatureUnlocked:(DDApplicationFeatureType)featureType {
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

    return [feature checkForUnlockStatus];
}


+ (void)ensureFeatureUnlocked:(DDApplicationFeatureType)featureType withBlock:(PFBooleanResultBlock)block {
    [[self ensureFeatureUnlocked:featureType] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
        if (task.exception) {
            NSLog(@"BFTask caught exception:%@", task.exception);
            abort();
        }
        BOOL result = ((NSNumber *) task.result).boolValue;
        block(result, task.error);
        return nil;
    }];
}

@end