//
//  MilestoneDetailsViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 2/9/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MilestoneDetailsViewController : UIViewController
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *enteredByLabel;
@property (strong, nonatomic) IBOutlet UILabel *ageRangeLabel;
@property (strong, nonatomic) IBOutlet UILabel *descriptionLabel;


// Note: We use an achievement here instead of a milestone, so that we can pass it to the NoteMilestoneViewController if the user want's to complete it
@property MilestoneAchievement *achievement;

@end
