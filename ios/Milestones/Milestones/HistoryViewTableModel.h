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
-(void) objectsUpdated;

@end


@interface HistoryViewTableModel : NSObject

@property (readonly) NSArray * futureMilesstones;  // Array of StandardMilestone - Milestones that have not been marked completed, but still might be.
@property (readonly) NSArray * achievements;       // Array of MilestoneAchievement - Milestones (standard and custom) that have been achieved already
@property (readonly) NSArray * pastMilesstones;    // Array of StandardMilestone - Milestones that have not been marked completed, but past the page for the baby age.
@property (weak) id <HistoryViewTableModelDelegate> delegate;

-(void) loadAllObjects;
-(void) loadAchievements;



@end
