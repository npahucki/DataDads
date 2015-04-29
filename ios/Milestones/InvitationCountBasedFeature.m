//
// Created by Nathan  Pahucki on 4/29/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "InvitationCountBasedFeature.h"


@implementation InvitationCountBasedFeature

- (BFTask *)checkForUnlockStatus {
    return [[FollowConnection countMyInvites] continueWithSuccessBlock:^id(BFTask *task) {
        FollowConnectionInvitationCount *counts = task.result;
        BOOL canUnlock = [self canUnlock:counts];
        return [BFTask taskWithResult:@(canUnlock)];
    }];
}

- (BOOL)canUnlock:(FollowConnectionInvitationCount *)count {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

@end