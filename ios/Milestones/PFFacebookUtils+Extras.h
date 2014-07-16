//
//  PFFacebookUtils+PFFacebookUtils_Extras.h
//  Milestones
//
//  Created by Nathan  Pahucki on 6/5/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <Parse/Parse.h>
#import <Parse/PFFacebookUtils.h>

#define FB_PUBLISH_PERMISSION_ARRAY @[@"publish_actions",@"email",@"public_profile"]

@interface PFFacebookUtils (PFFacebookUtils_Extras)

+ (void)shareAchievement:(MilestoneAchievement *)achievement block:(PFBooleanResultBlock)block;

+ (BOOL)userHasAuthorizedPublishPermissions:(PFUser *)user;

+ (void)ensureHasPublishPermissions:(ParentUser *)user block:(PFBooleanResultBlock)block;

+ (void)populateCurrentUserDetailsFromFacebook:(ParentUser *)user block:(PFBooleanResultBlock)block;

+ (BOOL)showAlertIfFacebookDisplayableError:(NSError *)error;

@end
