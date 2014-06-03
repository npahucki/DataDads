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

@interface NoteMilestoneViewController ()

@end

@implementation NoteMilestoneViewController {
  FDTakeController* _takeController;
  NSData * _imageOrVideo;
  NSString * _imageOrVideoType;
  ALAssetsLibrary * _assetLibrary;
  BOOL _startedAnimation;
  NSString * _shortDescription;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  _imageOrVideo = nil;
  _imageOrVideoType = nil;
  
  NSAssert(self.achievement.baby, @"baby must be set on acheivement before view loads");

  self.commentsTextField.delegate = self;
  self.customTitleTextField.delegate = self;
  
  self.titleTextView.delegate = self;
  NSDictionary *linkAttributes = @{NSForegroundColorAttributeName: [UIColor appSelectedColor],
                                   NSUnderlineColorAttributeName: [UIColor appSelectedColor],
                                   NSUnderlineStyleAttributeName: @(NSUnderlinePatternSolid)};
  self.titleTextView.linkTextAttributes = linkAttributes; // customizes the appearance of links
  self.titleTextView.hidden = self.isCustom;
  self.customTitleTextField.hidden = !self.isCustom;
  self.doneButton.enabled = !self.isCustom;
  // Needed to dimiss the keyboard once a user clicks outside the text boxes
  UITapGestureRecognizer *viewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
  [self.view addGestureRecognizer:viewTap];
}

-(void)handleSingleTap:(UITapGestureRecognizer *)sender {
  [self.view endEditing:NO];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
  [textField resignFirstResponder];
  return YES;
}

-(BOOL) isCustom {
  return self.achievement.standardMilestone == nil;
}

-(void) viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
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
- (IBAction)didEndEditingCustomTitle:(id)sender {
  self.doneButton.enabled = self.customTitleTextField.text.length > 1;
}

- (IBAction)didClickTakePicture:(id)sender {
  [self.view endEditing:YES];
  _takeController = [[FDTakeControllerNoStatusBar alloc] init];
  _takeController.delegate = self;
  _takeController.viewControllerForPresentingImagePickerController = self;
  _takeController.allowsEditingPhoto = YES;
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
  
  // Bit of a hacky work around to the fact that CLoudCode beforeSave trigger reloads the object after a save
  // buts does not load the pointers, so the achievement object has the Baby and StandardMilestone fields set to
  // hollow pointers (do data but the objectId). We would normally need to make two more network calls to get
  // these two objects back (needed for code that runs in the notification handlers). However, we assume
  // that the CloudCode trigger scripts are NOT changing the baby or StandardMilestone, meaning that we can save the
  // values here, and restore them later (after asserting that the objectIds are the same of course!).
  StandardMilestone* originalMilestone = self.achievement.standardMilestone; // this will be nil for custom milestones.
  Baby * originalBaby = self.achievement.baby;
  
  
  if(self.commentsTextField.text.length) self.achievement.comment = self.commentsTextField.text;
  if(self.customTitleTextField.text.length) self.achievement.customTitle = self.customTitleTextField.text;
  self.achievement.attachment = attachment;
  self.achievement.attachmentType = type;
  self.achievement.completionDate =  ((UIDatePicker*)self.completionDateTextField.inputView).date;
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
      
      [[NSNotificationCenter defaultCenter] postNotificationName:kDDNotificationMilestoneNotedAndSaved object:self userInfo:@{@"" : self.achievement}];
      [self dismissViewControllerAnimated:YES completion:nil];
    }
  }];
}

#pragma mark - FDTakeDelegate

- (void)takeController:(FDTakeController *)controller didCancelAfterAttempting:(BOOL)madeAttempt
{
  // TODO: Log this for user interaction tracking
}

- (void)takeController:(FDTakeController *)controller gotPhoto:(UIImage *)photo withInfo:(NSDictionary *)info
{
  
  if(!_assetLibrary) {
    _assetLibrary = [[ALAssetsLibrary alloc] init];
  }
  
  // Attempt to use date from the photo taken, instead of the current date
  NSURL *assetURL = [info objectForKey:UIImagePickerControllerReferenceURL];
  if(assetURL) {
    [_assetLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset) {
      NSDate * createDate = [asset valueForProperty:ALAssetPropertyDate];
      if(createDate) {

        if([self.achievement.baby daysSinceBirthDate:createDate] < 0) {
          [[[UIAlertView alloc] initWithTitle:@"Hmmmm" message:@"This photo seems to have been taken before baby was born - we'll use baby's birthdate instead, but feel free to correct it." delegate:nil cancelButtonTitle:@"Accept" otherButtonTitles:nil, nil] show];
          createDate = self.achievement.baby.birthDate;
        }
        
        UIDatePicker * picker = (UIDatePicker*)self.completionDateTextField.inputView;
        if([picker.date compare:createDate]) {
          picker.date = createDate;
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
            self.completionDateTextField.text = newDateLabel.text;
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
  self.takePhotoButton.contentMode = UIViewContentModeCenter;
  [self.takePhotoButton setImage:photo forState:UIControlStateNormal];
  self.takePhotoButton.alpha = 1.0;

//  // Hide the Label
//  self.takePhotoLabel.text = @"Nice Shot!";
//  [UILabel animateWithDuration:1.0 delay:2.0 options:UIViewAnimationOptionCurveEaseOut animations:^{ self.takePhotoLabel.alpha = 0.0; } completion:nil];
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
