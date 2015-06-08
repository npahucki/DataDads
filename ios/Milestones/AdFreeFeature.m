//
// Created by Nathan  Pahucki on 4/29/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "AdFreeFeature.h"
#import "InAppPurchaseHelper.h"


@implementation AdFreeFeature

- (BFTask *)checkForUnlockStatus {
    // We want to leave ads unless they BOUGHT the video.
    return [self checkPurchaseForUnlockStatus];
}

- (BFTask *)checkPurchaseForUnlockStatus {
    BFTaskCompletionSource *completionSource = [[BFTaskCompletionSource alloc] init];
    // To allow people who have already purchased the video to keep using it......
    [[[InAppPurchaseHelper alloc] init] checkAdFreeProductPurchased:^(BOOL succeeded, NSError *error) {
        if (error) {
            [completionSource setError:error];
        } else {
            [completionSource setResult:@(succeeded)];
        }
    }];
    return completionSource.task;
}

@end