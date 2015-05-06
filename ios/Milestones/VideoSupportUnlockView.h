//
//  VideoSupportUnlockView.h
//  DataParenting
//
//  Created by Nathan  Pahucki on 4/29/15.
//  Copyright (c) 2015 DataParenting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBContactPicker.h"
#import "CircleProgressBar.h"

@class BFTask;

@interface VideoSupportUnlockView : UIViewController <MBContactPickerDelegate>
@property(weak, nonatomic) IBOutlet UILabel *titleLabel;
@property(weak, nonatomic) IBOutlet UILabel *detailLabel;
@property(weak, nonatomic) IBOutlet CircleProgressBar *circleProgressBar;
@property(weak, nonatomic) IBOutlet MBContactPicker *pickerView;
@property(weak, nonatomic) IBOutlet UIButton *inviteNowButton;
@property(weak, nonatomic) IBOutlet UIButton *cancelButton;
@property NSInteger targetInviteNumber;
@property NSInteger currentInviteNumber;
@property(weak, nonatomic) IBOutlet UIView *progressContainerView;
@property(weak, nonatomic) IBOutlet UIView *pickerContainerView;
@property(weak, nonatomic) IBOutlet UIButton *doneButton;

@property(weak, nonatomic) IBOutlet NSLayoutConstraint *contactPickerHeightContraint;
@property(nonatomic) BOOL useAcceptedInvites;

// Returns a task that has an NSNumber boolean value. YES if the video can be unlocked now
// and NO otherwise.
- (BFTask *)show;
@end
