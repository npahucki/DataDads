//
//  MilestoneNotedViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 1/21/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StandardMilestone.h"
#import "Baby.h"

@interface NoteMilestoneViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITextField *completionDateTextField;

@property StandardMilestone *milestone;
@property Baby *baby;

@property (strong, nonatomic) IBOutlet UIButton *doneButton;


@end
