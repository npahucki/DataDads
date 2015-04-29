//
// Created by Nathan  Pahucki on 4/29/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "VideoFeature.h"


@implementation VideoFeature {

}

- (BOOL)canUnlock:(FollowConnectionInvitationCount *)count {
    return count.numberOfInvitesSent > 10;
}

@end