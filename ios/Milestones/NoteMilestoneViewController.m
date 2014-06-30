//
//  MilestoneNotedViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/21/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "NoteMilestoneViewController.h"
#import "MilestoneAchievement.h"
#import "WebViewerViewController.h"
#import "FDTakeControllerNoStatusBar.h"
#import "UnitHelper.h"

@interface NoteMilestoneViewController ()

@end

@implementation NoteMilestoneViewController {
  FDTakeController* _takeController;
  NSData * _imageOrVideo;
  NSString * _imageOrVideoType;
  ALAssetsLibrary * _assetLibrary;
  BOOL _startedAnimation;
  NSString * _shortDescription;
  BOOL _isKeyboardShowing;
  CGRect _originalFrame;
  UITextField * _activeField;
  
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  _imageOrVideo = nil;
  _imageOrVideoType = nil;
  
  NSAssert(self.achievement.baby, @"baby must be set on acheivement before view loads");
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWasShown:)
                                               name:UIKeyboardWillShowNotification object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillBeHidden:)
                                               name:UIKeyboardWillHideNotification object:nil];
  
  self.completionDateTextField.inputAccessoryView = nil;

  NSDictionary *linkAttributes = @{NSForegroundColorAttributeName: [UIColor appSelectedColor],
                                   NSUnderlineColorAttributeName: [UIColor appSelectedColor],
                                   NSUnderlineStyleAttributeName: @(NSUnderlinePatternSolid)};

  self.heightUnitLabel.text = [UnitHelper unitForHeight];
  self.weightUnitLabel.text = [UnitHelper unitForWeight];
  self.titleTextView.linkTextAttributes = linkAttributes; // customizes the appearance of links
  self.titleTextView.hidden = self.isCustom;
  self.scrollView.hidden = !self.isCustom;
  self.segmentControl.hidden = !self.isCustom;
  self.doneButton.enabled = !self.isCustom;
  // Needed to dimiss the keyboard once a user clicks outside the text boxes
  UITapGestureRecognizer *viewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
  [self.view addGestureRecognizer:viewTap];
  
  self.takePhotoButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
  self.takePhotoButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
  self.takePhotoButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
  
  self.fbSwitch = [[SevenSwitch alloc] initWithFrame:CGRectMake(10, 10, 50, 30)];
  [self.view addSubview:_fbSwitch];
  [_fbSwitch addTarget:self action:@selector(didChangeFacebookSwitch:) forControlEvents:UIControlEventValueChanged];
  _fbSwitch.thumbImage = [UIImage imageNamed:@"facebookSwitch"];
  _fbSwitch.thumbTintColor = UIColorFromRGB(0x3B5999); // Facebook color
  _fbSwitch.isRounded = NO;
  _fbSwitch.inactiveColor = [UIColor appGreyTextColor];
  _fbSwitch.onTintColor = [UIColor appNormalColor];
  _fbSwitch.activeColor = _fbSwitch.onTintColor;
  _fbSwitch.borderColor = [UIColor blackColor];
  //_fbSwitch.shadowColor = [UIColor blackColor];
  [_fbSwitch setOn:ParentUser.currentUser.autoPublishToFacebook && [PFFacebookUtils userHasAuthorizedPublishPermissions:ParentUser.currentUser] animated:NO];
}

-(void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
  NSDictionary* info = [aNotification userInfo];
  CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
  
  if(!_isKeyboardShowing) {
    _isKeyboardShowing = YES;
    _originalFrame = self.view.frame;
  }
  // NOTE: we use this instead of scroll view because working woth autolayout and the scroll view is almost impossible
  // becasue we resize some content based on the size of the screen, and in scrollview, this means that the content is
  // as large as it can be, but is scrollable which is NOT what we want!

  if(_activeField.frame.size.height + _activeField.frame.origin.y > self.view.frame.size.height - kbSize.height) {
    [UIView
     animateWithDuration:0.5
     animations:^{
       self.view.frame = CGRectMake(0,_originalFrame.origin.y - kbSize.height + self.adBanner.frame.size.height , _originalFrame.size.width, _originalFrame.size.height);
     }];
  }
}

  
// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
  _isKeyboardShowing = NO;
  [UIView
   animateWithDuration:0.5
   animations:^{
     self.view.frame = _originalFrame;
   }];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
  _activeField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
  _activeField = nil;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
  NSUInteger newLength = [textField.text length] + [string length] - range.length;
  if(textField == self.weightTextField) {
    self.doneButton.enabled = string.floatValue > 0 && self.heightTextField.text.floatValue > 0;
    return (newLength < 5);
  } else if(textField == self.heightTextField) {
    self.doneButton.enabled = string.floatValue > 0 && self.weightTextField.text.floatValue > 0;
    return (newLength < 5);
  } else if(textField == self.customTitleTextField) {
    self.doneButton.enabled = newLength > 0;
  }

  return YES;
}

-(void)handleSingleTap:(UITapGestureRecognizer *)sender {
  [self.view endEditing:NO];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
  [textField resignFirstResponder];
  return YES;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  CGFloat x = scrollView.contentOffset.x;
  CGFloat w = scrollView.bounds.size.width;
  self.segmentControl.selectedSegmentIndex = x/w;
}
- (IBAction)userDidPage:(id)sender {
  NSInteger p = self.segmentControl.selectedSegmentIndex;
  CGFloat w = self.scrollView.bounds.size.width;
  [self.scrollView setContentOffset:CGPointMake(p*w,0) animated:YES];
  if(self.isMeasurement) {
      self.doneButton.enabled = self.weightTextField.text.floatValue > 0 && self.weightTextField.text.floatValue > 0;
  } else {
    self.doneButton.enabled = self.customTitleTextField.text.length > 0;
  }
}

-(void) viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  self.fbSwitch.frame = self.placeHolderSwitch.frame;
  [self.takePhotoButton.layer setCornerRadius:self.takePhotoButton.frame.size.width/2];
  self.takePhotoButton.layer.masksToBounds = YES;
  self.takePhotoButton.layer.borderWidth = 1;

  // NOTE: For some odd reson, this will not work is done in viewDidLoad!
  if(self.achievement.standardMilestone) self.titleTextView.attributedText = [self createTitleTextFromMilestone];


  if(!_startedAnimation) {
    
    [UIButton animateWithDuration:1.0 delay:0.0 options:
     UIViewAnimationOptionAllowUserInteraction |UIViewAnimationOptionBeginFromCurrentState |UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat
                       animations:^{
                         self.takePhotoButton.alpha = .75;
                       } completion:nil];
    _startedAnimation = YES;
  }
}


- (IBAction)didClickTakePicture:(id)sender {
  [self.view endEditing:YES];
  _takeController = [[FDTakeControllerNoStatusBar alloc] init];
  _takeController.delegate = self;
  _takeController.viewControllerForPresentingImagePickerController = self;
  _takeController.allowsEditingPhoto = NO; // NOTE: Allowing photo editing causes a problem with landscape pictures!
  _takeController.allowsEditingVideo = NO;
  [_takeController takePhotoOrChooseFromLibrary];
}

- (IBAction)didClickDoneButton:(id)sender {
  [self.view endEditing:YES];
  
  if([Reachability showAlertIfParseNotReachable]) return;

  if(_imageOrVideo) {
    [self saveImageOrPhoto];
  } else {
    [self saveAchievementWithAttachment:nil andType:nil];
  }
}

- (IBAction)didClickCancelButton:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didChangeFacebookSwitch:(id)sender {
  if(self.fbSwitch.on) {
      [PFFacebookUtils ensureHasPublishPermissions:ParentUser.currentUser block:^(BOOL succeeded, NSError *error) {
        if(error) {
          [PFFacebookUtils showAlertIfFacebookDisplayableError:error];
          [self.fbSwitch setOn:NO animated:YES];
        } else if(!succeeded) {
          // User did not link or did not give permissions.
          [self.fbSwitch setOn:NO animated:YES];
        }
      }];
  }

  // Remember for future uses.
  if(ParentUser.currentUser.autoPublishToFacebook != self.fbSwitch.on) {
    ParentUser.currentUser.autoPublishToFacebook = self.fbSwitch.on;
    [ParentUser.currentUser saveEventually];
  }
  

}

-(void) saveImageOrPhoto {
  [self showInProgressHUDWithMessage:@"Uploading Photo" andAnimation:YES andDimmedBackground:YES];
  PFFile *file = [PFFile fileWithData:_imageOrVideo];
  [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
    if(error) {
      [self showErrorThenRunBlock:error withMessage:@"Could not upload the photo." andBlock:nil];
    } else {
      [self saveAchievementWithAttachment:file andType:_imageOrVideoType];
    }
  }];
  }

-(void) saveAchievementWithAttachment:(PFFile*) attachment andType:(NSString*) type {
  
  // Bit of a hacky work around to the fact that CloudCode beforeSave trigger reloads the object after a save
  // buts does not load the pointers, so the achievement object has the Baby and StandardMilestone fields set to
  // hollow pointers (do data but the objectId). We would normally need to make two more network calls to get
  // these two objects back (needed for code that runs in the notification handlers). However, we assume
  // that the CloudCode trigger scripts are NOT changing the baby or StandardMilestone, meaning that we can save the
  // values here, and restore them later (after asserting that the objectIds are the same of course!).
  StandardMilestone* originalMilestone = self.achievement.standardMilestone; // this will be nil for custom milestones.
  Baby * originalBaby = self.achievement.baby;
  
  Measurement * heightMeasurement;
  Measurement * weightMeasurement;
  if(self.isMeasurement) {
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

    self.achievement.customTitle = [NSString stringWithFormat:@"${He} reaches %@%@ and %@%@!",heightMeasurement.quantity, heightMeasurement.unit, weightMeasurement.quantity, weightMeasurement.unit];
  } else if(self.isCustom) {
      NSAssert(self.customTitleTextField.text.length, @"Expected non empty custom title!");
      self.achievement.customTitle = self.customTitleTextField.text;
  }
  
  if(self.commentsTextField.text.length) self.achievement.comment = self.commentsTextField.text;
  self.achievement.attachment = attachment;
  self.achievement.attachmentType = type;
  self.achievement.completionDate =  self.completionDateTextField.date;
  
  [self saveObject:self.achievement withTitle:@"Noting Milestone" andFailureMessage:@"Could not note milestone." andBlock:^(NSError * error) {
    if(!error) {
      // SEE NOTE ABOVE
      if(!self.achievement.baby.isDataAvailable) {
        NSAssert([self.achievement.baby.objectId isEqualToString:originalBaby.objectId],@"The server unexpectedly changed the Baby in the achievement!");
        self.achievement.baby = originalBaby; // avoid network call
      }
      if(originalMilestone && !self.achievement.standardMilestone.isDataAvailable) {
        NSAssert([self.achievement.standardMilestone.objectId isEqualToString:originalMilestone.objectId],@"The server unexpectedly changed the Milestone in the achievement!");
        self.achievement.standardMilestone = originalMilestone; // avoid network call
      }
      
      // Notify locally
      [[NSNotificationCenter defaultCenter] postNotificationName:kDDNotificationMilestoneNotedAndSaved object:self.achievement];
      
      // Publish the achievement to facebook
      if(self.fbSwitch.on) {
        [PFFacebookUtils shareAchievement:self.achievement block:^(BOOL succeeded, NSError *error) {
          if(error) {
            [[[UIAlertView alloc] initWithTitle:@"Could not share the milestone on Facebook" message:@"Make sure that you have authorized the DataParenting App at https://www.facebook.com/settings?tab=applications" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
          }
        }];
      }
      

      
      // Save the measurments (if any)
      if(heightMeasurement) [heightMeasurement saveEventually:^(BOOL succeeded, NSError *error) {
        if(error) {
          NSLog(@"Could not save the height measurement %@", error);
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kDDNotificationMeasurementNotedAndSaved object:heightMeasurement];
      }];
      if(weightMeasurement) [weightMeasurement saveEventually:^(BOOL succeeded, NSError *error) {
        if(error) {
          NSLog(@"Could not save the weight measurement %@", error);
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kDDNotificationMeasurementNotedAndSaved object:weightMeasurement];
      }];

      if(self.isMeasurement) {
        if(heightMeasurement) [UsageAnalytics trackMeasurement:heightMeasurement];
        if(weightMeasurement) [UsageAnalytics trackMeasurement:weightMeasurement];
      } else {
        [UsageAnalytics trackAchievementLogged:self.achievement sharedOnFacebook:self.fbSwitch.on];
      }
      [self dismissViewControllerAnimated:YES completion:nil];
    }
  }];
}

-(BOOL) isMeasurement {
  return self.isCustom && self.segmentControl.selectedSegmentIndex == 1;
}

-(BOOL) isCustom {
  return self.achievement.standardMilestone == nil;
}

#pragma mark - FDTakeDelegate

- (void)takeController:(FDTakeController *)controller didCancelAfterAttempting:(BOOL)madeAttempt
{
  // TODO: Log this for user interaction tracking
}

- (void)takeController:(FDTakeController *)controller gotPhoto:(UIImage *)photo withInfo:(NSDictionary *)info
{
  
//  if([info objectForKey:@"UIImagePickerControllerOriginalImage"]) {
//    photo = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
//    CGRect crop = [[info valueForKey:@"UIImagePickerControllerCropRect"] CGRectValue];
//    photo = [photo imageCroppedToRect:crop];
//  }
  
  // Attempt to use date from the photo taken, instead of the current date
  NSURL *assetURL = [info objectForKey:UIImagePickerControllerReferenceURL];
  if(assetURL) {
    if(!_assetLibrary) {
      _assetLibrary = [[ALAssetsLibrary alloc] init];
    }
    [_assetLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset) {
      NSDate * createDate = [asset valueForProperty:ALAssetPropertyDate];
      if(createDate) {

        if([self.achievement.baby daysSinceBirthDate:createDate] < 0) {
          [[[UIAlertView alloc] initWithTitle:@"Hmmmm" message:@"This photo seems to have been taken before baby was born - we'll use baby's birthdate instead, but feel free to correct it." delegate:nil cancelButtonTitle:@"Accept" otherButtonTitles:nil, nil] show];
          createDate = self.achievement.baby.birthDate;
        }
        
        
        if([self.completionDateTextField.date compare:createDate]) {
          // Label to show the date has been changed., based on the phtoto date
          UILabel * newDateLabel = [[UILabel alloc] init];
          newDateLabel.textColor =  self.completionDateTextField.textColor;
          newDateLabel.font = self.completionDateTextField.font;
          newDateLabel.text = [self.completionDateTextField.dateFormatter stringFromDate:createDate];
          [newDateLabel sizeToFit];
          newDateLabel.center = self.takePhotoButton.center;
          [self.view addSubview:newDateLabel];
          
          newDateLabel.transform = CGAffineTransformScale(newDateLabel.transform, 2.5, 2.5);
          [UILabel animateWithDuration:0.5 animations:^{
            newDateLabel.transform = CGAffineTransformScale(newDateLabel.transform, .5, .5);
            newDateLabel.frame = CGRectMake(self.completionDateTextField.frame.origin.x + 5, self.completionDateTextField.frame.origin.y + 5, newDateLabel.frame.size.width, newDateLabel.frame.size.height);
          } completion:^(BOOL finished) {
            [newDateLabel removeFromSuperview];
            self.completionDateTextField.date = createDate;
          }];
        }
      }
    } failureBlock:^(NSError *error) {
      // NSLog(@"Failed to get asset from library");
    }];
  }


  // TODO: Support video too!
  _imageOrVideo = UIImageJPEGRepresentation(photo, 0.5f);
  _imageOrVideoType = @"image/jpg";
  [self.takePhotoButton.layer removeAllAnimations];
  self.takePhotoButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
  [self.takePhotoButton setImage:photo forState:UIControlStateNormal];
  self.takePhotoButton.alpha = 1.0;
}

-(NSAttributedString *) createTitleTextFromMilestone {
  StandardMilestone * m = self.achievement.standardMilestone;
  NSMutableAttributedString *attrText = [[NSMutableAttributedString alloc] init];
  NSAttributedString * lf = [[NSAttributedString alloc] initWithString:@"\n"];
  NSDictionary *dataLabelTextAttributes = @{NSFontAttributeName: [UIFont fontForAppWithType:Bold andSize:15.0], NSForegroundColorAttributeName: [UIColor blackColor]};
  NSDictionary *dataValueTextAttributes = @{NSFontAttributeName: [UIFont fontForAppWithType:Medium andSize:15.0], NSForegroundColorAttributeName: [UIColor blackColor]};
  

  
  NSAttributedString * titleString = [[NSAttributedString alloc] initWithString:[m titleForBaby:self.achievement.baby] attributes:@{NSFontAttributeName: [UIFont fontForAppWithType:Bold andSize:15.0], NSForegroundColorAttributeName: [UIColor appNormalColor]}];
  [attrText appendAttributedString:titleString];
  [attrText appendAttributedString:lf];

  NSAttributedString * enteredDateLabel = [[NSAttributedString alloc] initWithString:@"Entered By: " attributes:dataLabelTextAttributes];
  NSAttributedString * enteredDateValue = [[NSAttributedString alloc] initWithString:@"DataParenting Staff" attributes:dataValueTextAttributes];
  [attrText appendAttributedString:lf];
  [attrText appendAttributedString:enteredDateLabel];
  [attrText appendAttributedString:enteredDateValue];
  [attrText appendAttributedString:lf];

  NSAttributedString * rangeLabel = [[NSAttributedString alloc] initWithString:@"Completion Range: " attributes:dataLabelTextAttributes];
  NSAttributedString * rangeValue = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ to %@ days",m.rangeLow,m.rangeHigh] attributes:dataValueTextAttributes];
  [attrText appendAttributedString:rangeLabel];
  [attrText appendAttributedString:rangeValue];
  [attrText appendAttributedString:lf];

  if(m.url) {
    [attrText appendAttributedString:lf];
    NSMutableAttributedString *readMoreLabel = [[NSMutableAttributedString alloc] initWithString:@"Read More..." attributes:@{
                                                                                                                                                   NSFontAttributeName: [UIFont fontForAppWithType:BoldItalic andSize:17.0],
                                                                                                                                                   NSForegroundColorAttributeName: [UIColor appSelectedColor]
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
