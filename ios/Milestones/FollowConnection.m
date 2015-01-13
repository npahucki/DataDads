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
@dynamic otherPartyEmail;

+ (NSString *)parseClassName {
    return @"Parse.Cloud.FollowConnections"; // Not a real Parse Entity - only returned from Cloud Code function.
}

- (void)deleteInBackgroundWithBlock:(PFBooleanResultBlock)block {
    [self executeCloudFuncitonNamed:@"deleteFollowConnection" andBlock:block];
}

- (void)resendInvitationInBackgroundWithBlock:(PFBooleanResultBlock)block {
    [self executeCloudFuncitonNamed:@"resendFollowConnectionInvitation" andBlock:block];
}

- (void)acceptInvitationInBackgroundWithBlock:(PFBooleanResultBlock)block {
    [self executeCloudFuncitonNamed:@"acceptFollowConnectionInvitation" andBlock:block];
}

- (void)executeCloudFuncitonNamed:(NSString *)functionName andBlock:(PFBooleanResultBlock)block {
    [PFCloud                    callFunctionInBackground:functionName withParameters:@{
            @"appVersion" : NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"],
            @"connectionObjectId" : self.objectId} block:^(id object, NSError *error) {

        if(error) {
            // TODO: Retries....
        }

        if (block) {
            block(((NSNumber *) object).boolValue, error);
        }
    }];
}


@end
