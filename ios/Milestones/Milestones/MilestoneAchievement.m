//
//  StandardMilestoneAchievement.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/31/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "MilestoneAchievement.h"
#import <Parse/PFObject+Subclass.h>


@implementation MilestoneAchievement

// Since we can't use an inner query based on an onject reference (See https://parse.com/questions/trouble-with-nested-query-using-objectid)
// we must include a redundant column which is a string and has the milestoneId included. As such, to make sure this is always set correctly
// we must implement the milestone getter/setter ourselves.
//@dynamic standardMilestone;
@dynamic baby;
@dynamic completionDate;
@dynamic attachment;
@dynamic attachmentType;
@dynamic customTitle;
@dynamic customDescription;
@dynamic isSkipped;
@dynamic isPostponed;

+ (NSString *)parseClassName {
  return @"MilestoneAchievements";
}

-(id) init {
  self = [super init];
  if(self) {
    self.isSkipped = NO;
    self.isPostponed = NO;
  }
  return self;
}

-(void) setStandardMilestone:(StandardMilestone *)standardMilestone {
  [self setObject:standardMilestone forKey:@"standardMilestone"];
  [self setObject:standardMilestone.objectId forKey:@"standardMilestoneId"];
}

-(StandardMilestone*) standardMilestone {
  return [self objectForKey:@"standardMilestone"];
}

-(BOOL) isCustom {
  return self.standardMilestone == nil;
}


@end
