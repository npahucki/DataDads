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
@dynamic attachmentThumbnail;
@dynamic customTitle;
@dynamic comment;
@dynamic isSkipped;
@dynamic isPostponed;

+ (NSString *)parseClassName {
  return @"MilestoneAchievements";
}

-(void) setStandardMilestone:(StandardMilestone *)standardMilestone {
  [self setObject:standardMilestone forKey:@"standardMilestone"];
  [self setObject:standardMilestone.objectId forKey:@"standardMilestoneId"];
}

-(StandardMilestone*) standardMilestone {
  return [self objectForKey:@"standardMilestone"];
}

-(void) setCompletionDate:(NSDate *)completionDate {
  [self setObject:completionDate forKey:@"completionDate"];
  // Skip any thing in the past. This can happen if the user has entered bad dates
  // or uploads a photo with a bad date on it. 
  NSInteger days = [self.baby daysSinceDueDate:completionDate];
  if(days >= 0) [self setObject:@(days) forKey:@"completionDays"];
}

-(NSDate *) completionDate {
  return [self objectForKey:@"completionDate"];
}

-(NSString*) displayTitle {
  return self.customTitle.length ? self.customTitle : [self.standardMilestone titleForBaby:self.baby];
}

-(BOOL) isCustom {
  return self.standardMilestone == nil;
}

-(void) calculatePercentileRankingWithBlock: (void ( ^ )(float percentile) ) block {
  if(self.standardMilestone) {
    [PFCloud callFunctionInBackground:@"percentileRanking"
                       withParameters:@{@"milestoneId": self.standardMilestone.objectId,
                                        @"completionDays": @([self.baby daysSinceDueDate:self.completionDate])}
                                block:^(NSNumber *result, NSError *error) {
                                  if(error) {
                                    NSLog(@"Error trying to calulate percentile: %@", error);
                                    block(-1);
                                  } else {
                                    block([result floatValue] );
                                  }
                                }];
  } else {
    block(-1);
  }
}

@end
