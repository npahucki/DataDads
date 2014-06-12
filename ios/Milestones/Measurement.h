//
//  Measurement.h
//  Milestones
//
//  Created by Nathan  Pahucki on 6/12/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MilestoneAchievement.h"

@interface Measurement : PFObject<PFSubclassing>

@property NSString * unit;
@property NSString * type;
@property NSNumber * quantity;
@property MilestoneAchievement * achievement;

@end
