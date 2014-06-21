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
-(void) didLoadAchievementsAtPageIndex:(NSInteger) pageIndex;
-(void) didFailToLoadAchievements:(NSError *) error atPageIndex:(NSInteger) pageIndex;

-(void) didLoadFutureMilestonesAtPageIndex:(NSInteger) pageIndex;
-(void) didFailToLoadFutureMilestones:(NSError *) error atPageIndex:(NSInteger) pageIndex;

-(void) didLoadPastMilestonesAtPageIndex:(NSInteger) pageIndex;
-(void) didFailToLoadPastMilestones:(NSError *) error atPageIndex:(NSInteger) pageIndex;

@optional

-(void) willLoadAchievementsAtPageIndex:(NSInteger) pageIndex;
-(void) willLoadFutureMilestonesAtPageIndex:(NSInteger) pageIndex;
-(void) willLoadPastMilestonesAtPageIndex:(NSInteger) pageIndex;

@end


@interface HistoryViewTableModel : NSObject

@property NSString * filter;                    // If non-nil, filters the results in the model. After chnaging this, the results are loaded into the table again.

@property (readonly) NSArray * futureMilestones;  // Array of StandardMilestone - Milestones that have not been marked completed, but still might be.
@property (readonly) NSArray * achievements;       // Array of MilestoneAchievement - Milestones (standard and custom) that have been achieved already
@property (readonly) NSArray * pastMilestones;    // Array of StandardMilestone - Milestones that have not been marked completed, but past the page for the baby age.
@property (readonly) BOOL isLoadingAchievements;
@property (readonly) BOOL isLoadingPastMilestones;
@property (readonly) BOOL isLoadingFutureMilestones;

@property (readonly) BOOL hasMoreFutureMilestones;
@property (readonly) BOOL hasMorePastMilestones;
@property (readonly) BOOL hasMoreAchievements;








@property (weak) id <HistoryViewTableModelDelegate> delegate;
@property (nonatomic, strong) Baby* baby;

@property NSInteger pagingSize;

// clears all the properties and make ready for use.
-(void) reset;


-(void) loadFutureMilestonesPage:(NSInteger) startIndex;
-(void) loadPastMilestonesPage:(NSInteger) startIndex;
-(void) loadAchievementsPage:(NSInteger) startIndex;

-(void) markPastMilestone:(NSInteger)index ignored:(BOOL) ignored postponed:(BOOL) postponed;
-(void) markFutureMilestone:(NSInteger)index ignored:(BOOL) ignored postponed:(BOOL) postponed;

/*!
 * Adds a new achievement, and returns the index of where it was inserted in the list 
 * which may not be the head of the list if the achievement has an older date. If the 
 * item would be inserted after other items yet to be loaded, then -1 is returned, 
 * and the UI shoud not expect to display it right away.
 */
-(NSInteger) addNewAchievement:(MilestoneAchievement *) achievement;

-(MilestoneAchievement *) deleteAchievementAtIndex:(NSInteger) index;

/*!
 * Use this instead of doing indexOfObject on the array property since that does not do equality checking based on the object Id.
 */
-(NSInteger) indexOfFutureMilestone:(StandardMilestone*) milestone;

/*!
 * Use this instead of doing indexOfObject on the array property since that does not do equality checking based on the object Id.
 */
-(NSInteger) indexOfPastMilestone:(StandardMilestone*) milestone;





@end
