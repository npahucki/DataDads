//
//  HistoryViewTableModel.m
//  Milestones
//
//  Created by Nathan  Pahucki on 5/17/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "HistoryViewTableModel.h"

@implementation HistoryViewTableModel

-(void) loadAllObjects {

  [self loadAchievements];
  
  NSMutableArray *futureMilestones = [[NSMutableArray alloc] init];
  _futureMilesstones = futureMilestones; // Non mutable array interface
  NSMutableArray *pastMilestones = [[NSMutableArray alloc] init];
  _pastMilesstones = pastMilestones;

  for(int i=0; i<7; i++) {
    StandardMilestone * milestone = [StandardMilestone object];
    milestone.title = [NSString stringWithFormat:@"Future Milestone %d",i];
    milestone.shortDescription = @"dfkjhsfk shfkjshdjkdhkfs jhafkjhdsafkj hdshdksjafh kashfdkasdf hkasdhfksak dhfkjshfkjs hdfkj sahf sdafhsakdfjh  sdfkhs dfsfdkjhs dkfhs dfhs dfjs dFHSKDFHKSAHJDF ";
    [futureMilestones addObject:milestone];

    milestone = [StandardMilestone object];
    milestone.title = [NSString stringWithFormat:@"Past Milestone %d",i];
    milestone.shortDescription = @"dfkjhsfk shfkjshdjkdhkfs jhafkjhdsafkj hdshdksjafh kashfdkasdf hkasdhfksak dhfkjshfkjs hdfkj sahf sdafhsakdfjh  sdfkhs dfsfdkjhs dkfhs dfhs dfjs dFHSKDFHKSAHJDF ";
    [pastMilestones addObject:milestone];
  }
  
  [self.delegate objectsUpdated];
}


-(void) loadAchievements {
  NSMutableArray *achievements = [[NSMutableArray alloc] init];
  _achievements = achievements;

  
  for(int i=0; i<3; i++) {
    MilestoneAchievement * achievement = [MilestoneAchievement object];
    achievement.customTitle = [NSString stringWithFormat:@"Custom Achievement %d",i];
    achievement.customDescription = @"dfkjhsfk shfkjshdjkdhkfs jhafkjhdsafkj hdshdksjafh kashfdkasdf hkasdhfksak dhfkjshfkjs hdfkj sahf sdafhsakdfjh  sdfkhs dfsfdkjhs dkfhs dfhs dfjs dFHSKDFHKSAHJDF ";
    achievement.completionDate = [NSDate dateWithTimeIntervalSinceNow:i * 360 * -24];
    [achievements addObject:achievement];
  }
  
  for(int i=0; i<3; i++) {
    MilestoneAchievement * achievement = [MilestoneAchievement object];
    StandardMilestone * milestone = [StandardMilestone object];
    milestone.objectId = [NSString stringWithFormat:@"milestone-%d",i];
    milestone.title = [NSString stringWithFormat:@"Completed Milestone %d",i];
    milestone.shortDescription = @"dfkjhsfk shfkjshdjkdhkfs jhafkjhdsafkj hdshdksjafh kashfdkasdf hkasdhfksak dhfkjshfkjs hdfkj sahf sdafhsakdfjh  sdfkhs dfsfdkjhs dkfhs dfhs dfjs dFHSKDFHKSAHJDF ";
    achievement.standardMilestone = milestone;
    achievement.completionDate = [NSDate dateWithTimeIntervalSinceNow:i * 360 * -48];
    [achievements addObject:achievement];
  }
  
}

@end
