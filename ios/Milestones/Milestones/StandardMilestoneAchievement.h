//
//  StandardMilestoneAchievement.h
//  Milestones
//
//  Created by Nathan  Pahucki on 1/31/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Baby.h"
#import "StandardMilestone.h"

@interface StandardMilestoneAchievement : PFObject <PFSubclassing>

@property Baby* baby;
@property StandardMilestone *milestone;
@property NSDate* completionDate;


@end
