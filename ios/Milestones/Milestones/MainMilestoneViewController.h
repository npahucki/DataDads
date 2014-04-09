//
//  MainMilestoneViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 4/1/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainMilestoneViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIButton *addMilestoneButton;

// Show an animation of the add button bouncing 3 time, to get attention
-(void) bounceAddButton;

@end

