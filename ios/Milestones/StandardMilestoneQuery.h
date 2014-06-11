//
//  MilestonesQuery.h
//  Milestones
//
//  Created by Nathan  Pahucki on 3/21/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <Parse/Parse.h>

@interface StandardMilestoneQuery : PFQuery

@property (strong, nonatomic) NSString *babyId;
@property (strong, nonatomic) NSNumber * rangeDays;


@end
