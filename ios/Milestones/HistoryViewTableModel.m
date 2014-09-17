//
//  HistoryViewTableModel.m
//  Milestones
//
//  Created by Nathan  Pahucki on 5/17/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "HistoryViewTableModel.h"
#import "PFCloud+Cache.h"
#import "PFObject+NSCoding.h"

#define STOP_WORDS @[@"the", @"in", @"and", @"he", @"she",@"him",@"her",@"his"]

typedef void (^StandardMilestoneResultBlock)(NSNumber *totalCount, NSArray *objects, NSError *error);

@implementation HistoryViewTableModel {
    NSString *_filter;
    NSArray *_filterTokens;
}

- (void)setFilter:(NSString *)filter {
    if (_filter != filter && ![_filter isEqualToString:filter]) {
        _filter = filter;
        NSMutableArray *filterTokens = [NSMutableArray arrayWithArray:[[_filter lowercaseString] componentsSeparatedByString:@" "]];
        [filterTokens removeObjectsInArray:STOP_WORDS];
        _filterTokens = filterTokens;

        [self loadAchievementsPage:0];
        [self loadPastMilestonesPage:0];
        [self loadFutureMilestonesPage:0];
    }
}

- (NSString *)filter {
    return _filter;
}

- (id)init {
    self = [super init];
    if (self) {
        [self reset];
    }
    return self;
}

- (void)reset {
    _baby = nil;
    _achievements = nil;
    _futureMilestones = nil;
    _pastMilestones = nil;
    _hasMoreAchievements = YES;
    _hasMoreFutureMilestones = YES;
    _hasMorePastMilestones = YES;
    _hadErrorLoadingAchievements = NO;
    _hadErrorLoadingFutureMilestones = NO;
    _hadErrorLoadingPastMilestones = NO;

    _filter = nil;
    _countOfAchievements = 0;
    _countOfFutureMilestones = 0;
    _countOfPastMilestones = 0;
}

- (void)loadFutureMilestonesPage:(NSInteger)startIndex {
    if (startIndex == 0) {
        // Need to reset
        _futureMilestones = nil;
        _hasMoreFutureMilestones = YES;
    }

    _hadErrorLoadingFutureMilestones = NO;
    if (self.hasMoreFutureMilestones) {
        if ([self.delegate respondsToSelector:@selector(willLoadFutureMilestonesAtPageIndex:)])
            [self.delegate willLoadFutureMilestonesAtPageIndex:startIndex];
        _isLoadingFutureMilestones = YES;
        PFCachePolicy cachePolicy = _futureMilestones.count ? kPFCachePolicyNetworkElseCache : kPFCachePolicyCacheThenNetwork;
        __block BOOL cachedResult = cachePolicy == kPFCachePolicyCacheThenNetwork;
        [self loadMilestonesPage:startIndex forTimePeriod:@"future" withCachePolicy:cachePolicy withBlock:^(NSNumber *count, NSArray *objects, NSError *error) {
            if (error) {
                _hadErrorLoadingFutureMilestones = YES;
                [self.delegate didFailToLoadFutureMilestones:error atPageIndex:startIndex];
            } else {
                if (cachedResult || ![HistoryViewTableModel isPFObjectArrayEqual:_futureMilestones toPFObjectArray:objects]) {
                    // if results, set the has more to false
                    _hasMoreFutureMilestones = objects.count == self.pagingSize;
                    if (count.integerValue >= 0) _countOfFutureMilestones = count.integerValue;
                    if (!_futureMilestones || startIndex == 0) _futureMilestones = [NSMutableArray arrayWithCapacity:objects.count * 3]; // enough for three pages
                    // NOTE: We must reverse the order so that they get rendered bottom to top.
                    NSIndexSet *indices = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, objects.count)];
                    NSArray *reversedObject = [[objects reverseObjectEnumerator] allObjects];
                    [((NSMutableArray *) _futureMilestones) insertObjects:reversedObject atIndexes:indices];
                    [self.delegate didLoadFutureMilestonesAtPageIndex:startIndex];
                    _isLoadingFutureMilestones = NO;
                    cachedResult = NO;
                }
            }
        }];
    } else {
        // Must call to end loading
        [self.delegate didLoadFutureMilestonesAtPageIndex:startIndex];
        _isLoadingFutureMilestones = NO;
    }
}

- (void)loadPastMilestonesPage:(NSInteger)startIndex {
    if (startIndex == 0) {
        // Need to reset
        _pastMilestones = nil;
        _hasMorePastMilestones = YES;
    }

    _hadErrorLoadingPastMilestones = NO;
    if (self.hasMorePastMilestones) {
        if ([self.delegate respondsToSelector:@selector(willLoadPastMilestonesAtPageIndex:)])
            [self.delegate willLoadPastMilestonesAtPageIndex:startIndex];
        _isLoadingPastMilestones = YES;
        PFCachePolicy cachePolicy = _pastMilestones.count ? kPFCachePolicyNetworkElseCache : kPFCachePolicyCacheThenNetwork;
        __block BOOL cachedResult = cachePolicy == kPFCachePolicyCacheThenNetwork;
        [self loadMilestonesPage:startIndex forTimePeriod:@"past" withCachePolicy:cachePolicy withBlock:^(NSNumber *count, NSArray *objects, NSError *error) {
            if (error) {
                [self.delegate didFailToLoadPastMilestones:error atPageIndex:startIndex];
                _isLoadingPastMilestones = NO;
                _hadErrorLoadingPastMilestones = YES;
            } else {
                if (cachedResult || ![HistoryViewTableModel isPFObjectArrayEqual:_pastMilestones toPFObjectArray:objects]) {
                    // if results, set the has more to false
                    if (count.integerValue >= 0) _countOfPastMilestones = count.integerValue;
                    if (!_pastMilestones) _pastMilestones = [[NSMutableArray alloc] initWithCapacity:self.pagingSize];
                    _hasMorePastMilestones = objects.count == self.pagingSize;
                    [((NSMutableArray *) _pastMilestones) addObjectsFromArray:objects];
                    [self.delegate didLoadPastMilestonesAtPageIndex:startIndex];
                    _isLoadingPastMilestones = NO;
                    cachedResult = NO;
                }
            }
        }];
    } else {
        // Must call to end loading
        [self.delegate didLoadPastMilestonesAtPageIndex:startIndex];
        _isLoadingPastMilestones = NO;
    }
}


- (void)loadMilestonesPage:(NSInteger)startIndex forTimePeriod:(NSString *)timePeriod withCachePolicy:(PFCachePolicy)cachePolicy withBlock:(StandardMilestoneResultBlock)block {
    if (self.baby) {
        NSNumber *babySex = @(self.baby.isMale);
        NSNumber *parentSex = @(ParentUser.currentUser.isMale);

        [PFCloud callFunctionInBackground:@"queryMyMilestones"
                           withParameters:@{@"babyId" : self.baby.objectId,
                                   @"appVersion" : NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"],
                                   @"babyIsMale" : babySex,
                                   @"parentIsMale" : parentSex,
                                   @"timePeriod" : timePeriod,
                                   @"rangeDays" : [@(self.baby.daysSinceDueDate) stringValue],
                                   @"skip" : [@(startIndex) stringValue],
                                   @"limit" : [@(self.pagingSize) stringValue],
                                   @"showPostponed" : @(self.showPostponedMilestones),
                                   @"showIgnored" : @(self.showIgnoredMilestones),
                                   @"filterTokens" : _filter ? _filterTokens : [NSNull null]}
                              cachePolicy:cachePolicy
                                    block:^(NSDictionary *results, NSError *error) {
                                        NSNumber *count = results[@"count"];
                                        NSArray *milestones = results[@"milestones"];
            block(count, milestones, error);
        }];
    } else {
        block(nil, nil, nil);
    }
}


// a startIndex of 0 or less causes a default skip of 0
- (void)loadAchievementsPage:(NSInteger)startIndex {
    if (startIndex == 0) {
        // Need to reset
        _achievements = nil;
        _hasMoreAchievements = YES;
    }

    // If no Baby available yet, don't try to load anything
    _hadErrorLoadingAchievements = NO;
    if (self.baby && self.hasMoreAchievements) {
        if ([self.delegate respondsToSelector:@selector(willLoadAchievementsAtPageIndex:)]) {
            [self.delegate willLoadAchievementsAtPageIndex:startIndex];
        }

        _isLoadingAchievements = YES;
        PFCachePolicy cachePolicy = _achievements.count ? kPFCachePolicyNetworkOnly : kPFCachePolicyCacheThenNetwork;
        __block BOOL cachedResult = cachePolicy == kPFCachePolicyCacheThenNetwork;
        [PFCloud callFunctionInBackground:@"queryMyAchievements"
                           withParameters:@{@"babyId" : self.baby.objectId,
                                   @"appVersion" : NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"],
                                   @"skip" : [@(startIndex) stringValue],
                                   @"limit" : [@(self.pagingSize) stringValue],
                                   @"filterTokens" : _filter ? _filterTokens : [NSNull null]}
                              cachePolicy:cachePolicy
                                    block:^(NSDictionary *results, NSError *error) {
            if (error) {
                if (error.code != kPFErrorCacheMiss) {
                    [self.delegate didFailToLoadAchievements:error atPageIndex:startIndex];
                    _isLoadingAchievements = NO;
                    _hadErrorLoadingAchievements = YES;
                }
            } else {
                NSNumber *count = (NSNumber *) results[@"count"];
                if (count.integerValue >= 0) _countOfAchievements = count.integerValue;
                NSArray *achievements = results[@"achievements"];
                // Don't update if it is the same which causes flickering
                if (cachedResult || ![HistoryViewTableModel isPFObjectArrayEqual:_achievements toPFObjectArray:achievements]) {
                    // if results, set the has more to false
                    if (!_achievements || startIndex == 0) _achievements = [[NSMutableArray alloc] initWithCapacity:self.pagingSize];
                    _hasMoreAchievements = achievements.count == self.pagingSize;
                    for (MilestoneAchievement *achievement in achievements) {
                        if (Baby.currentBaby) { // in some cases, like on log out, the bbay may have been set null already.
                            NSAssert([achievement.baby.objectId isEqualToString:Baby.currentBaby.objectId], @"Expected only achievements that match current baby!");
                            // So we can use a populated object, assign the object to the current baby object
                            achievement.baby = Baby.currentBaby;
                        }
                        [((NSMutableArray *) _achievements) addObject:achievement];
                    }

                    [self.delegate didLoadAchievementsAtPageIndex:startIndex];
                    _isLoadingAchievements = NO;
                }
            }
            if (cachedResult) cachedResult = NO;
        }];
    } else {
        [self.delegate didLoadAchievementsAtPageIndex:startIndex];
        _isLoadingAchievements = NO;
    }
}

- (void)markPastMilestone:(NSUInteger)index ignored:(BOOL)ignored postponed:(BOOL)postponed {
    [self markMilestone:_pastMilestones[index] ignored:ignored postponed:postponed];
    [(NSMutableArray *) _pastMilestones removeObjectAtIndex:index];
    _countOfPastMilestones--;
}

- (void)markFutureMilestone:(NSUInteger)index ignored:(BOOL)ignored postponed:(BOOL)postponed {
    [self markMilestone:_futureMilestones[index] ignored:ignored postponed:postponed];
    [(NSMutableArray *) _futureMilestones removeObjectAtIndex:index];
    _countOfFutureMilestones--;
}

- (void)markMilestone:(StandardMilestone *)milestone ignored:(BOOL)ignored postponed:(BOOL)postponed {

    if (!ignored && !postponed) return; // Don't save it, just used to remove from the arrays above.

    MilestoneAchievement *achievement = [MilestoneAchievement object];
    achievement.isPostponed = postponed;
    achievement.isSkipped = ignored;
    achievement.baby = _baby;
    achievement.standardMilestone = milestone;
    achievement.completionDate = [NSDate date];
    // This will make it looks like it happens right away, and it will save as soon as it can be done.
    [achievement saveEventually];
    [UsageAnalytics trackAchievementLogged:achievement sharedOnFacebook:NO];
}

- (NSInteger)addNewAchievement:(MilestoneAchievement *)achievement {
    _countOfAchievements++;
    // The achievement are already sorted by completion date (descending), so we need to run through the list and
    // find the appropriate place to insert it. We could insert and sort the list again, but we would then not
    // know where the item ended up in the list, which is needed to know which parts of the table to update.
    NSUInteger idx;
    for (idx = 0; idx < _achievements.count; idx++) {
        MilestoneAchievement *extant = (MilestoneAchievement *) _achievements[idx];
        if ([achievement.completionDate timeIntervalSinceDate:extant.completionDate] > 0) {
            break; // leave IDX here.
        }
    }
    // If we hit the end of the loop, then IDX should be the same as the last element, so it means we add to the end
    if (idx >= _achievements.count && _hasMoreAchievements) {
        return -1;
    } else {
        [(NSMutableArray *) _achievements insertObject:achievement atIndex:idx];
        return idx;
    }
}

- (void)replaceAchievementIfLoaded:(MilestoneAchievement *)achievement {
    NSUInteger idx = [self indexOfAchievement:achievement];
    if (idx != NSNotFound) {
        ((NSMutableArray *) _achievements)[idx] = achievement;
    }
}

- (MilestoneAchievement *)deleteAchievementAtIndex:(NSUInteger)index {
    MilestoneAchievement *achievement = _achievements[index];
    [((NSMutableArray *) _achievements) removeObjectAtIndex:index];
    _countOfAchievements--;
    [achievement deleteEventually];
    return achievement;
}

- (NSUInteger)indexOfAchievement:(MilestoneAchievement *)achievment {
    for (NSUInteger idx = 0; idx < _achievements.count; idx++) {
        if ([achievment.objectId isEqualToString:((MilestoneAchievement *) _achievements[idx]).objectId]) {
            return idx;
        }
    }
    return NSNotFound;
}


- (NSUInteger)indexOfFutureMilestone:(StandardMilestone *)milestone {
    for (NSUInteger idx = 0; idx < _futureMilestones.count; idx++) {
        if ([milestone.objectId isEqualToString:((StandardMilestone *) _futureMilestones[idx]).objectId]) {
            return idx;
        }
    }
    return NSNotFound;
}

- (NSUInteger)indexOfPastMilestone:(StandardMilestone *)milestone {
    for (NSUInteger idx = 0; idx < _pastMilestones.count; idx++) {
        if ([milestone.objectId isEqualToString:((StandardMilestone *) _pastMilestones[idx]).objectId]) {
            return idx;
        }
    }
    return NSNotFound;
}

+ (BOOL)isPFObjectArrayEqual:(NSArray *)array1 toPFObjectArray:(NSArray *)array2 {
    BOOL isEqual = YES;

    if (array1.count == array2.count) {
        for (NSUInteger i = 0; i < array1.count; i++) {
            PFObject *obj1 = array1[i];
            PFObject *obj2 = array2[i];
            if (![[obj1 parseClassName] isEqualToString:[obj2 parseClassName]] || ![obj1.objectId isEqualToString:obj2.objectId] ||
                    ![obj1.updatedAt isEqualToDate:obj2.updatedAt]) {
                isEqual = NO;
                break;
            }
        }
    } else {
        isEqual = NO;
    }
    return isEqual;
}


@end
