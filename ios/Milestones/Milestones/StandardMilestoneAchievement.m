//
//  StandardMilestoneAchievement.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/31/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "StandardMilestoneAchievement.h"
#import <Parse/PFObject+Subclass.h>


@implementation StandardMilestoneAchievement


@dynamic milestone;
@dynamic baby;
@dynamic completionDate;

+ (NSString *)parseClassName {
  return @"StandardMilestoneAchievements";
}


@end
