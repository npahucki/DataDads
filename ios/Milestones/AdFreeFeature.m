//
// Created by Nathan  Pahucki on 4/29/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "AdFreeFeature.h"


@implementation AdFreeFeature

- (BOOL)canUnlock:(FollowConnectionInvitationCount *)count {
    // TODO: Read from MPTweakValue
    return count.numberOfInvitesSent >= 3;
}


@end