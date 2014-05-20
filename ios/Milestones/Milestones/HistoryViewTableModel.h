//
//  HistoryViewTableModel.h
//  Milestones
//
//  Created by Nathan  Pahucki on 5/17/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HistoryViewTableModelDelegate <NSObject>

@required
// Called back when the objects have been updated
-(void) didLoadAchievements;
-(void) didFailToLoadAchievements:(NSError *) error;

-(void) didLoadFutureMilestones;
-(void) didFailToLoadFutureMilestones:(NSError *) error;

-(void) didLoadPastMilestones;
-(void) didFailToLoadPastMilestones:(NSError *) error;

@end


@interface HistoryViewTableModel : NSObject

@property (readonly) NSArray * futureMilestones;  // Array of StandardMilestone - Milestones that have not been marked completed, but still might be.
@property (readonly) NSArray * achievements;       // Array of MilestoneAchievement - Milestones (standard and custom) that have been achieved already
@property (readonly) NSArray * pastMilesstones;    // Array of StandardMilestone - Milestones that have not been marked completed, but past the page for the baby age.
@property (readonly) BOOL isLoadingAchievements;
@property (readonly) BOOL isLoadingPastMilestones;
@property (readonly) BOOL isLoadingFutureMilestones;

@property (readonly) BOOL hasMoreFutureMilestones;
@property (readonly) BOOL hasMorePastMilestones;
@property (readonly) BOOL hasMoreAchievements;


@property (weak) id <HistoryViewTableModelDelegate> delegate;
@property Baby* baby;


@property NSInteger pagingSize;

-(void) loadFutureMilestonesPage:(int) startIndex;
-(void) loadPastMilestonesPage:(int) startIndex;

-(void) loadAchievementsPage:(NSUInteger) startIndex;

@end
