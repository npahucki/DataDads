//
//  PFFacebookUtils+PFFacebookUtils_Extras.m
//  Milestones
//
//  Created by Nathan  Pahucki on 6/5/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "PFFacebookUtils+Extras.h"
#import "NSDate+Utils.h"

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
                                                url:nil // TOOD: Link to page
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

+(void) ensureHasPublishPermissions:(PFUser *) user block:(PFBooleanResultBlock) block {
  if([PFFacebookUtils isLinkedWithUser:user]) {
    if([[[PFFacebookUtils session] permissions] containsObject:@"publish_actions"]) {
      block(YES,nil);
    } else {
      // Msg Box
      
      [PFFacebookUtils reauthorizeUser:user withPublishPermissions:@[@"publish_actions",@"email",@"public_profile"] audience:FBSessionDefaultAudienceFriends block:block];
    }
  } else {
    // MSG Box to LInk with Facebook
    // TODO: Authorize user.
    NSLog(@"NOT LINKED! TODO: Link User At This Point");
    block(NO, nil);
  }
}



@end
