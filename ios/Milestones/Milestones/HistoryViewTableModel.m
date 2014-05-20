//
//  HistoryViewTableModel.m
//  Milestones
//
//  Created by Nathan  Pahucki on 5/17/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "HistoryViewTableModel.h"


@implementation HistoryViewTableModel


-(id) init {
  self = [super init];
  if(self) {
    _hasMoreFutureMilestones = YES;
    _hasMorePastMilestones = YES;
    _hasMoreAchievements = YES;
  }
  return self;
}

-(void) loadFutureMilestonesPage:(NSInteger) startIndex {
  if(self.hasMoreFutureMilestones) {
    _isLoadingFutureMilestones = YES;
    [self loadMilestonesPage:startIndex forTimePeriod:@"future" withBlock:^(NSArray *objects, NSError *error) {
      if(error) {
        [self.delegate didFailToLoadFutureMilestones:error];
      } else {
        // if results, set the has more to false
        _hasMoreFutureMilestones = objects.count == self.pagingSize;
        if(!_futureMilestones) _futureMilestones = [NSMutableArray arrayWithCapacity:objects.count * 3]; // enough for three pages
        // NOTE: We must reverse the order so that they get rendered bottom to top.
        NSIndexSet* indices = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,objects.count)];
        NSArray * reversedObject = [[objects reverseObjectEnumerator] allObjects];
        [((NSMutableArray*) _futureMilestones) insertObjects:reversedObject atIndexes:indices];
        [self.delegate didLoadFutureMilestones];
        _isLoadingFutureMilestones = NO;
      }
    }];
  } else {
    // Must call to end loading
    [self.delegate didLoadFutureMilestones];
    _isLoadingFutureMilestones = NO;
  }
}

-(void) loadPastMilestonesPage:(NSInteger) startIndex {
  if(self.hasMorePastMilestones) {
    _isLoadingPastMilestones = YES;
    [self loadMilestonesPage:startIndex forTimePeriod:@"past" withBlock:^(NSArray *objects, NSError *error) {
      if(error) {
        [self.delegate didFailToLoadPastMilestones:error];
        _isLoadingPastMilestones = NO;
      } else {
        // if results, set the has more to false
        if(!_pastMilestones) _pastMilestones = [[NSMutableArray alloc] initWithCapacity:self.pagingSize];
        _hasMorePastMilestones = objects.count == self.pagingSize;
        [((NSMutableArray*) _pastMilestones) addObjectsFromArray:objects];
        [self.delegate didLoadPastMilestones];
        _isLoadingPastMilestones = NO;
      }
    }];
  } else {
    // Must call to end loading
    [self.delegate didLoadPastMilestones];
    _isLoadingPastMilestones = NO;
  }
}


-(void) loadMilestonesPage:(int) startIndex forTimePeriod:(NSString*) timePeriod withBlock:(PFArrayResultBlock) block {
  // TODO: caching!
  if(self.baby) {
    [PFCloud callFunctionInBackground:@"queryMyMilestones"
           withParameters:@{@"babyId": self.baby.objectId,
                            @"timePeriod" : timePeriod,
                            @"rangeDays": [@(self.baby.daysSinceDueDate) stringValue],
                            @"skip" : [@(startIndex) stringValue],
                            @"limit" : [@(self.pagingSize) stringValue]}
                    block:^(NSArray *results, NSError *error) {
                      block(results, error);
                    }];
  } else {
    block(nil, nil);
  }
}

// a startIndex of 0 or less causes a default skip of 0
-(void) loadAchievementsPage:(NSInteger) startIndex {
  // If no Baby available yet, don't try to load anything
  if(self.baby && self.hasMoreAchievements) {
    PFQuery * query = [MilestoneAchievement query];
    [query whereKey:@"baby" equalTo:Baby.currentBaby];
    [query whereKey:@"isSkipped" equalTo:[NSNumber numberWithBool:NO]];
    [query whereKey:@"isPostponed" equalTo:[NSNumber numberWithBool:NO]];
    [query includeKey:@"standardMilestone"];
    [query orderByDescending:@"completionDate"];
    // If no objects are loaded in memory, we look to the cache
    // first to fill the table and then subsequently do a query
    // against the network.
    query.cachePolicy = _achievements.count ? kPFCachePolicyNetworkOnly : kPFCachePolicyCacheThenNetwork;
    query.limit = self.pagingSize;
    query.skip = startIndex > 0 ? startIndex : 0;
    _isLoadingAchievements = YES;
    __block BOOL cachedResult = query.cachePolicy == kPFCachePolicyCacheThenNetwork;
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
      if (error) {
        if(error.code != kPFErrorCacheMiss) {
          [self.delegate didFailToLoadAchievements:error];
          _isLoadingAchievements = NO;
        }
      } else {
        // if results, set the has more to false
        if(!_achievements || startIndex == 0) _achievements = [[NSMutableArray alloc] initWithCapacity:self.pagingSize];
        _hasMoreAchievements = objects.count == self.pagingSize;
        [((NSMutableArray*) _achievements) addObjectsFromArray:objects];
        [self.delegate didLoadAchievements];
        _isLoadingAchievements = NO;
      }
      if(cachedResult) cachedResult = NO;
    }];
  } else {
    [self.delegate didLoadAchievements];
    _isLoadingAchievements = NO;
  }
}

-(void) markPastMilestone:(NSInteger)index ignored:(BOOL) ignored postponed:(BOOL) postponed {
  [self markMilestone:_pastMilestones[index] ignored:ignored postponed:postponed];
  [(NSMutableArray*) _pastMilestones removeObjectAtIndex:index];
}

-(void) markFutureMilestone:(NSInteger)index ignored:(BOOL) ignored postponed:(BOOL) postponed {
  [self markMilestone:_futureMilestones[index] ignored:ignored postponed:postponed];
  [(NSMutableArray*) _futureMilestones removeObjectAtIndex:index];
}

-(void) markMilestone:(StandardMilestone *)milestone ignored:(BOOL) ignored postponed:(BOOL) postponed {
  MilestoneAchievement * achievement = [MilestoneAchievement object];
  achievement.isPostponed = postponed;
  achievement.isSkipped = ignored;
  achievement.baby = _baby;
  achievement.standardMilestone = milestone;
  achievement.completionDate = [NSDate date];
  
  // This will make it looks like it happens right away, and it will save as soon as it can be done.
  [achievement saveEventually];
}



  
  



  
  

@end
