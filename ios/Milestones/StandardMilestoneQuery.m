//
//  MilestonesQuery.m
//  Milestones
//
//  Created by Nathan  Pahucki on 3/21/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "StandardMilestoneQuery.h"

@implementation StandardMilestoneQuery



/*!
 Finds objects asynchronously and calls the given block with the results.
 @param block The block to execute. The block should have the following argument signature:(NSArray *objects, NSError *error)
 */
- (void)findObjectsInBackgroundWithBlock:(PFArrayResultBlock)queryBlock {
  if(queryBlock) {
    [PFCloud callFunctionInBackground:@"queryMyMilestones"
                       withParameters:@{@"babyId": self.babyId,
                                        @"rangeDays": self.rangeDays,
                                        @"skip" : [@(self.skip) stringValue],
                                        @"limit" : [@(self.limit) stringValue]}
                                block:^(NSArray *results, NSError *error) {
                                  queryBlock(results, nil);
                                }];
  }
}



@end
