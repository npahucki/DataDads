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

@interface MilestoneAchievement : PFObject <PFSubclassing>

@property Baby* baby;
@property StandardMilestone *standardMilestone; // optional, could be custom in which case customTitle and customDescription should be set
@property NSDate* completionDate;
@property PFFile* attachment;
@property NSString* attachmentType;
@property NSString* customTitle;      // optional, should be set if milestone is nil
@property NSString* customDescription;
@property BOOL isSkipped;
@property BOOL isPostponed;

-(BOOL) isCustom;

@end
