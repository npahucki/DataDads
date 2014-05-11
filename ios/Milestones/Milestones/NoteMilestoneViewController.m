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
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  _imageOrVideo = nil;
  _imageOrVideoType = nil;
  
  NSAssert(self.achievement.standardMilestone || self.achievement.customTitle,@"one of standardMilestone or customTitle must be set");
  NSAssert(self.achievement.baby, @"baby must be set on acheivement before view loads");
  
  self.takePhotoLabel.font = [UIFont fontForAppWithType:Light andSize:31.0];
  [UIButton animateWithDuration:1.0 delay:0.0 options:
   UIViewAnimationOptionAllowUserInteraction |UIViewAnimationOptionBeginFromCurrentState |UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat
                     animations:^{
                       self.takePhotoButton.alpha = .75;
                     } completion:nil];
}

-(void) viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  [self.takePhotoButton.layer setCornerRadius:self.takePhotoButton.frame.size.width/2];
  self.takePhotoButton.layer.masksToBounds = YES;
  self.takePhotoButton.layer.borderWidth = 1;
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
  self.achievement.attachment = attachment;
  self.achievement.attachmentType = type;
  self.achievement.completionDate =  ((UIDatePicker*)self.completionDateTextField.inputView).date;
  [self saveObject:self.achievement withTitle:@"Noting Milestone" andFailureMessage:@"Could not note milestone." andBlock:^(NSError * error) {
    if(!error) {
      [[NSNotificationCenter defaultCenter] postNotificationName:kDDNotificationMilestoneNotedAndSaved object:self userInfo:@{@"" : self.achievement}];
      [self dismiss];
    }
  }];
  
  // TODO: Show Ranking
  
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
  [[UIApplication sharedApplication] setStatusBarHidden:YES];
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

  // Hide the Label
  self.takePhotoLabel.text = @"Nice Shot!";
  [UILabel animateWithDuration:1.0 delay:2.0 options:UIViewAnimationOptionCurveEaseOut animations:^{ self.takePhotoLabel.alpha = 0.0; } completion:nil];
}



@end
