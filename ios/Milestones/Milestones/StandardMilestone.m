//
//  StandardMilestone.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/31/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "StandardMilestone.h"
#import <Parse/PFObject+Subclass.h>

@implementation StandardMilestone

@dynamic title;
@dynamic description;
@dynamic rangeHigh;
@dynamic rangeLow;

+ (NSString *)parseClassName {
  return @"StandardMilestones";
}

+ (PFQuery*) queryForMilestonesForDay:(NSNumber *)rangeDays {
  PFQuery *query = [StandardMilestone query];
  [query whereKey:@"rangeHigh" greaterThanOrEqualTo:rangeDays];
  [query whereKey:@"rangeLow" lessThanOrEqualTo:rangeDays];
  [query orderByDescending:@"rangeUpper"];
  return query;
}


@end
