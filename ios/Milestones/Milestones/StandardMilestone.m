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
@dynamic shortDescription;
@dynamic rangeHigh;
@dynamic rangeLow;

+ (NSString *)parseClassName {
  return @"StandardMilestones";
}

@end
