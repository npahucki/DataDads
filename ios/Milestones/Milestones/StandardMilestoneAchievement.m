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

// Since we can't use an inner query based on an onject reference (See https://parse.com/questions/trouble-with-nested-query-using-objectid)
// we must include a redundant column which is a string and has the milestoneId included. As such, to make sure this is always set correctly
// we must implement the milestone getter/setter ourselves.
//@dynamic milestone;
@dynamic baby;
@dynamic completionDate;
@dynamic attachment;
@dynamic attachmentType;

+ (NSString *)parseClassName {
  return @"StandardMilestoneAchievements";
}

-(void) setMilestone:(StandardMilestone *)milestone {
  [self setObject:milestone forKey:@"milestone"];
  [self setObject:milestone.objectId forKey:@"milestoneId"];
}

-(StandardMilestone*) milestone {
  return [self objectForKey:@"milestone"];
}

@end
