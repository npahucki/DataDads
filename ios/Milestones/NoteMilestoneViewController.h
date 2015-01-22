//
//  MilestoneNotedViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 1/21/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "StandardMilestone.h"
#import "FDTakeController.h"
#import "UIDateField.h"
#import "UIViewControllerWithHUDProgress.h"
#import "SevenSwitch.h"
#import "RangeIndicatorView.h"
#import "DataParentingAdView.h"
#import "CMPopTipView.h"


@interface NoteMilestoneViewController : UIViewControllerWithHUDProgress <FDTakeDelegate, UITextFieldDelegate, UITextViewDelegate, UIScrollViewDelegate, DataParentingAdViewDelegate, CMPopTipViewDelegate>

@property MilestoneAchievement *achievement;
@property(strong, nonatomic) IBOutlet UIDateField *completionDateTextField;
@property(strong, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property(weak, nonatomic) IBOutlet UITextField *commentsTextField;
@property(strong, nonatomic) IBOutlet UIButton *takePhotoButton;
@property(weak, nonatomic) IBOutlet UITextView *titleTextView;
@property(weak, nonatomic) IBOutlet UITextField *customTitleTextField;
@property(weak, nonatomic) IBOutlet UIView *placeHolderSwitch;
@property(strong, nonatomic) SevenSwitch *fbSwitch;

@property(weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property(weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property(weak, nonatomic) IBOutlet UITextField *heightTextField;
@property(weak, nonatomic) IBOutlet UILabel *weightUnitLabel;
@property(weak, nonatomic) IBOutlet UILabel *heightUnitLabel;
@property(weak, nonatomic) IBOutlet UIView *detailsContainerView;

@property(weak, nonatomic) IBOutlet UILabel *rangeLabel;
@property(weak, nonatomic) IBOutlet RangeIndicatorView *rangeIndicatorView;
@property(weak, nonatomic) IBOutlet UIView *titleTextFadingView;
@property(weak, nonatomic) IBOutlet UITextField *weightTextField;
@property(weak, nonatomic) IBOutlet DataParentingAdView *adView;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *adViewHeightConstraint;
@end

