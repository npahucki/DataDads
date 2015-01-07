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
@dynamic otherPartyAuxDisplayName;
@dynamic otherPartyAvatar;

+ (NSString *)parseClassName {
    return @"Parse.Cloud.FollowConnections"; // Not a real Parse Entity - only returned from Cloud Code function.
}

- (void)deleteInBackgroundWithBlock:(PFBooleanResultBlock)block {

}

- (void)resendInvitationInBackgroundWithBlock:(PFBooleanResultBlock)block {

}

- (void)acceptInvitationInBackgroundWithBlock:(PFBooleanResultBlock)block {

}

@end
