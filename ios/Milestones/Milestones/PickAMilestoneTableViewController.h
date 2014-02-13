//
//  PickAMilestoneTableViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 1/23/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <Parse/Parse.h>
#import "Baby.h"
#import "StandardMilestone.h"

@interface PickAMilestoneTableViewController : PFQueryTableViewController

@property Baby * baby;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *addNewButton;

@end

