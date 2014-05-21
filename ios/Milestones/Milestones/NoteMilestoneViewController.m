//
//  MilestoneNotedViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/21/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "NoteMilestoneViewController.h"
#import "MilestoneAchievement.h"
#import "FDTakeControllerNoStatusBar.h"

@interface NoteMilestoneViewController ()

@end

@implementation NoteMilestoneViewController {
  FDTakeController* _takeController;
  NSData * _imageOrVideo;
  NSString * _imageOrVideoType;
  ALAssetsLibrary * _assetLibrary;
  BOOL _startedAnimation;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  _imageOrVideo = nil;
  _imageOrVideoType = nil;
  
  NSAssert(self.achievement.baby, @"baby must be set on acheivement before view loads");

  self.commentsTextField.delegate = self;
  self.customTitleTextField.delegate = self;
  
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
  
  if(self.commentsTextField.text.length) self.achievement.comment = self.commentsTextField.text;
  if(self.customTitleTextField.text.length) self.achievement.customTitle = self.customTitleTextField.text;
  self.achievement.attachment = attachment;
  self.achievement.attachmentType = type;
  self.achievement.completionDate =  ((UIDatePicker*)self.completionDateTextField.inputView).date;
  [self saveObject:self.achievement withTitle:@"Noting Milestone" andFailureMessage:@"Could not note milestone." andBlock:^(NSError * error) {
    if(!error) {
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

  NSDictionary *dataLabelTextAttributes = @{NSFontAttributeName: [UIFont fontForAppWithType:Bold andSize:15.0], NSForegroundColorAttributeName: [UIColor blackColor]};
  NSDictionary *dataValueTextAttributes = @{NSFontAttributeName: [UIFont fontForAppWithType:Medium andSize:15.0], NSForegroundColorAttributeName: [UIColor blackColor]};
  
  NSAttributedString * titleString = [[NSAttributedString alloc] initWithString:m.title attributes:@{NSFontAttributeName: [UIFont fontForAppWithType:Bold andSize:15.0], NSForegroundColorAttributeName: [UIColor appNormalColor]}];

  NSAttributedString * descriptionString = [[NSAttributedString alloc] initWithString:m.shortDescription attributes:@{NSFontAttributeName: [UIFont fontForAppWithType:Medium andSize:14.0], NSForegroundColorAttributeName: [UIColor appGreyTextColor]}];

  NSAttributedString * enteredDateLabel = [[NSAttributedString alloc] initWithString:@"Entered By: " attributes:dataLabelTextAttributes];
  NSAttributedString * enteredDateValue = [[NSAttributedString alloc] initWithString:@"DataParenting Staff" attributes:dataValueTextAttributes];
  NSAttributedString * rangeLabel = [[NSAttributedString alloc] initWithString:@"Completion Range: " attributes:dataLabelTextAttributes];
  NSAttributedString * rangeValue = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ to %@ days",m.rangeLow,m.rangeHigh] attributes:dataValueTextAttributes];
  NSAttributedString * lf = [[NSAttributedString alloc] initWithString:@"\n"];


  NSMutableAttributedString *attrText = [[NSMutableAttributedString alloc] init];
  [attrText appendAttributedString:titleString];
  [attrText appendAttributedString:lf];
  [attrText appendAttributedString:descriptionString];
  [attrText appendAttributedString:lf];
  [attrText appendAttributedString:lf];
  [attrText appendAttributedString:enteredDateLabel];
  [attrText appendAttributedString:enteredDateValue];
  [attrText appendAttributedString:lf];
  [attrText appendAttributedString:rangeLabel];
  [attrText appendAttributedString:rangeValue];

  return attrText;
}

@end
