//
//  BabyInfoPhotoControllerViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 4/5/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "BabyInfoPhotoControllerViewController.h"

@interface BabyInfoPhotoControllerViewController ()

@end

@implementation BabyInfoPhotoControllerViewController


- (void)viewDidLoad
{
  [super viewDidLoad];
  NSAssert(self.baby,@"Expected baby would be set before view loads");
  self.theLabel.font = [UIFont fontWithName:@"GothamRounded-Light" size:31.0];
  _shouldAnimateCamera = YES;
  [self animateCameraImage];
}

-(void) viewWillAppear:(BOOL)animated {
  // This is needed to hack around the fact that the image picker turns on the status bar
  [[UIApplication sharedApplication] setStatusBarHidden:YES];
  [super viewWillAppear:animated];
}

-(void) viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  [self.takePhotoButton.layer setCornerRadius:self.takePhotoButton.frame.size.width/2];
  self.takePhotoButton.layer.masksToBounds = YES;
  self.takePhotoButton.layer.borderWidth = 1;
  
}

-(void) animateCameraImage {
  [UIButton animateWithDuration:1.0 delay:0.0 options:
   UIViewAnimationOptionAllowUserInteraction| UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAutoreverse
                     animations:^{
                       self.takePhotoButton.alpha = .75;
                     } completion:^(BOOL finished) {
                       if(_shouldAnimateCamera) {
                         [self animateCameraImage];
                       } else {
                         // reset
                         self.takePhotoButton.alpha = 1.0;
                       }
                     }];
  
}

- (IBAction)didClickPhotoButton:(id)sender {
  _takeController = [[FDTakeController alloc] init];
  _takeController.delegate = self;
  _takeController.viewControllerForPresentingImagePickerController = self;
  _takeController.allowsEditingPhoto = YES;
  _takeController.allowsEditingVideo = NO;
  [_takeController takePhotoOrChooseFromLibrary];
}

- (IBAction)didClickDoneButton:(id)sender {
  [self.view endEditing:YES];
  [self showHUD:YES];
  if(_imageData) {
    [self saveImageOrPhoto];
  } else {
    [self saveBabyWithAvatar:nil];
  }
}

-(void) saveImageOrPhoto {
  self.hud.mode = MBProgressHUDModeCustomView;
  self.hud.customView =  [[UIImageView alloc] initWithImage:[UIImage animatedImageNamed:@"progress-" duration:1.0f]];
  self.hud.labelText = [NSString stringWithFormat:@"Uploading %@'s photo", self.baby.name];
  PFFile *file = [PFFile fileWithData:_imageData];
  [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
    if(error) {
      [self showSaveError:error withMessage:@"Could not upload your photo."];
    } else {
      [self saveBabyWithAvatar:file];
    }
  } progressBlock:^(int percentDone) {
  }];
}

-(void) saveBabyWithAvatar:(PFFile*) attachment {
  self.hud.mode = MBProgressHUDModeCustomView;
  self.hud.customView =  [[UIImageView alloc] initWithImage:[UIImage animatedImageNamed:@"progress-" duration:1.0f]];
  self.hud.labelText = [NSString stringWithFormat:@"Saving %@'s info", self.baby.name];
  self.baby.avatarImage = attachment;
  [self.baby saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
    if(succeeded) {
      Baby.currentBaby = self.baby;
      [self showSaveSuccessAndDismissDialog];
    } else {
      [self showSaveError:error withMessage:@"Could not save Baby information."];
    }
  }];
}

// Override because we don't want to return to root view in controller but we want to dismiss.
-(void) dismiss {
  [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - FDTakeDelegate

- (void)takeController:(FDTakeController *)controller didCancelAfterAttempting:(BOOL)madeAttempt
{
  // TODO: Log this for user interaction tracking
}

- (void)takeController:(FDTakeController *)controller gotPhoto:(UIImage *)photo withInfo:(NSDictionary *)info
{
  _shouldAnimateCamera = NO; // stop the animation cycle
  _imageData = UIImageJPEGRepresentation(photo, 0.5f);
  [self.takePhotoButton.imageView.layer removeAllAnimations];
  [self.takePhotoButton.layer removeAllAnimations];
  self.takePhotoButton.contentMode = UIViewContentModeCenter;
  [self.takePhotoButton setImage:photo forState:UIControlStateNormal];
}




@end
