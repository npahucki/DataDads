//
//  InvitationsViewController.h
//  DataParenting
//
//  Created by Nathan  Pahucki on 1/6/15.
//  Copyright (c) 2015 DataParenting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewControllerWithBabyInfoButton.h"

@class MBContactPicker;

@interface MainFollowConnectionsViewController : ViewControllerWithBabyInfoButton <MBContactPickerDelegate>

@property(weak, nonatomic) IBOutlet UIBarButtonItem *inviteButton;
@property(weak, nonatomic) IBOutlet MBContactPicker *pickerView;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *pickerHeightConstraint;
@property(weak, nonatomic) IBOutlet UIView *containerView;
@property(weak, nonatomic) IBOutlet UIButton *babyMenuButton;
@property(weak, nonatomic) IBOutlet UIView *nothingToShowContainerView;

@end
