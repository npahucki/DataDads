//
//  FollowConnection.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 1/6/15.
//  Copyright (c) 2015 DataParenting. All rights reserved.
//

@implementation FollowConnection


@dynamic inviteSentOn;
@dynamic inviteAcceptedOn;
@dynamic isInviter;
@dynamic otherPartyDisplayName;
@dynamic otherPartyAvatar;

+ (NSString *)parseClassName {
    return @"Parse.Cloud.FollowConnections"; // Not a real entiry, only returned from Cloud Code function.
}

@end
