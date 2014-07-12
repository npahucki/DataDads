//
//  ParentUser.m
//  Milestones
//
//  Created by Nathan  Pahucki on 6/5/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "ParentUser.h"
#import <Parse/PFObject+Subclass.h>

@implementation ParentUser

@dynamic screenName;
@dynamic isMale;
@dynamic usesMetric;
@dynamic launchCount;


-(BOOL) showHiddenTips {
  return [[NSUserDefaults standardUserDefaults] boolForKey:@"showHiddenTips"];
}

-(void) setShowHiddenTips:(BOOL)showHiddenTips {
  [[NSUserDefaults standardUserDefaults] setBool:showHiddenTips forKey:@"showHiddenTips"];
}

-(BOOL) showIgnoredMilestones {
  return [[NSUserDefaults standardUserDefaults] boolForKey:@"showIgnoredMilestones"];
}

-(void) setShowIgnoredMilestones:(BOOL)showIgnoredMilestones {
  [[NSUserDefaults standardUserDefaults] setBool:showIgnoredMilestones forKey:@"showIgnoredMilestones"];
}

-(BOOL) showPostponedMilestones {
  return [[NSUserDefaults standardUserDefaults] boolForKey:@"showPostponedMilestones"];
}

-(void) setShowPostponedMilestones:(BOOL)showPostponedMilestones {
  [[NSUserDefaults standardUserDefaults] setBool:showPostponedMilestones forKey:@"showPostponedMilestones"];
}

-(void) setAutoPublishToFacebook:(BOOL)autoPublishToFacebook {
  [[NSUserDefaults standardUserDefaults] setBool:autoPublishToFacebook forKey:@"autoPublishToFacebook"];
}

-(BOOL) autoPublishToFacebook {
  return [[NSUserDefaults standardUserDefaults] boolForKey:@"autoPublishToFacebook"];
}

+(void) incrementLaunchCount {
  [self.currentUser incrementKey:@"launchCount"];
  [self.currentUser saveEventually:^(BOOL succeeded, NSError *error) {
    if(succeeded) [ParentUser.currentUser refreshInBackgroundWithBlock:nil];
  }];
}




@end
