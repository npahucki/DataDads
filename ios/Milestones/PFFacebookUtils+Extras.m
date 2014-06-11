//
//  PFFacebookUtils+PFFacebookUtils_Extras.m
//  Milestones
//
//  Created by Nathan  Pahucki on 6/5/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "PFFacebookUtils+Extras.h"
#import "NSDate+Utils.h"
#import "FacebookSDK/NSError+FBError.h"


@implementation PFFacebookUtils (PFFacebookUtils_Extras)

+(void) shareAchievement:(MilestoneAchievement*) achievement block:(PFBooleanResultBlock) block {
  ParentUser * user = [ParentUser currentUser];
  [self ensureHasPublishPermissions:user block:^(BOOL succeeded, NSError *error) {
    if(error) {
      block(NO,error);
    } else {
        [self createFBNoteMilestoneAction:achievement block:block];
    }
  }];
}

+(void) createFBNoteMilestoneAction:(MilestoneAchievement*) achievement block:(PFBooleanResultBlock) block {
  // First create the object, as we will need the object id
  [self createFBMilestoneObject:achievement block:^(NSString *fbMilestoneId, NSError *error) {
    if(error) {
      block(NO,error);
    } else {
      NSMutableDictionary<FBGraphObject> *action = [FBGraphObject graphObject];
      action[@"babymilestone"] = fbMilestoneId;
      action[@"explicitly_shared"] = @(YES);
      action[@"fb:explicitly_shared"] = @(YES);
      [FBRequestConnection startForPostWithGraphPath:@"me/dataparenting:note" graphObject:action
                                   completionHandler:^(FBRequestConnection *connection,id result,NSError *error) {
                                     if (error) {
                                       block(NO, error);
                                     } else {
                                       block(YES,nil);
                                     }
                                   }];
    }
  }];
}

+(void) createFBMilestoneObject:(MilestoneAchievement*) achievement block:(PFStringResultBlock) block {
  [self stageFile:achievement.attachment block:^(NSString *imageUrl, NSError *error) {
    if(error) {
      block(nil, error);
    } else {
      NSMutableDictionary<FBOpenGraphObject> *object =
      [FBGraphObject openGraphObjectForPostWithType:@"dataparenting:babymilestone"
                                              title:achievement.displayTitle
                                              image:imageUrl
                                                url:achievement.attachment.url
                                        description:@""];
      object[@"al:ios"] = @"http://www.dataparenting.com/app";
      object[@"data"] = @{@"baby_name" : achievement.baby.name,
                          @"baby_is_male" : @(achievement.baby.isMale),
                          @"completion_date" : [achievement.completionDate asISO8601String],
                          };
      if(achievement.comment) object[@"data"][@"comment"] = achievement.comment;
      if(achievement.standardMilestone.url) object[@"see_also"] = achievement.standardMilestone.url;


      [FBRequestConnection startForPostOpenGraphObject:object completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
          block([result objectForKey:@"id"], nil);
        } else {
          block(nil, error);
        }
      }];
    }
  }];
  
}

+(void) stageFile:(PFFile *) attachment  block:(PFStringResultBlock) block {
  if(attachment) {
    [attachment getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
      if(!error) {
        UIImage * image = [UIImage imageWithData:data];
        [FBRequestConnection startForUploadStagingResourceWithImage:image completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
          if(!error) {
            block([result objectForKey:@"uri"], nil);
          } else {
            block(nil, error);
          }
        }];
      } else {
        block(nil, error);
      }
    }];
  } else {
    block(nil, nil);
  }
  
  
  
}

+(BOOL) userHasAuthorizedPublishPermissions:(PFUser *) user {
  return [PFFacebookUtils isLinkedWithUser:user] && [[[PFFacebookUtils session] permissions] containsObject:@"publish_actions"];
}


+(void) ensureHasPublishPermissions:(PFUser *) user block:(PFBooleanResultBlock) block {
  if([PFFacebookUtils isLinkedWithUser:user]) {
    if([[[PFFacebookUtils session] permissions] containsObject:@"publish_actions"]) {
      block(YES,nil);
    } else {
     UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Proceed?" message:@"You have to give us permission to publish on Facebook to share your milestones." delegate:nil cancelButtonTitle:@"Not Now" otherButtonTitles:@"Let's Do It", nil];
      [alert showWithButtonBlock:^(NSInteger buttonIndex) {
        if(buttonIndex == 0) {
          // cancel
          block(NO, nil);
        } else {
          // NOTE: If the user denies the auth, The call back is never called!
          // We should file an issue with Parse over this. 
          [PFFacebookUtils reauthorizeUser:user withPublishPermissions:FB_PUBLISH_PERMISSION_ARRAY audience:FBSessionDefaultAudienceFriends block:^(BOOL succeeded, NSError *error) {
            if(error) {
              block(NO, error);
            } else {
              block(succeeded,nil);
            }
          }];
        }
      }];
    }
  } else {
     UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Proceed?" message:@"You have to sign into Facebook to share." delegate:nil cancelButtonTitle:@"Not Now" otherButtonTitles:@"Let's Do It", nil];
    
      [alert showWithButtonBlock:^(NSInteger buttonIndex) {
        if(buttonIndex == 0) {
          // cancel
          block(NO, nil);
        } else {
          NSAssert(user != nil, @"DId not expect a completely non logged in user here!");
          [PFFacebookUtils linkUser:user permissions:FB_PUBLISH_PERMISSION_ARRAY block:^(BOOL succeeded, NSError *error) {
            if(error) {
              block(NO, error);
            } else {
              [PFFacebookUtils populateCurrentUserDetailsFromFacebook:(ParentUser*)user block:nil]; // this will be done in the background
              block(succeeded,nil);
            }
          }];
        }
      }];
  }
}

+(void) populateCurrentUserDetailsFromFacebook: (ParentUser *) user block:(PFBooleanResultBlock) block {
  [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
    if (error) {
      if(block) block(NO,error);
    } else {
      NSString *facebookEMail = result[@"email"];
      NSString *firstName = result[@"first_name"];
      NSString *lastName = result[@"last_name"];
      NSString *username = result[@"username"];
      NSString *gender = result[@"gender"];
      
      if (facebookEMail.length) {
        user.email = facebookEMail;
        user.username = facebookEMail;
      }
      
      if([@"male" isEqualToString:gender]) {
        user.isMale = YES;
      } else if([@"female" isEqualToString:gender]) {
        user.isMale = NO;
      } // else don't set it
      
      // Only set if not set previously.
      if(!user.screenName) {
        if(firstName.length && lastName.length) {
          user.screenName = [NSString stringWithFormat:@"%@ %@.",firstName, [lastName substringToIndex:1]];
        } else {
          user.screenName = username;
        }
      }
      [user saveEventually:block];
    }
  }];
}


+(BOOL) showAlertIfFacebookDisplayableError:(NSError*) error {
  
  
  if([error.domain isEqualToString:@"com.facebook.sdk"] && [[error.userInfo objectForKey:@"com.facebook.sdk:ErrorLoginFailedReason"] isEqualToString:@"com.facebook.sdk:SystemLoginDisallowedWithoutError"]) {
    NSString *msg = @"If you want to log in with facebook go to Settings>Facebook and enable acceess for 'DataParenting', then try to log in again.";
    [[[UIAlertView alloc] initWithTitle:@"Facebook Login Is Disabled"
                                                    message:msg
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil] show];
    return YES;
  } else if([error fberrorShouldNotifyUser]) {
    [[[UIAlertView alloc] initWithTitle:@"Facebook Login Failed"
                                message:[error fberrorUserMessage]
                             delegate:nil
                    cancelButtonTitle:@"OK"
                    otherButtonTitles:nil] show];
  
    return YES;
  } else   {
    return NO;
  }
}


@end