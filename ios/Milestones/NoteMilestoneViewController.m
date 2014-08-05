//
//  MilestoneNotedViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/21/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "NoteMilestoneViewController.h"
#import "WebViewerViewController.h"
#import "UnitHelper.h"
#import "UIImage+FX.h"
#import "TutorialBubbleView.h"

@interface NoteMilestoneViewController ()

@end

@implementation NoteMilestoneViewController {
    FDTakeController *_takeController;
    NSData *_imageOrVideo;
    NSString *_imageOrVideoType;
    ALAssetsLibrary *_assetLibrary;
    BOOL _isKeyboardShowing;
    CGRect _originalFrame;
    UITextField *_activeField;

}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.adView.containingViewController = self;
    _imageOrVideo = nil;
    _imageOrVideoType = nil;

    NSAssert(self.achievement.baby, @"baby must be set on acheivement before view loads");

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];


    if (self.isCustom) {
        self.detailsContainerView.hidden = YES;
        self.scrollView.hidden = NO;
        self.heightUnitLabel.text = [UnitHelper unitForHeight];
        self.weightUnitLabel.text = [UnitHelper unitForWeight];
        self.segmentControl.hidden = NO;
        self.doneButton.enabled = NO;


        // Icky hack to work around the fact that you can't both set an image and test on segmented control. 
        [self.segmentControl setImage:[[UIImage imageNamed:@"milestonesIcon"] imageWithString:@"Milestone"] forSegmentAtIndex:0];
        [self.segmentControl setImage:[[UIImage imageNamed:@"measurementsIcon"] imageWithString:@"Measurement"] forSegmentAtIndex:1];


    } else {
        self.rangeLabel.font = [UIFont fontForAppWithType:Light andSize:11];
        self.rangeIndicatorView.rangeScale = 5 * 365; // 5 years
        self.rangeIndicatorView.rangeReferencePoint = Baby.currentBaby.daysSinceDueDate;
        self.rangeIndicatorView.userInteractionEnabled = YES;
        [self.rangeIndicatorView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didClickRangeIndicator:)]];
        self.titleTextView.linkTextAttributes = @{NSForegroundColorAttributeName : [UIColor appSelectedColor],
                NSUnderlineColorAttributeName : [UIColor appSelectedColor],
                NSUnderlineStyleAttributeName : @(NSUnderlinePatternSolid)};
        self.detailsContainerView.hidden = NO;
        self.scrollView.hidden = YES;
        self.segmentControl.hidden = YES;
        self.doneButton.enabled = YES;
    }

    [self.doneButton setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontForAppWithType:Bold andSize:17]} forState:UIControlStateNormal];
    self.completionDateTextField.inputAccessoryView = nil;



    // Needed to dimiss the keyboard once a user clicks outside the text boxes
    UITapGestureRecognizer *viewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self.view addGestureRecognizer:viewTap];

    self.fbSwitch = [[SevenSwitch alloc] initWithFrame:CGRectMake(10, 10, 50, 30)];
    [self.view addSubview:_fbSwitch];
    [_fbSwitch addTarget:self action:@selector(didChangeFacebookSwitch:) forControlEvents:UIControlEventValueChanged];
    _fbSwitch.thumbImage = [UIImage imageNamed:@"facebookSwitch"];
    _fbSwitch.thumbTintColor = UIColorFromRGB(0x3B5999); // Facebook color
    _fbSwitch.isRounded = NO;
    _fbSwitch.inactiveColor = [UIColor appHeaderBackgroundNormalColor];
    _fbSwitch.activeColor = [UIColor appHeaderBackgroundActiveColor];
    _fbSwitch.borderColor = [UIColor appInputBorderNormalColor];
    _fbSwitch.labelFont = [UIFont fontForAppWithType:Medium andSize:10];

    _fbSwitch.onText = @"On";
    _fbSwitch.onFontColor = [UIColor appNormalColor];
    _fbSwitch.onTintColor = [UIColor appHeaderBackgroundNormalColor];

    _fbSwitch.offText = @"Off";
    _fbSwitch.offFontColor = UIColorFromRGB(0xb2c0c3);

    //_fbSwitch.shadowColor = [UIColor blackColor];
    [_fbSwitch setOn:ParentUser.currentUser.autoPublishToFacebook && [PFFacebookUtils userHasAuthorizedPublishPermissions:ParentUser.currentUser] animated:NO];

    self.commentsTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.commentsTextField.attributedPlaceholder.string attributes:@{NSForegroundColorAttributeName : [UIColor appGreyTextColor]}];
    self.customTitleTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.customTitleTextField.attributedPlaceholder.string attributes:@{NSForegroundColorAttributeName : [UIColor appGreyTextColor]}];

}

- (void)viewDidAppear:(BOOL)animated {
    if (!self.isCustom) {
        self.rangeIndicatorView.startRange = self.achievement.standardMilestone.rangeLow.integerValue;
        self.rangeIndicatorView.endRange = self.achievement.standardMilestone.rangeHigh.integerValue;
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification *)aNotification {
    NSDictionary *info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    if (!_isKeyboardShowing) {
        _isKeyboardShowing = YES;
        _originalFrame = self.view.frame;
    }
    // NOTE: we use this instead of scroll view because working woth autolayout and the scroll view is almost impossible
    // becasue we resize some content based on the size of the screen, and in scrollview, this means that the content is
    // as large as it can be, but is scrollable which is NOT what we want!

    if (_activeField.frame.size.height + _activeField.frame.origin.y > self.view.frame.size.height - kbSize.height) {
        [UIView
                animateWithDuration:0.5
                         animations:^{
            self.view.frame = CGRectMake(0, _originalFrame.origin.y - kbSize.height + self.adView.frame.size.height, _originalFrame.size.width, _originalFrame.size.height);
        }];
    }
}


// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification *)aNotification {
    _isKeyboardShowing = NO;
    [UIView
            animateWithDuration:0.5
                     animations:^{
        self.view.frame = _originalFrame;
    }];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    _activeField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    _activeField = nil;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    if (textField == self.weightTextField) {
        self.doneButton.enabled = string.floatValue > 0 && self.heightTextField.text.floatValue > 0;
        return (newLength < 5);
    } else if (textField == self.heightTextField) {
        self.doneButton.enabled = string.floatValue > 0 && self.weightTextField.text.floatValue > 0;
        return (newLength < 5);
    } else if (textField == self.customTitleTextField) {
        self.doneButton.enabled = newLength > 0;
    }

    return YES;
}

- (void)handleSingleTap:(UITapGestureRecognizer *)sender {
    [self.view endEditing:NO];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGFloat x = scrollView.contentOffset.x;
    CGFloat w = scrollView.bounds.size.width;
    self.segmentControl.selectedSegmentIndex = x / w;
    [self updateCurrentNavigationTitle];
}

- (IBAction)userDidPage:(id)sender {
    NSInteger p = self.segmentControl.selectedSegmentIndex;
    CGFloat w = self.scrollView.bounds.size.width;
    [self.scrollView setContentOffset:CGPointMake(p * w, 0) animated:YES];
    if (self.isMeasurement) {
        self.doneButton.enabled = self.weightTextField.text.floatValue > 0;
    } else {
        self.doneButton.enabled = self.customTitleTextField.text.length > 0;
    }
    [self updateCurrentNavigationTitle];
}

- (void)updateCurrentNavigationTitle {
    self.navigationItem.title = self.segmentControl.selectedSegmentIndex == 0 ? @"Note Milestone" : @"Note Measurement";
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.fbSwitch.frame = self.placeHolderSwitch.frame;
    // NOTE: For some odd reason, this will not work is done in viewDidLoad!
    if (self.achievement.standardMilestone) self.titleTextView.attributedText = [self createTitleTextFromMilestone];


    // Center the text veritcally in the TextView
    CGFloat requiredHeight = [self.titleTextView sizeThatFits:CGSizeMake([self.titleTextView contentSize].width, FLT_MAX)].height;
    if (requiredHeight < self.titleTextView.contentSize.height) {
        CGFloat offset = self.titleTextView.contentSize.height - requiredHeight;
        self.titleTextView.contentInset = UIEdgeInsetsMake(offset / 2, 0, offset / 2, 0);
    }

    // Make the bottom of the Text field fade out
    CAGradientLayer *l = [CAGradientLayer layer];
    l.frame = self.titleTextFadingView.bounds;
    l.colors = [NSArray arrayWithObjects:(id) [UIColor whiteColor].CGColor, (id) [UIColor clearColor].CGColor, nil];
    l.startPoint = CGPointMake(0.5f, 0.5f);
    l.endPoint = CGPointMake(0.5f, 1.0f);
    self.titleTextFadingView.layer.mask = l;
}

- (void)didClickRangeIndicator:(id)sender {
    TutorialBubbleView *bubble = [[[NSBundle mainBundle] loadNibNamed:@"TutorialBubbleView" owner:self options:nil] objectAtIndex:0];
    CGPoint relativePoint = CGPointMake(self.rangeIndicatorView.center.x, self.rangeIndicatorView.frame.origin.y + self.rangeIndicatorView.frame.size.height + 5);
    bubble.arrowTip = [self.rangeIndicatorView.superview convertPoint:relativePoint toView:self.view];
    bubble.textLabel.font = [UIFont fontForAppWithType:Medium andSize:16];
    [bubble showInView:self.view withText:[NSString stringWithFormat:@"The shaded area represents the typical range. The dot shows where %@ is.", Baby.currentBaby.name]];
}

- (IBAction)didClickTakePicture:(id)sender {
    [self.view endEditing:YES];
    _takeController = [[FDTakeController alloc] init];
    _takeController.delegate = self;
    _takeController.viewControllerForPresentingImagePickerController = self;
    _takeController.allowsEditingPhoto = NO; // NOTE: Allowing photo editing causes a problem with landscape pictures!
    _takeController.allowsEditingVideo = NO;
    [_takeController takePhotoOrChooseFromLibrary];
}

- (IBAction)didClickDoneButton:(id)sender {
    [self.view endEditing:YES];

    if ([Reachability showAlertIfParseNotReachable]) return;

    if (_imageOrVideo) {
        [self saveImageOrPhoto];
    } else {
        [self saveAchievementWithAttachment:nil andType:nil];
    }
}

- (IBAction)didClickCancelButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didChangeFacebookSwitch:(id)sender {
    if (self.fbSwitch.on) {
        [PFFacebookUtils ensureHasPublishPermissions:ParentUser.currentUser block:^(BOOL succeeded, NSError *error) {
            if (error) {
                [PFFacebookUtils showAlertIfFacebookDisplayableError:error];
                [self.fbSwitch setOn:NO animated:YES];
            } else if (!succeeded) {
                // User did not link or did not give permissions.
                [self.fbSwitch setOn:NO animated:YES];
            }
        }];
    }

    // Remember for future uses.
    if (ParentUser.currentUser.autoPublishToFacebook != self.fbSwitch.on) {
        ParentUser.currentUser.autoPublishToFacebook = self.fbSwitch.on;
        [ParentUser.currentUser saveEventually:^(BOOL succeeded, NSError *error) {
            if (succeeded) [ParentUser.currentUser refreshInBackgroundWithBlock:nil]; // Make sure cache is updated
        }];
    }
}

- (void)saveImageOrPhoto {
    [self showInProgressHUDWithMessage:@"Uploading Photo" andAnimation:YES andDimmedBackground:YES];
    PFFile *file = [PFFile fileWithData:_imageOrVideo];
    [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error) {
            [self showErrorThenRunBlock:error withMessage:@"Could not upload the photo." andBlock:nil];
        } else {
            [self saveAchievementWithAttachment:file andType:_imageOrVideoType];
        }
    }];
}

- (void)saveAchievementWithAttachment:(PFFile *)attachment andType:(NSString *)type {

    // Bit of a hacky work around to the fact that CloudCode beforeSave trigger reloads the object after a save
    // buts does not load the pointers, so the achievement object has the Baby and StandardMilestone fields set to
    // hollow pointers (do data but the objectId). We would normally need to make two more network calls to get
    // these two objects back (needed for code that runs in the notification handlers). However, we assume
    // that the CloudCode trigger scripts are NOT changing the baby or StandardMilestone, meaning that we can save the
    // values here, and restore them later (after asserting that the objectIds are the same of course!).
    StandardMilestone *originalMilestone = self.achievement.standardMilestone; // this will be nil for custom milestones.
    Baby *originalBaby = self.achievement.baby;

    Measurement *heightMeasurement;
    Measurement *weightMeasurement;
    if (self.isMeasurement) {
        heightMeasurement = [Measurement object];
        heightMeasurement.type = @"height";
        heightMeasurement.unit = self.heightUnitLabel.text;
        heightMeasurement.quantity = @(self.heightTextField.text.floatValue);
        heightMeasurement.achievement = self.achievement;
        heightMeasurement.baby = self.achievement.baby;

        weightMeasurement = [Measurement object];
        weightMeasurement.type = @"weight";
        weightMeasurement.unit = self.weightUnitLabel.text;
        weightMeasurement.quantity = @(self.weightTextField.text.floatValue);
        weightMeasurement.achievement = self.achievement;
        weightMeasurement.baby = self.achievement.baby;

        self.achievement.customTitle = [NSString stringWithFormat:@"${He} reaches %@%@ and %@%@!", heightMeasurement.quantity, heightMeasurement.unit, weightMeasurement.quantity, weightMeasurement.unit];
    } else if (self.isCustom) {
        NSAssert(self.customTitleTextField.text.length, @"Expected non empty custom title!");
        self.achievement.customTitle = self.customTitleTextField.text;
    }

    if (self.commentsTextField.text.length) self.achievement.comment = self.commentsTextField.text;
    self.achievement.attachment = attachment;
    self.achievement.attachmentType = type;
    self.achievement.completionDate = self.completionDateTextField.date;
    self.achievement.sharedVia = self.fbSwitch.on ? SharingMediumFacebook : SharingMediumNotShared;
    [self saveObject:self.achievement withTitle:@"Noting Milestone" andFailureMessage:@"Could not note milestone." andBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            // SEE NOTE ABOVE
            if (!self.achievement.baby.isDataAvailable) {
                NSAssert([self.achievement.baby.objectId isEqualToString:originalBaby.objectId], @"The server unexpectedly changed the Baby in the achievement!");
                self.achievement.baby = originalBaby; // avoid network call
            }
            if (originalMilestone && !self.achievement.standardMilestone.isDataAvailable) {
                NSAssert([self.achievement.standardMilestone.objectId isEqualToString:originalMilestone.objectId], @"The server unexpectedly changed the Milestone in the achievement!");
                self.achievement.standardMilestone = originalMilestone; // avoid network call
            }

            // Notify locally
            [[NSNotificationCenter defaultCenter] postNotificationName:kDDNotificationMilestoneNotedAndSaved object:self.achievement];

            // Publish the achievement to facebook
            if (self.fbSwitch.on) {
                [PFFacebookUtils shareAchievement:self.achievement block:^(BOOL succeeded, NSError *error) {
                    if (error) {
                        [[[UIAlertView alloc] initWithTitle:@"Could not share the milestone on Facebook" message:@"Make sure that you have authorized the DataParenting App at https://www.facebook.com/settings?tab=applications" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                    }
                }];
            }



            // Save the measurments (if any)
            if (heightMeasurement)
                [heightMeasurement saveEventually:^(BOOL succeeded, NSError *error) {
                    if (error) {
                        NSLog(@"Could not save the height measurement %@", error);
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:kDDNotificationMeasurementNotedAndSaved object:heightMeasurement];
                }];
            if (weightMeasurement)
                [weightMeasurement saveEventually:^(BOOL succeeded, NSError *error) {
                    if (error) {
                        NSLog(@"Could not save the weight measurement %@", error);
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:kDDNotificationMeasurementNotedAndSaved object:weightMeasurement];
                }];

            if (self.isMeasurement) {
                if (heightMeasurement) [UsageAnalytics trackMeasurement:heightMeasurement];
                if (weightMeasurement) [UsageAnalytics trackMeasurement:weightMeasurement];
            } else {
                [UsageAnalytics trackAchievementLogged:self.achievement sharedOnFacebook:self.fbSwitch.on];
            }
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
}

- (BOOL)isMeasurement {
    return self.isCustom && self.segmentControl.selectedSegmentIndex == 1;
}

- (BOOL)isCustom {
    return self.achievement.standardMilestone == nil;
}

#pragma mark - FDTakeDelegate

- (void)takeController:(FDTakeController *)controller gotPhoto:(UIImage *)photo withInfo:(NSDictionary *)info {
    // Attempt to use date from the photo taken, instead of the current date
    NSURL *assetURL = [info objectForKey:UIImagePickerControllerReferenceURL];
    if (assetURL) {
        if (!_assetLibrary) {
            _assetLibrary = [[ALAssetsLibrary alloc] init];
        }
        [_assetLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset) {
            NSDate *createDate = [asset valueForProperty:ALAssetPropertyDate];
            if (createDate) {

                if ([self.achievement.baby daysSinceBirthDate:createDate] < 0) {
                    [[[UIAlertView alloc] initWithTitle:@"Hmmmm" message:@"This photo seems to have been taken before baby was born - we'll use baby's birthdate instead, but feel free to correct it." delegate:nil cancelButtonTitle:@"Accept" otherButtonTitles:nil, nil] show];
                    createDate = self.achievement.baby.birthDate;
                }


                if ([self.completionDateTextField.date compare:createDate]) {
                    // Label to show the date has been changed., based on the phtoto date
                    UILabel *newDateLabel = [[UILabel alloc] init];
                    newDateLabel.textColor = self.completionDateTextField.textColor;
                    newDateLabel.font = self.completionDateTextField.font;
                    newDateLabel.text = [self.completionDateTextField.dateFormatter stringFromDate:createDate];
                    [newDateLabel sizeToFit];
                    newDateLabel.center = self.takePhotoButton.center;
                    [self.view addSubview:newDateLabel];

                    newDateLabel.transform = CGAffineTransformScale(newDateLabel.transform, 2.5, 2.5);
                    [UILabel animateWithDuration:0.5 animations:^{
                        newDateLabel.transform = CGAffineTransformScale(newDateLabel.transform, .5, .5);
                        newDateLabel.frame = CGRectMake(self.completionDateTextField.frame.origin.x + 5, self.completionDateTextField.frame.origin.y + 5, newDateLabel.frame.size.width, newDateLabel.frame.size.height);
                    }                 completion:^(BOOL finished) {
                        [newDateLabel removeFromSuperview];
                        self.completionDateTextField.date = createDate;
                    }];
                }
            }
        }             failureBlock:^(NSError *error) {
            // NSLog(@"Failed to get asset from library");
        }];
    }


    // TODO: Support video too!
    _imageOrVideo = UIImageJPEGRepresentation(photo, 0.5f);
    _imageOrVideoType = @"image/jpg";
    CGSize scaleSize = CGSizeMake(self.takePhotoButton.bounds.size.width * 2, self.takePhotoButton.bounds.size.height * 2);
    [self.takePhotoButton setImage:[photo imageScaledToFitSize:scaleSize] forState:UIControlStateNormal];
}

- (NSAttributedString *)createTitleTextFromMilestone {
    StandardMilestone *m = self.achievement.standardMilestone;
    NSMutableAttributedString *attrText = [[NSMutableAttributedString alloc] init];
    NSAttributedString *lf = [[NSAttributedString alloc] initWithString:@"\n"];
    NSDictionary *dataLabelTextAttributes = @{NSFontAttributeName : [UIFont fontForAppWithType:Medium andSize:13.0], NSForegroundColorAttributeName : [UIColor blackColor]};
    NSDictionary *dataValueTextAttributes = @{NSFontAttributeName : [UIFont fontForAppWithType:Light andSize:13.0], NSForegroundColorAttributeName : [UIColor blackColor]};


    NSAttributedString *titleString = [[NSAttributedString alloc] initWithString:[m titleForBaby:self.achievement.baby] attributes:@{NSFontAttributeName : [UIFont fontForAppWithType:Bold andSize:13.0], NSForegroundColorAttributeName : [UIColor appNormalColor]}];
    [attrText appendAttributedString:titleString];
    [attrText appendAttributedString:lf];
    [attrText appendAttributedString:lf];

    if (self.achievement.standardMilestone.enteredBy) {
        NSAttributedString *enteredByLabel = [[NSAttributedString alloc] initWithString:@"First Noted By: " attributes:dataLabelTextAttributes];
        NSAttributedString *enteredByValue = [[NSAttributedString alloc] initWithString:self.achievement.standardMilestone.enteredBy attributes:dataValueTextAttributes];
        [attrText appendAttributedString:lf];
        [attrText appendAttributedString:enteredByLabel];
        [attrText appendAttributedString:enteredByValue];
        [attrText appendAttributedString:lf];
    }

    NSAttributedString *rangeLabel = [[NSAttributedString alloc] initWithString:@"Typical Range: " attributes:dataLabelTextAttributes];
    NSAttributedString *rangeValue = [[NSAttributedString alloc] initWithString:m.humanReadableRange];
    [attrText appendAttributedString:rangeLabel];
    [attrText appendAttributedString:rangeValue];

    if (m.url) {
        [attrText appendAttributedString:lf];
        [attrText appendAttributedString:lf];
        NSMutableAttributedString *readMoreLabel = [[NSMutableAttributedString alloc] initWithString:@"Read More..." attributes:@{
                NSFontAttributeName : [UIFont fontForAppWithType:BoldItalic andSize:17.0],
                NSForegroundColorAttributeName : [UIColor appSelectedColor]
        }];
        [readMoreLabel addAttribute:NSLinkAttributeName value:m.url range:NSMakeRange(0, readMoreLabel.length)];
        [attrText appendAttributedString:readMoreLabel];
    }

    return attrText;

}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)url inRange:(NSRange)characterRange {
    [self presentViewController:[WebViewerViewController webViewForUrl:url] animated:YES completion:NULL];
    return NO;
}


@end
