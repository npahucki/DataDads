//
//  AchievementDetailsViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 5/27/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RangeIndicatorView.h"
#import "DataParentingAdView.h"

@interface AchievementDetailsViewController : UIViewController <UITextViewDelegate, UIDynamicAnimatorDelegate>
@property(weak, nonatomic) IBOutlet DataParentingAdView *adView;

@property MilestoneAchievement *achievement;
@property(weak, nonatomic) IBOutlet UITextView *detailsTextView;
@property(weak, nonatomic) IBOutlet UIImageView *statusImageView;
@property(weak, nonatomic) IBOutlet RangeIndicatorView *rangeIndicatorView;
@property(weak, nonatomic) IBOutlet UILabel *rangleScaleLabel;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareButtonBarItem;
@property(weak, nonatomic) IBOutlet UIView *detailsTextViewContainerView;
@property(weak, nonatomic) IBOutlet UIButton *detailsImageButton;
@property(weak, nonatomic) IBOutlet UIBarButtonItem *actionBarButton;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@end
