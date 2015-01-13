//
//  PFFacebookUtils+PFFacebookUtils_Extras.m
//  Milestones
//
//  Created by Nathan  Pahucki on 6/5/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "NSDate+Utils.h"


@implementation PFFacebookUtils (PFFacebookUtils_Extras)

+ (void)shareAchievement:(MilestoneAchievement *)achievement block:(PFBooleanResultBlock)block {
    ParentUser *user = [ParentUser currentUser];
    [self ensureHasPublishPermissions:user block:^(BOOL succeeded, NSError *error) {
        if (error) {
            block(NO, error);
        } else {
            [self createFBNoteMilestoneAction:achievement block:block];
        }
    }];
}

+ (void)createFBNoteMilestoneAction:(MilestoneAchievement *)achievement block:(PFBooleanResultBlock)block {
    // First create the object, as we will need the object id
    [self createFBMilestoneObject:achievement block:^(NSString *fbMilestoneId, NSError *error) {
        if (error) {
            block(NO, error);
        } else {
            NSMutableDictionary <FBGraphObject> *action = [FBGraphObject graphObject];
            action[@"babymilestone"] = fbMilestoneId;
            action[@"explicitly_shared"] = @"true";
            action[@"fb:explicitly_shared"] = @"true";
            [FBRequestConnection startForPostWithGraphPath:@"me/dataparenting:note" graphObject:action
                                         completionHandler:^(FBRequestConnection *connection, id result, NSError *error2) {
                if (error2) {
                    block(NO, error2);
                } else {
                    block(YES, nil);
                }
            }];
        }
    }];
}

+ (void)createFBMilestoneObject:(MilestoneAchievement *)achievement block:(PFStringResultBlock)block {
            NSString *url = [NSString stringWithFormat:@"http://%@/achievements/%@", VIEW_HOST, achievement.objectId];
            NSMutableDictionary <FBOpenGraphObject> *object =
                    [FBGraphObject openGraphObjectForPostWithType:@"dataparenting:babymilestone"
                                                            title:achievement.displayTitle
                                                            image:achievement.attachmentThumbnail.url
                                                              url:url
                                                      description:@""];
            object[@"al:ios"] = @"http://www.dataparenting.com/app";
            object[@"data"] = @{@"baby_name" : achievement.baby.name,
                    @"baby_is_male" : @(achievement.baby.isMale),
                    @"completion_date" : [achievement.completionDate asISO8601String],
            };
            if (achievement.comment) object[@"data"][@"comment"] = achievement.comment;
            if (achievement.standardMilestone.url) object[@"see_also"] = achievement.standardMilestone.url;

            [FBRequestConnection startForPostOpenGraphObject:object completionHandler:^(FBRequestConnection *connection, id result, NSError *error2) {
                if (!error2) {
                    block([result objectForKey:@"id"], nil);
                } else {
                    block(nil, error2);
                }
            }];
}

+ (BOOL)userHasAuthorizedPublishPermissions:(PFUser *)user {
    return [PFFacebookUtils isLinkedWithUser:user] && [[[PFFacebookUtils session] permissions] containsObject:@"publish_actions"];
}

+ (void)ensureHasPublishPermissions:(PFUser *)user block:(PFBooleanResultBlock)block {
    if ([PFFacebookUtils isLinkedWithUser:user]) {
        if ([[[PFFacebookUtils session] permissions] containsObject:@"publish_actions"]) {
            block(YES, nil);
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Proceed?" message:@"You have to give us permission to publish on Facebook to share your milestones." delegate:nil cancelButtonTitle:@"Not Now" otherButtonTitles:@"Let's Do It", nil];
            [alert showWithButtonBlock:^(NSInteger buttonIndex) {
                if (buttonIndex == 0) {
                    // cancel
                    [UsageAnalytics trackUserLinkedWithFacebook:(ParentUser *) user forPublish:YES withError:[NSError errorWithDomain:@"DataParenting" code:kDDErrorUserRefusedFacebookPermissions userInfo:nil]];
                    block(NO, nil);
                } else {
                    // NOTE: If the user denies the auth, The call back is never called!
                    // We should file an issue with Parse over this.
                    [PFFacebookUtils reauthorizeUser:user withPublishPermissions:FB_PUBLISH_PERMISSION_ARRAY audience:FBSessionDefaultAudienceFriends block:^(BOOL succeeded, NSError *error) {
                        [UsageAnalytics trackUserLinkedWithFacebook:(ParentUser *) user forPublish:YES withError:error];
                        if (error) {
                            block(NO, error);
                        } else {
                            block(succeeded, nil);
                        }
                    }];
                }
            }];
        }
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Proceed?" message:@"You have to sign into Facebook to share." delegate:nil cancelButtonTitle:@"Not Now" otherButtonTitles:@"Let's Do It", nil];

        [alert showWithButtonBlock:^(NSInteger buttonIndex) {
            if (buttonIndex == 0) {
                // cancel
                block(NO, nil);
            } else {
                NSAssert(user != nil, @"Did not expect a anonymous user here!");
                [PFFacebookUtils linkUser:user permissions:FB_PUBLISH_PERMISSION_ARRAY block:^(BOOL succeeded, NSError *error) {
                    [UsageAnalytics trackUserLinkedWithFacebook:(ParentUser *) user forPublish:YES withError:error];
                    if (error) {
                        block(NO, error);
                    } else {
                        [PFFacebookUtils populateCurrentUserDetailsFromFacebook:(ParentUser *) user block:nil]; // this will be done in the background
                        block(succeeded, nil);
                    }
                }];
            }
        }];
    }
}

+ (void)populateCurrentUserDetailsFromFacebook:(ParentUser *)user block:(PFBooleanResultBlock)block {
    [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        [UsageAnalytics trackUserLinkedWithFacebook:user forPublish:NO withError:error];
        if (error) {
            if (block) block(NO, error);
        } else {
            NSString *facebookEMail = result[@"email"];
            NSString *usersName = result[@"name"];
            NSString *gender = result[@"gender"];

            if (facebookEMail.length) {
                user.email = facebookEMail;
                user.username = facebookEMail;
            }

            if ([@"male" isEqualToString:gender]) {
                user.isMale = YES;
            } else if ([@"female" isEqualToString:gender]) {
                user.isMale = NO;
            } // else don't set it

            if (usersName.length) {
                user.fullName = usersName;
            }
            [user saveEventually:block];
        }
    }];
}


+ (BOOL)showAlertIfFacebookDisplayableError:(NSError *)error {

    if ([error.domain isEqualToString:@"Parse"] && error.code == 208) {
        NSString *msg = @"There is another DataParenting account aready linked to that Facebook account. Please either use that DataParenting account, another Facebook account, or contact support.";
        [[[UIAlertView alloc] initWithTitle:@"Duplicate Facebook Account"
                                    message:msg
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
        return YES;
    } else if ([error.domain isEqualToString:@"com.facebook.sdk"] && [error.userInfo[@"com.facebook.sdk:ErrorLoginFailedReason"] isEqualToString:@"com.facebook.sdk:SystemLoginDisallowedWithoutError"]) {
        NSString *msg = @"Please go to Settings->Facebook and enable acceess for 'DataParenting', then try to log in again.";
        [[[UIAlertView alloc] initWithTitle:@"Facebook Login Is Disabled"
                                    message:msg
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
        return YES;
    } else if ([error.domain isEqualToString:@"com.facebook.sdk"] && [error.userInfo[@"com.facebook.sdk:ErrorLoginFailedReason"] isEqualToString:@"com.facebook.sdk:SystemLoginCancelled"]) {
        NSString *msg = @"Please go to Settings->Facebook and update your login information";
        [[[UIAlertView alloc] initWithTitle:@"Facebook Token Invalid"
                                    message:msg
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
        return YES;
    } else if ([error fberrorShouldNotifyUser]) {
        [[[UIAlertView alloc] initWithTitle:@"Facebook Login Failed"
                                    message:[error fberrorUserMessage]
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];

        return YES;
    } else {
        [UsageAnalytics trackError:error forOperationNamed:@"FacebookOperation"];
        return NO;
    }
}


@end
