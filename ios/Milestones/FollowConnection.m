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
#import "BFExecutor.h"

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
    NSAssert([ParentUser currentUser].isLoggedIn, @"Expected user to be signed in already!");
    NSMutableArray *inviteArray = [[NSMutableArray alloc] initWithCapacity:inviteContacts.count];
    for (InviteContact *contact in inviteContacts) {
        NSAssert(contact.emailAddress, @"Unexpected nil emailAddress");
        [inviteArray addObject:@{
                @"sendToName" : contact.fullName ? contact.fullName : [NSNull null],
                @"sendToEmail" : contact.emailAddress.lowercaseString
        }];
    }
    [UsageAnalytics trackFollowConnectionInviteSent:[inviteArray count]];
    return [[PFCloud callFunctionInBackground:@"sendFollowInvitation" withParameters:@{
            @"appVersion" : NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"],
            @"invites" : inviteArray}] continueWithExecutor:[BFExecutor mainThreadExecutor] withSuccessBlock:^id(BFTask *task) {
        [self clearInviteCountCache];
        return [BFTask taskWithResult:task.result];
    }];
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

+ (BFTask *)countMyInvitesSent {
    return [[self myFollowConnectionsWithCachePolicy:kPFCachePolicyCacheElseNetwork] continueWithSuccessBlock:^id(BFTask *task) {
        NSArray *invites = task.result;
        return [BFTask taskWithResult:@(invites.count)];
    }];
}


+ (BFTask *)myFollowConnectionsWithCachePolicy:(PFCachePolicy)policy {
    // We can only call this method if the user is logged in, and they can not
    // have any connections if they are not logged in.
    if ([ParentUser currentUser].isLoggedIn) {
        return [PFCloud callFunctionInBackground:@"queryMyFollowConnections"
                                  withParameters:[self paramsForInviteLookup]
                                     cachePolicy:policy];
    } else {
        return [BFTask taskWithResult:@[]]; // Empty array
    }
}

+ (void)clearInviteCountCache {
    [PFCloud clearCachedResult:@"queryMyFollowConnections" withParameters:[self paramsForInviteLookup]];
}

+ (NSDictionary *)paramsForInviteLookup {
    return @{@"appVersion" : NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"],
            @"limit" : [@(1000) stringValue]};
}

@end
