//
//  FollowConnection.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 1/6/15.
//  Copyright (c) 2015 DataParenting. All rights reserved.
//

#import <PFCloud+Cache/PFCloud+Cache.h>
#import "BFTask.h"
#import "InviteContactsAddressBookDataSource.h"

@implementation FollowConnectionInvitationCount
@end

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

+ (BFTask *)sendInvites:(NSArray *)inviteContacts {
    NSMutableArray *inviteArray = [[NSMutableArray alloc] initWithCapacity:inviteContacts.count];
    for (InviteContact *contact in inviteContacts) {
        NSAssert(contact.emailAddress, @"Unexpected nil emailAddress");
        [inviteArray addObject:@{
                @"sendToName" : contact.fullName ? contact.fullName : [NSNull null],
                @"sendToEmail" : contact.emailAddress.lowercaseString
        }];
    }
    [UsageAnalytics trackFollowConnectionInviteSent:[inviteArray count]];
    [self clearInviteCountCache];
    return [PFCloud callFunctionInBackground:@"sendFollowInvitation" withParameters:@{
            @"appVersion" : NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"],
            @"invites" : inviteArray}];
}

- (void)deleteInBackgroundWithBlock:(PFBooleanResultBlock)block {
    [FollowConnection clearInviteCountCache];
    [self executeCloudFunctionNamed:@"deleteFollowConnection" andBlock:block];
}

- (void)resendInvitationInBackgroundWithBlock:(PFBooleanResultBlock)block {
    [self executeCloudFunctionNamed:@"resendFollowConnectionInvitation" andBlock:block];
}

- (void)acceptInvitationInBackgroundWithBlock:(PFBooleanResultBlock)block {
    [self executeCloudFunctionNamed:@"acceptFollowConnectionInvitation" andBlock:block];
}

- (void)executeCloudFunctionNamed:(NSString *)functionName andBlock:(PFBooleanResultBlock)block {
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

+ (BFTask *)countMyInvites {
    BFTask *countLookup = [PFCloud callFunctionInBackground:@"countMyFollowInvitations"
                                             withParameters:[self paramsForInviteCountLookup]
                                                cachePolicy:kPFCachePolicyCacheElseNetwork];

    return [countLookup continueWithSuccessBlock:^id(BFTask *task) {
        FollowConnectionInvitationCount *counts = [[FollowConnectionInvitationCount alloc] init];
        NSDictionary *countResult = task.result;
        counts.numberOfInvitesSent = ((NSNumber *) countResult[@"invitesSent"]).integerValue;
        counts.numberOfInvitesResultingInInstalls = ((NSNumber *) countResult[@"signUpsFromInvites"]).integerValue;
        return [BFTask taskWithResult:counts];
    }];

}

+ (void)clearInviteCountCache {
    [PFCloud clearCachedResult:@"countMyFollowInvitations" withParameters:[self paramsForInviteCountLookup]];
}

+ (NSDictionary *)paramsForInviteCountLookup {
    return @{
            @"appVersion" : NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"]
    };
}

@end
