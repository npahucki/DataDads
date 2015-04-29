//
// Created by Nathan  Pahucki on 4/29/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FeatureManager.h"

// NOTE: This class is only for subclassing!
@interface InvitationCountBasedFeature : NSObject <DDApplicationFeature>

// Must be overridden by subclasses.
- (BOOL)canUnlock:(FollowConnectionInvitationCount *)count;


@end