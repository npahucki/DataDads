//
//  VideoSupportUnlockView.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 4/29/15.
//  Copyright (c) 2015 DataParenting. All rights reserved.
//
#define DIALOG_INSET 20.0F

#import <Bolts/BFExecutor.h>
#import "VideoSupportUnlockView.h"
#import "BFTask.h"
#import "BFTaskCompletionSource.h"
#import "InviteContactsAddressBookDataSource.h"
#import "NSString+EmailAddress.h"
#import "MBContactPicker+ForceCompletion.h"
#import "FollowConnectionUtils.h"
#import "InAppPurchaseHelper.h"

@implementation VideoSupportUnlockView {
    UIView *_dialogView;
    BFTaskCompletionSource *_completionSource;
    InviteContactsAddressBookDataSource *_addressBookDataSource;
    BOOL _inviteMode;
    BOOL _showedPermissionWarning;
}

- (IBAction)didTouchDoneInvitingButton:(id)sender {
    if ([_pickerView forcePendingTextEntry]) {
        [self setInviteMode:NO];
        if (_pickerView.contactsSelected.count) {
            [self sendInvites];
        }
    }
}

- (IBAction)didRequestPurchaseRestore:(id)sender {
    if(self.titleLabel.userInteractionEnabled) {
        self.titleLabel.userInteractionEnabled = NO; // prevent from fireing more than once.
        [self.view removeFromSuperview];
        [[InAppPurchaseHelper instance] ensureProductPurchased:DDProductVideoSupport withBlock:^(BOOL succeeded, NSError * __nullable error) {
            [_completionSource setResult:@(succeeded)];
            if(error) [UsageAnalytics trackError:error forOperationNamed:@"Restore or purchase video"];
        }];
    }
}

- (IBAction)didTouchInviteNowButton:(id)sender {
    [FollowConnectionUtils ensureCurrentUserHasEmailPresentIn:self andRunBlock:^(BOOL success, NSError *emailError) {
        if (success) {
            if (_currentInviteNumber >= _targetInviteNumber) {
                // If there was an error sending the invites, this will allow a retry if we already have enough
                // to unlock the videos.
                [self sendInvites];
            } else {
                [self setInviteMode:YES];
            }
        }
    }];
}

- (IBAction)didTouchCancelButton:(id)sender {
    [UsageAnalytics trackUnlockDecision:NO forProductId:@"Video"];
    [_completionSource trySetCancelled];
    [self close];

}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.cancelButton.enabled = YES; // but enable the cancel button...in case we can't load!
    self.pickerView.delegate = self;
    _dialogView = [[NSBundle mainBundle] loadNibNamed:@"VideoSupportUnlockView" owner:self options:nil][0];
    _dialogView.layer.shouldRasterize = YES;
    _dialogView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    _dialogView.layer.cornerRadius = 7;
    _dialogView.frame = CGRectInset(self.view.bounds, DIALOG_INSET, DIALOG_INSET);

    // For the black background
    self.view.frame = [UIScreen mainScreen].bounds;
    self.view.layer.shouldRasterize = YES;
    self.view.layer.rasterizationScale = [[UIScreen mainScreen] scale];

    [self applyMotionEffects];
    _dialogView.layer.opacity = 0.5f;
    _dialogView.layer.transform = CATransform3DMakeScale(1.3f, 1.3f, 1.0);

    self.view.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    [self.view addSubview:_dialogView];


    [_inviteNowButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

    _titleLabel.font = [UIFont fontForAppWithType:Bold andSize:21.0];
    _detailLabel.font = [UIFont fontForAppWithType:Medium andSize:18.0];
    _doneButton.titleLabel.font = [UIFont fontForAppWithType:Bold andSize:15.0];

    _circleProgressBar.progressBarWidth = 45;
    _circleProgressBar.startAngle = 270.0;
    _circleProgressBar.hintViewBackgroundColor = [UIColor whiteColor];
    _circleProgressBar.backgroundColor = [UIColor whiteColor];
    _circleProgressBar.progressBarTrackColor = [UIColor appLightColor];
    _circleProgressBar.progressBarProgressColor = [UIColor appNormalColor];
    _circleProgressBar.hintTextColor = [UIColor appNormalColor];
    _circleProgressBar.hintTextFont = [UIFont fontForAppWithType:Book andSize:30];
    _circleProgressBar.hintHidden = NO;
    [_circleProgressBar setHintTextGenerationBlock:^NSString *(CGFloat progress) {
        return [NSString stringWithFormat:@"%ld of %ld", (long) _currentInviteNumber, (long) _targetInviteNumber];
    }];

    _pickerView.layer.borderColor = [UIColor appNormalColor].CGColor;
    _pickerView.layer.borderWidth = 1;
    _pickerView.allowsCompletionOfSelectedContacts = NO;
    _pickerView.prompt = @"Invite:";
    _pickerView.maxVisibleRows = 5;
    _pickerView.delegate = self;
    _pickerView.datasource = self.addressBookDataSource;

    [[MBContactCollectionViewContactCell appearance] setTintColor:[UIColor appNormalColor]];

    self.pickerContainerView.alpha = 0.0F;
}

- (void)setInviteMode:(BOOL)inviting {
    _inviteMode = inviting;
    self.inviteNowButton.hidden = self.cancelButton.hidden = _inviteMode;
    [UIView animateWithDuration:0.3 animations:^{
        self.pickerContainerView.alpha = _inviteMode ? 1.0F : 0.0F;
        self.progressContainerView.alpha = _inviteMode ? 0.0F : 1.0F;
    }                completion:^(BOOL finished) {
        if (_inviteMode) {
            for (FollowConnection *conn in self.invites) {
                [self.addressBookDataSource addExcludeContactWithEmail:conn.otherPartyEmail];
            }
            [self.addressBookDataSource ensureAddressBookOpenWithBlock:^(BOOL succeeded, NSError *error) {
                if (error) {
                    [UsageAnalytics trackError:error forOperationNamed:@"openAddressBook"];
                }
                if (succeeded) {
                    [self.pickerView reloadData];
                } else {
                    // UIAlert, if not shown already.
                    if (!_showedPermissionWarning) {
                        _showedPermissionWarning = YES;
                        [[[UIAlertView alloc] initWithTitle:@"No Access To Contacts" message:@"You will need to enter email addresses manualy. To enable picking from your contacts go to the Privacy->Contacts section in the Settings app and enable access for DataParenting." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                    }
                }
            }];
            [self.pickerView becomeFirstResponder];
        } else {
            [self.pickerView resignFirstResponder];
        }
    }];
}

- (void)updateProgress {

    if (_useAcceptedInvites) {
        self.detailLabel.text = [NSString stringWithFormat:@"Signup %ld more friends with babies", (long) _targetInviteNumber];
    } else {
        int remaining = _targetInviteNumber - _currentInviteNumber;
        if (remaining > 0) {
            self.detailLabel.hidden = NO;
            NSDictionary *normalAttributes = @{NSFontAttributeName : [UIFont fontForAppWithType:Medium andSize:15]};
            NSDictionary *bolderAttributes = @{NSFontAttributeName : [UIFont fontForAppWithType:Bold andSize:19], NSForegroundColorAttributeName : [UIColor appNormalColor]};
            NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:@"Invite " attributes:normalAttributes];
            [text appendAttributedString:[[NSAttributedString alloc] initWithString:[@(remaining) stringValue] attributes:bolderAttributes]];
            [text appendAttributedString:[[NSAttributedString alloc] initWithString:@" more friends or relatives to follow " attributes:normalAttributes]];
            [text appendAttributedString:[[NSAttributedString alloc] initWithString:[Baby currentBaby].name attributes:bolderAttributes]];
            [text appendAttributedString:[[NSAttributedString alloc] initWithString:@"'s progress" attributes:normalAttributes]];
            self.detailLabel.attributedText = text;
        } else {
            self.detailLabel.hidden = YES;
        }

    }
    [_circleProgressBar setProgress:((CGFloat) _currentInviteNumber) / ((CGFloat) _targetInviteNumber) animated:YES];
}

- (BFTask *)show {
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    [self viewDidLoad];

    // Attached to the top most window (make sure we are using the right orientation):
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    switch (interfaceOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
            self.view.transform = CGAffineTransformMakeRotation(M_PI * 270.0 / 180.0);
            break;

        case UIInterfaceOrientationLandscapeRight:
            self.view.transform = CGAffineTransformMakeRotation(M_PI * 90.0 / 180.0);
            break;

        case UIInterfaceOrientationPortraitUpsideDown:
            self.view.transform = CGAffineTransformMakeRotation(M_PI * 180.0 / 180.0);
            break;

        default:
            break;
    }
    [[[[UIApplication sharedApplication] windows] firstObject] addSubview:self.view];
    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.view.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4f];
                         _dialogView.layer.opacity = 1.0f;
                         _dialogView.layer.transform = CATransform3DMakeScale(1, 1, 1);
                     }
                     completion:^(BOOL finished) {
                         [self updateProgress];
                     }
    ];

    _completionSource = [BFTaskCompletionSource taskCompletionSource];
    return _completionSource.task;
}

- (void)close {
    CATransform3D currentTransform = _dialogView.layer.transform;

    CGFloat startRotation = [[_dialogView valueForKeyPath:@"layer.transform.rotation.z"] floatValue];
    CATransform3D rotation = CATransform3DMakeRotation(-startRotation + M_PI * 270.0 / 180.0, 0.0f, 0.0f, 0.0f);

    _dialogView.layer.transform = CATransform3DConcat(rotation, CATransform3DMakeScale(1, 1, 1));
    _dialogView.layer.opacity = 1.0f;

    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionTransitionNone
                     animations:^{
                         self.view.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.0f];
                         _dialogView.layer.transform = CATransform3DConcat(currentTransform, CATransform3DMakeScale(0.6f, 0.6f, 1.0));
                         _dialogView.layer.opacity = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         [self.view removeFromSuperview];
                     }
    ];
}


- (void)applyMotionEffects {
    NSInteger kCustomIOS7MotionEffectExtent = 10;

    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        return;
    }

    UIInterpolatingMotionEffect *horizontalEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
                                                                                                    type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    horizontalEffect.minimumRelativeValue = @(-kCustomIOS7MotionEffectExtent);
    horizontalEffect.maximumRelativeValue = @( kCustomIOS7MotionEffectExtent);

    UIInterpolatingMotionEffect *verticalEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
                                                                                                  type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    verticalEffect.minimumRelativeValue = @(-kCustomIOS7MotionEffectExtent);
    verticalEffect.maximumRelativeValue = @( kCustomIOS7MotionEffectExtent);

    UIMotionEffectGroup *motionEffectGroup = [[UIMotionEffectGroup alloc] init];
    motionEffectGroup.motionEffects = @[horizontalEffect, verticalEffect];

    [_dialogView addMotionEffect:motionEffectGroup];
}

- (InviteContactsAddressBookDataSource *)addressBookDataSource {
    if (!_addressBookDataSource) {
        _addressBookDataSource = [[InviteContactsAddressBookDataSource alloc] init];
        [_addressBookDataSource addExcludeContactWithEmail:[PFUser currentUser].email];
    }
    return _addressBookDataSource;
}


// NOTE: This method is named badly.
- (void)contactPicker:(MBContactPicker *)contactPicker didEnterCustomText:(NSString *)text {
    if (text.isValidEmailAddress && ![self.addressBookDataSource isEmailExcluded:text]) {
        InviteContact *contact = [[InviteContact alloc] init];
        contact.emailAddress = text;
        [_pickerView addToSelectedContacts:contact];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Whoops" message:@"Invalid email address or email already used, please correct it"
                                   delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    }
}


// This delegate method is called to allow the parent view to increase the size of
// the contact picker view to show the search table view
- (void)didShowFilteredContactsForContactPicker:(MBContactPicker *)contactPicker {
    if (self.contactPickerHeightContraint.constant <= contactPicker.currentContentHeight) {
        CGRect pickerRectInWindow = [_pickerContainerView convertRect:contactPicker.frame fromView:nil];
        CGFloat newHeight = _pickerContainerView.window.bounds.size.height - pickerRectInWindow.origin.y - contactPicker.keyboardHeight;
        [self setPickerHeight:newHeight animated:YES];
    }
}

// This delegate method is called to allow the parent view to decrease the size of
// the contact picker view to hide the search table view
- (void)didHideFilteredContactsForContactPicker:(MBContactPicker *)contactPicker {
    if (self.contactPickerHeightContraint.constant > contactPicker.currentContentHeight) {
        [self setPickerHeight:contactPicker.currentContentHeight animated:YES];
    }
}

// This delegate method is invoked to allow the parent to increase the size of the
// collectionview that shows which contacts have been selected. To increase or decrease
// the number of rows visible, change the maxVisibleRows property of the MBContactPicker
- (void)contactPicker:(MBContactPicker *)contactPicker didUpdateContentHeightTo:(CGFloat)newHeight {
    if (_inviteMode) {
        [self setPickerHeight:newHeight animated:YES];
    }
}

- (void)setPickerHeight:(CGFloat)height animated:(BOOL)animated {
    self.contactPickerHeightContraint.constant = height;
    [_pickerContainerView setNeedsLayout];
    if (animated) {
        [UIView animateWithDuration:self.pickerView.animationSpeed animations:^{
            [_pickerContainerView layoutIfNeeded];
        }];
    } else {
        [_pickerContainerView layoutIfNeeded];
    }

}

- (void)contactCollectionView:(MBContactCollectionView *)contactCollectionView didAddContact:(id <MBContactPickerModelProtocol>)model {
    _currentInviteNumber++;
    [self updateProgress];
}

- (void)contactCollectionView:(MBContactCollectionView *)contactCollectionView didRemoveContact:(id <MBContactPickerModelProtocol>)model {
    _currentInviteNumber--;
    [self updateProgress];
}

- (void)sendInvites {
    self.inviteNowButton.enabled = NO;
    [self.activityIndicator startAnimating];
    // We need a name from which to send the invite.
    [[[[FollowConnectionUtils ensureCurrentUserHasEmailPresentIn:self] continueWithSuccessBlock:^id(BFTask *task) {
        if ([((NSNumber *) task.result) boolValue]) {
            return [FollowConnectionUtils makeBestAttemptToPopulateSendersFullNameUsingAddressBookDataSource:_addressBookDataSource];
        } else {
            return nil;
        }
    }] continueWithSuccessBlock:^id(BFTask *task) {
        return [FollowConnection sendInvites:_pickerView.contactsSelected];
    }] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
        self.inviteNowButton.enabled = YES;
        [self.activityIndicator stopAnimating];
        if (task.error) {
            [UsageAnalytics trackError:task.error forOperationNamed:@"sendInvites"];
            [[[UIAlertView alloc] initWithTitle:@"Could Not Send Invites" message:@"There was an error trying to send the invites. Make sure you have an internet connection and try again" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        } else {
            // Show any invites in the window now.
            if (_currentInviteNumber >= _targetInviteNumber) {
                [self close];
                [[[UIAlertView alloc] initWithTitle:@"Congrats!" message:@"You have unlocked unlimited video storage!" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] showWithButtonBlock:^(NSInteger buttonIndex) {
                    [UsageAnalytics trackUnlockDecision:YES forProductId:@"Video"];
                    // we reached the target, dismiss the box
                    [_completionSource setResult:@(YES)];
                }];
            }
        }
        return nil;
    }];


}


@end
