//
// Created by Nathan  Pahucki on 4/29/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "VideoFeature.h"
#import "VideoSupportUnlockView.h"
#import "InAppPurchaseHelper.h"


@implementation VideoFeature {
}

- (BFTask *)checkForUnlockStatus {
    return [[self checkPurchaseForUnlockStatus] continueWithSuccessBlock:^id(BFTask *task) {
        if ([((NSNumber *) task.result) boolValue]) {
            return task;
        } else {
            return [self checkConnectionsForUnlockStatus];
        }
    }];
}

- (BFTask *)checkPurchaseForUnlockStatus {
    BFTaskCompletionSource *completionSource = [[BFTaskCompletionSource alloc] init];
    // To allow people who have already purchased the video to keep using it......
    [[[InAppPurchaseHelper alloc] init] checkProductPurchased:DDProductVideoSupport withBlock:^(BOOL succeeded, NSError *error) {
        if (error) {
            [completionSource setError:error];
        } else {
            [completionSource setResult:@(succeeded)];
        }
    }];
    return completionSource.task;
}


- (BFTask *)checkConnectionsForUnlockStatus {
    return [[FollowConnection myFollowConnectionsWithCachePolicy:kPFCachePolicyCacheElseNetwork] continueWithExecutor:[BFExecutor mainThreadExecutor] withSuccessBlock:^id(BFTask *task) {
        BOOL useAcceptedInvites = MPTweakValue(@"UnlockVideoUseAcceptedInvites", NO);
        NSInteger targetNumber = useAcceptedInvites ? MPTweakValue(@"UnlockVideoInviteAcceptedTargetNumber", 2) : MPTweakValue(@"UnlockVideoInviteSentTargetNumber", 10);
        NSArray *invites = task.result;
        NSInteger numberOfInvitesSent = 0;
        for (FollowConnection *conn in invites) if (conn.isInviter) numberOfInvitesSent++;
        BOOL canUnlock = numberOfInvitesSent >= targetNumber;
        if (canUnlock) {
            return [BFTask taskWithResult:@(YES)];
        } else {
            VideoSupportUnlockView *v = [[VideoSupportUnlockView alloc] init];
            v.targetInviteNumber = targetNumber;
            v.currentInviteNumber = numberOfInvitesSent;
            v.invites = invites;
            return [v show];
        }
    }];
}


@end