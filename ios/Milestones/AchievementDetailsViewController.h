//
//  AchievementDetailsViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 5/27/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RangeIndicatorView.h"

@interface AchievementDetailsViewController : UIViewController <UITextViewDelegate>

@property MilestoneAchievement * achievement;
@property (weak, nonatomic) IBOutlet UITextView *detailsTextView;
@property (weak, nonatomic) IBOutlet UIImageView *statusImageView;
@property (weak, nonatomic) IBOutlet RangeIndicatorView *rangeIndicatorView;
@property (weak, nonatomic) IBOutlet UILabel *rangleScaleLabel;

@property (weak, nonatomic) IBOutlet UIView *detailsTextViewContainerView;
@property (weak, nonatomic) IBOutlet UIButton *detailsImageButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *actionBarButton;
@end
