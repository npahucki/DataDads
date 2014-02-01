//
//  StandardMilestone.h
//  Milestones
//
//  Created by Nathan  Pahucki on 1/31/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>


@interface StandardMilestone : PFObject <PFSubclassing>

+ (NSString *)parseClassName;

@property NSString *title;
@property NSString *description;
@property NSNumber *rangeLow;
@property NSNumber *rangeHigh;

/**
 Returns a query that queries all the babies for the user passed in
 */
+ (PFQuery*) queryForMilestonesForDay:(NSNumber*)day;


@end
