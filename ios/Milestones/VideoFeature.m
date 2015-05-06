//
// Created by Nathan  Pahucki on 4/29/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "VideoFeature.h"
#import "VideoSupportUnlockView.h"


@implementation VideoFeature {
}

- (BFTask *)checkForUnlockStatus {
    BOOL useAcceptedInvites = MPTweakValue(@"UnlockVideoUseAcceptedInvites", NO);
    NSInteger targetNumber = useAcceptedInvites ? MPTweakValue(@"UnlockVideoInviteAcceptedTargetNumber", 2) : MPTweakValue(@"UnlockVideoInviteSentTargetNumber", 10);


    return [[FollowConnection countMyInvites] continueWithSuccessBlock:^id(BFTask *task) {
        FollowConnectionInvitationCount *counts = task.result;
        BOOL canUnlock = (useAcceptedInvites ? counts.numberOfInvitesResultingInInstalls : counts.numberOfInvitesSent) >= targetNumber;
        if (canUnlock) {
            return [BFTask taskWithResult:@(YES)];
        } else {
            VideoSupportUnlockView *v = [[VideoSupportUnlockView alloc] init];
            v.targetInviteNumber = targetNumber;
            v.currentInviteNumber = counts.numberOfInvitesSent;
            v.useAcceptedInvites = useAcceptedInvites;
            return [v show];
        }
    }];
}


@end