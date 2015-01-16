//
//  FollowConnection.h
//  DataParenting
//
//  Created by Nathan  Pahucki on 1/6/15.
//  Copyright (c) 2015 DataParenting. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FollowConnection : PFObject <PFSubclassing>

@property(readonly) BOOL isInviter;
@property(readonly) NSDate *inviteSentOn;
@property(readonly) NSDate *inviteAcceptedOn;
@property(readonly) NSString *otherPartyEmail;
@property(readonly) NSString *otherPartyDisplayName;
@property(readonly) NSString *otherPartyAuxDisplayName;
@property(readonly) NSString *otherPartyAvatar;


- (void)resendInvitationInBackgroundWithBlock:(PFBooleanResultBlock)block;

- (void)acceptInvitationInBackgroundWithBlock:(PFBooleanResultBlock)block;
@end