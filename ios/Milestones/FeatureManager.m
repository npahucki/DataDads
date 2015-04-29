//
// Created by Nathan  Pahucki on 4/29/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "FeatureManager.h"


@implementation FeatureManager

+ (void)ensureFeatureUnlocked:(id <DDApplicationFeature>)feature withBlock:(PFBooleanResultBlock)block {
    [[feature checkForUnlockStatus] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
        BOOL result = ((NSNumber *) task.result).boolValue;
        block(result, task.error);
        return nil;
    }];
}

@end