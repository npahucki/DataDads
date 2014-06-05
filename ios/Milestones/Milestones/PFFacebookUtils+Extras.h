//
//  PFFacebookUtils+PFFacebookUtils_Extras.h
//  Milestones
//
//  Created by Nathan  Pahucki on 6/5/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <Parse/Parse.h>


@interface PFFacebookUtils (PFFacebookUtils_Extras)

+(void) shareAchievement:(MilestoneAchievement*) achievement block:(PFBooleanResultBlock) block;
+(void) ensureHasPublishPermissions:(ParentUser *) user block:(PFBooleanResultBlock) block;


@end
