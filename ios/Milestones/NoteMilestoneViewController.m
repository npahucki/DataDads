//
//  MilestoneNotedViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/21/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import <CMPopTipView/CMPopTipView.h>
#import "NoteMilestoneViewController.h"
#import "WebViewerViewController.h"
#import "UnitHelper.h"
#import "UIImage+FX.h"
#import "PFFile+Media.h"
#import "CMPopTipView+WithStaticInitializer.h"
#import "UIResponder+FirstResponder.h"
#import "VideoFeature.h"
#import "AdFreeFeature.h"

@interface NoteMilestoneViewController ()
@property CMPopTipView *tutorialBubbleView;
@end

@implementation NoteMilestoneViewController {
    FDTakeController *_takeController;
    NSObject <MediaFile> *_attachment;
    PFFile *_thumbnailImage;
    ALAssetsLibrary *_assetLibrary;
    BOOL _isKeyboardShowing;
    CGRect _originalFrame;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.adView.containingViewController = self;
    NSAssert(self.achievement.baby, @"baby must be set on acheivement before view loads");
    self.doneButton = self.parentViewController.navigationItem.rightBarButtonItem;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];

    // Decide to show the add or not.
    self.adView.delegate = self;
    [FeatureManager ensureFeatureUnlocked:[[AdFreeFeature alloc] init] withBlock:^(BOOL purchased, NSError *error) {
        if (purchased) {
            [self hideAdView];
        } else {
            [self.adView attemptAdLoad];
        }
    }];

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
        self.titleTextView.attributedText = [self createTitleTextFromMilestone];
    }

    [self.doneButton setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontForAppWithType:Bold andSize:17]} forState:UIControlStateNormal];
    self.completionDateTextField.inputAccessoryView = nil;
    self.completionDateTextField.minimumDate = Baby.currentBaby.birthDate;



    // Needed to dimiss the keyboard once a user clicks outside the text boxes
    UITapGestureRecognizer *viewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self.view addGestureRecognizer:viewTap];

    self.commentsTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.commentsTextField.attributedPlaceholder.string attributes:@{NSForegroundColorAttributeName : [UIColor appGreyTextColor]}];
    self.customTitleTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.customTitleTextField.attributedPlaceholder.string attributes:@{NSForegroundColorAttributeName : [UIColor appGreyTextColor]}];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.isCustom) {
        self.rangeIndicatorView.startRange = self.achievement.standardMilestone.rangeLow.integerValue;
        self.rangeIndicatorView.endRange = self.achievement.standardMilestone.rangeHigh.integerValue;
    }
    
    // Make the bottom of the Text field fade out
    CAGradientLayer *l = [CAGradientLayer layer];
    l.frame = self.titleTextFadingView.bounds;
    l.colors = @[(id) [UIColor whiteColor].CGColor, (id) [UIColor clearColor].CGColor];
    l.startPoint = CGPointMake(0.0f, 0.9f);
    l.endPoint = CGPointMake(0.0f, 1.0f);
    self.titleTextFadingView.layer.mask = l;
    
    // HACK ALERT: For some goddamn inexplicable reason, the first time that viewDidLayoutSubViews, the views have a wrong width and height on iPhone 6
    // Thus, the text can't be centered correctly in the scroll view. Once the view appears, the dimensions are correct - so we set the layout flag on
    // view. However, this causes the text to jump from the incorrect position to the correct position.
    // Animating it make it look a little less worse.
    [self.view setNeedsLayout];
    [UIView animateWithDuration:0.2 animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification *)aNotification {
    NSDictionary *info = [aNotification userInfo];
    CGSize kbSize = [info[UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    if (!_isKeyboardShowing) {
        _isKeyboardShowing = YES;
        _originalFrame = self.view.frame;
    }
    // NOTE: we use this instead of scroll view because working with autolayout and the scroll view is almost impossible
    // because we resize some content based on the size of the screen, and in scrollview, this means that the content is
    // as large as it can be, but is scrollable which is NOT what we want!
    UITextField *activeField = [UIResponder currentFirstResponder];
    if (activeField.frame.size.height + activeField.frame.origin.y > self.view.frame.size.height - kbSize.height) {
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

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    if (textField == self.weightTextField) {
        self.doneButton.enabled = [self.weightTextField.text stringByReplacingCharactersInRange:range withString:string].floatValue > 0 || self.heightTextField.text.floatValue > 0;
        return (newLength < 5);
    } else if (textField == self.heightTextField) {
        self.doneButton.enabled = [self.heightTextField.text stringByReplacingCharactersInRange:range withString:string].floatValue > 0 || self.weightTextField.text.floatValue > 0;
        return (newLength < 5);
    } else if (textField == self.customTitleTextField) {
        self.doneButton.enabled = newLength > 0;
    }

    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.completionDateTextField) {
        // Update so the sharing tab knows what the date is and can adjust settings as needed.
        self.achievement.completionDate = self.completionDateTextField.date;
    }
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
    self.segmentControl.selectedSegmentIndex = (NSInteger) (x / w);
    [self userDidPage:self];
}

- (IBAction)userDidPage:(id)sender {
    NSInteger p = self.segmentControl.selectedSegmentIndex;
    CGFloat w = self.scrollView.bounds.size.width;
    [self.scrollView setContentOffset:CGPointMake(p * w, 0) animated:YES];
    if (self.isMeasurement) {
        self.doneButton.enabled = self.weightTextField.text.floatValue > 0 || self.heightTextField.text.floatValue > 0;
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
    // Center the text veritcally in the TextView
     CGFloat requiredHeight = [self.titleTextView sizeThatFits:CGSizeMake(self.titleTextView.bounds.size.width, FLT_MAX)].height;
    if (requiredHeight < self.titleTextView.bounds.size.height) {
        CGFloat offset = self.titleTextView.bounds.size.height - requiredHeight;
        self.titleTextView.contentInset = UIEdgeInsetsMake(offset / 2, 0, offset / 2, 0);
    }
}

- (void)didClickRangeIndicator:(id)sender {
    if (_tutorialBubbleView) {
        [_tutorialBubbleView dismissAnimated:YES];
        _tutorialBubbleView = nil;
    } else {
        _tutorialBubbleView = [CMPopTipView instanceWithApplicationLookAndFeelAndMessage:
                [NSString stringWithFormat:@"The shaded area represents the typical range. The dot shows where %@ is.", Baby.currentBaby.name]];
        _tutorialBubbleView.delegate = self;
        _tutorialBubbleView.maxWidth = self.view.frame.size.width - 20;
        [_tutorialBubbleView presentPointingAtView:self.rangeIndicatorView inView:self.view animated:YES];
    }
}

- (void)popTipViewWasDismissedByUser:(CMPopTipView *)popTipView {
    _tutorialBubbleView = nil;
}

- (IBAction)didClickTakePicture:(id)sender {
    [self.view endEditing:YES];
    _takeController = [[FDTakeController alloc] init];
    _takeController.delegate = self;
    _takeController.viewControllerForPresentingImagePickerController = self;
    _takeController.allowsEditingPhoto = NO; // NOTE: Allowing photo editing causes a problem with landscape pictures!
    _takeController.allowsEditingVideo = YES;
    _takeController.imagePicker.videoQuality = UIImagePickerControllerQualityType640x480;
    _takeController.imagePicker.videoMaximumDuration = MAX_VIDEO_ATTACHMENT_LENGTH_SECS;
    [_takeController takePhotoOrVideoOrChooseFromLibrary];
}

- (void)noteMilestone {
    [self.view endEditing:YES];

    if ([Reachability showAlertIfParseNotReachable]) return;

    if (_attachment) {
        [self saveAttachment];
    } else {
        [self saveAchievement];
    }
}

- (void)saveAttachment {
    BOOL isVideo = [_attachment.mimeType rangeOfString:@"video"].location != NSNotFound;
    NSString *type = isVideo ? @"video" : @"photo";
    NSString *title = [@"Uploading " stringByAppendingString:type];
    [self showInProgressHUDWithMessage:title andAnimation:YES andDimmedBackground:YES withCancel:isVideo];
    [_attachment saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error) {
            [self showErrorThenRunBlock:error withMessage:[@"Could not upload the " stringByAppendingString:type] andBlock:nil];
        } else if (succeeded) {
            [self saveAchievement];
        }
    }                        progressBlock:^(int percentDone) {
        [self showText:[NSString stringWithFormat:@"%@ %d%%", title, percentDone]];
    }];
}

- (void)handleHudCanceled {
    [_attachment cancel];
    // Dismiss the HUD right away, don't wait for the network operation to cancel since this can take a while.
    [self hideHud];
}

- (void)updateAchievementFromInputs {
    if (self.commentsTextField.text.length) self.achievement.comment = self.commentsTextField.text;
    // Can be a PFFile (old style used for images) or an ExternalMediaFile object for larger things like videos.
    if ([_attachment isKindOfClass:[ExternalMediaFile class]]) {
        self.achievement.attachmentExternalStorageId = ((ExternalMediaFile *) _attachment).uniqueId;
    } else {
        self.achievement.attachment = (PFFile *) _attachment;
    }
    self.achievement.attachmentType = _attachment.mimeType;
    self.achievement.attachmentOrientation = _attachment.orientation;
    self.achievement.attachmentWidth = _attachment.width;
    self.achievement.attachmentHeight = _attachment.height;
    self.achievement.completionDate = self.completionDateTextField.date;
    if (_thumbnailImage) self.achievement.attachmentThumbnail = _thumbnailImage;
}

- (void)saveAchievement {

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
        NSNumberFormatter *doubleValueWithMaxTwoDecimalPlaces = [[NSNumberFormatter alloc] init];
        [doubleValueWithMaxTwoDecimalPlaces setNumberStyle:NSNumberFormatterDecimalStyle];
        [doubleValueWithMaxTwoDecimalPlaces setMaximumFractionDigits:1];

        if (self.heightTextField.text.floatValue) {
            heightMeasurement = [Measurement object];
            heightMeasurement.type = @"height";
            heightMeasurement.unit = self.heightUnitLabel.text;
            heightMeasurement.quantity = [doubleValueWithMaxTwoDecimalPlaces numberFromString:self.heightTextField.text];
            heightMeasurement.achievement = self.achievement;
            heightMeasurement.baby = self.achievement.baby;
        }

        if (self.weightTextField.text.floatValue) {
            weightMeasurement = [Measurement object];
            weightMeasurement.type = @"weight";
            weightMeasurement.unit = self.weightUnitLabel.text;
            weightMeasurement.quantity = [doubleValueWithMaxTwoDecimalPlaces numberFromString:self.weightTextField.text];
            weightMeasurement.achievement = self.achievement;
            weightMeasurement.baby = self.achievement.baby;
        }

        
        if (heightMeasurement && weightMeasurement) {
            self.achievement.customTitle = [NSString stringWithFormat:@"${He} reaches %@%@ and %@%@!",
                                            [doubleValueWithMaxTwoDecimalPlaces stringFromNumber:heightMeasurement.quantity] , heightMeasurement.unit,
                                            [doubleValueWithMaxTwoDecimalPlaces stringFromNumber:weightMeasurement.quantity], weightMeasurement.unit];
        } else {
            Measurement *measurement = heightMeasurement ? heightMeasurement : weightMeasurement;
            self.achievement.customTitle = [NSString stringWithFormat:@"${He} reaches %@%@!",
                                            [doubleValueWithMaxTwoDecimalPlaces stringFromNumber:measurement.quantity], measurement.unit];
        }
    } else if (self.isCustom) {
        NSAssert(self.customTitleTextField.text.length, @"Expected non empty custom title!");
        self.achievement.customTitle = self.customTitleTextField.text;
    }

    [self updateAchievementFromInputs];
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
            BOOL shareOnFb = self.achievement.sharedVia & SharingMediumFacebook;
            if (shareOnFb) {
                [PFFacebookUtils shareAchievement:self.achievement block:^(BOOL succeeded2, NSError *error2) {
                    if (error2) {
                        [[[UIAlertView alloc] initWithTitle:@"Could not share the milestone on Facebook" message:@"Make sure that you have authorized the DataParenting App at https://www.facebook.com/settings?tab=applications" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                    }
                }];
            }



            // Save the measurments (if any)
            if (heightMeasurement) {
                [UsageAnalytics trackMeasurement:heightMeasurement];
                [heightMeasurement saveEventually:^(BOOL succeeded2, NSError *error2) {
                    if (error) {
                        NSLog(@"Could not save the height measurement %@", error);
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:kDDNotificationMeasurementNotedAndSaved object:heightMeasurement];
                }];
            }
            if (weightMeasurement) {
                [UsageAnalytics trackMeasurement:weightMeasurement];
                [weightMeasurement saveEventually:^(BOOL succeeded2, NSError *error2) {
                    if (error2) {
                        NSLog(@"Could not save the weight measurement %@", error2);
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:kDDNotificationMeasurementNotedAndSaved object:weightMeasurement];
                }];
            }
            if (!self.isMeasurement) {
                [UsageAnalytics trackAchievementLogged:self.achievement sharedOnFacebook:shareOnFb];
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

- (ALAssetsLibrary *)assetLibrary {
    if (!_assetLibrary) {
        _assetLibrary = [[ALAssetsLibrary alloc] init];
    }
    return _assetLibrary;
}

- (void)updateDateFromFDTakeAsset:(NSURL *)assertUrl {
    NSAssert(assertUrl != nil, @"Expected non nil assertURL");
    [self.assetLibrary assetForURL:assertUrl resultBlock:^(ALAsset *asset) {
        NSDate *createDate = [asset valueForProperty:ALAssetPropertyDate];
        if (createDate) {
            if ([self.achievement.baby daysSinceBirthDate:createDate] < 0) {
                [[[UIAlertView alloc] initWithTitle:@"Hmmmm" message:
                                @"This photo or video seems to have been taken before baby was born - we'll use baby's birthdate instead, but feel free to correct it."
                                           delegate:nil cancelButtonTitle:@"Accept" otherButtonTitles:nil, nil] show];
                createDate = self.achievement.baby.birthDate;
            }

            if ([self.completionDateTextField.date compare:createDate]) {
                // Label to show the date has been changed., based on the photo date
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
    }                 failureBlock:^(NSError *error) {
        [UsageAnalytics trackError:error forOperationNamed:@"getDateForFDTakeAsset"];
    }];
}


#pragma mark - FDTakeDelegate

- (BOOL)takeController:(FDTakeController *)controller shouldProceedWithCurrentSettings:(UIImagePickerController *)picker {
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera && [picker.mediaTypes containsObject:(NSString *) kUTTypeMovie]) {
        // If they picked to record a video, then we must present them with the dialog as soon as possible, not waiting
        // until after they already record the video.
        self.takePhotoButton.enabled = NO; // prevent clicking more than once
        [FeatureManager ensureFeatureUnlocked:[[VideoFeature alloc] init] withBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) [controller presentImagePicker];
            self.takePhotoButton.enabled = YES;
        }];
        return NO;
    }
    return YES;
}

- (void)takeController:(FDTakeController *)controller gotVideo:(NSURL *)videoUrl withInfo:(NSDictionary *)info {
    self.takePhotoButton.enabled = NO; // Prevent another click while sorting out purchase stuff.
    [FeatureManager ensureFeatureUnlocked:[[VideoFeature alloc] init] withBlock:^(BOOL succeeded, NSError *error) {
        self.takePhotoButton.enabled = YES; // Restore
        if (succeeded) {
            NSURL *assetUrl = info[UIImagePickerControllerReferenceURL];
            BOOL fromLibrary = assetUrl != nil;

            if (!fromLibrary) {
                [self.assetLibrary writeVideoAtPathToSavedPhotosAlbum:videoUrl completionBlock:^(NSURL *savedAssertUrl, NSError *error2) {
                    if (error2) {
                        [UsageAnalytics trackError:error2 forOperationNamed:@"writeVideoAtPathToSavedPhotosAlbum"];
                    }
                }];
            }

            ExternalMediaFile *videoAttachment = [ExternalMediaFile videoFileFromUrl:videoUrl];
            if (videoAttachment) {
                UIImage *thumbnail = [videoAttachment.thumbnail imageScaledToFitSize:CGSizeMake(320.0, 320.0)];
                [self.takePhotoButton setImage:thumbnail forState:UIControlStateNormal];
                _thumbnailImage = [PFFile fileWithData:UIImageJPEGRepresentation(thumbnail, 0.5f) contentType:@"image/jpg"];
                _attachment = videoAttachment;
                if (fromLibrary) {
                    [self updateDateFromFDTakeAsset:assetUrl];
                }
            }
        }
    }];
}

- (void)takeController:(FDTakeController *)controller gotPhoto:(UIImage *)photo withInfo:(NSDictionary *)info {
    [self.takePhotoButton setImage:[photo imageScaledToFitSize:self.takePhotoButton.bounds.size] forState:UIControlStateNormal];
    NSURL *assetUrl = info[UIImagePickerControllerReferenceURL];
    if (assetUrl) {
        [self updateDateFromFDTakeAsset:assetUrl];
    } else {
        [self.assetLibrary writeImageToSavedPhotosAlbum:[photo CGImage] orientation:(ALAssetOrientation) [photo imageOrientation] completionBlock:^(NSURL *savedAssertUrl, NSError *error) {
            if (error) {
                [UsageAnalytics trackError:error forOperationNamed:@"writeImageToSavedPhotosAlbum"];
            }
        }];
    }

    _attachment = [PFFile imageFileFromImage:photo];
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

#pragma mark - DataParentingAdViewDelegate

- (void)displayAdView {
    self.adView.hidden = NO;
    //[self.view layoutIfNeeded]; - Apple recomends doing this, but it causes undetermined behavior with viewDidLayoutSubviews being called before the sizes change and not again after the animation.
    self.adViewHeightConstraint.constant = self.adView.currentAdImageHeight;
    [self.view setNeedsUpdateConstraints];
    [UIView animateWithDuration:0.5
                     animations:^{
                         [self.view layoutIfNeeded];
                     }];
}

- (void)hideAdView {
    self.adView.hidden = YES;
    self.adViewHeightConstraint.constant = 8;
    [self.view layoutIfNeeded];
}

@end
