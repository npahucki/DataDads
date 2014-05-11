//
//  BabyInfoPhotoControllerViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 4/5/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "BabyInfoPhotoControllerViewController.h"
#import "FDTakeControllerNoStatusBar.h"

@interface BabyInfoPhotoControllerViewController ()

@end

@implementation BabyInfoPhotoControllerViewController {
  FDTakeController* _takeController;
  NSData * _imageData;
}


- (void)viewDidLoad
{
  [super viewDidLoad];
  NSAssert(self.baby,@"Expected baby would be set before view loads");
  self.theLabel.font = [UIFont fontForAppWithType:Light andSize:31.0];
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

- (IBAction)didClickPhotoButton:(id)sender {
  _takeController = [[FDTakeControllerNoStatusBar alloc] init];
  _takeController.delegate = self;
  _takeController.viewControllerForPresentingImagePickerController = self;
  _takeController.allowsEditingPhoto = YES;
  _takeController.allowsEditingVideo = NO;
  [_takeController takePhotoOrChooseFromLibrary];
}

- (IBAction)didClickDoneButton:(id)sender {
  [self.view endEditing:YES];
  if(_imageData) {
    [self saveImageOrPhoto];
  } else {
    [self saveBabyWithAvatar:nil];
  }
}

-(void) saveImageOrPhoto {
  [self showInProgressHUDWithMessage:[NSString stringWithFormat:@"Uploading %@'s photo", self.baby.name] andAnimation:YES andDimmedBackground:YES];
  PFFile *file = [PFFile fileWithData:_imageData];
  [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
    if(error) {
      [self showErrorThenRunBlock:error withMessage:@"Could not upload your photo." andBlock:nil];
    } else {
      [self saveBabyWithAvatar:file];
    }
  } progressBlock:^(int percentDone) {
  }];
}

-(void) saveBabyWithAvatar:(PFFile*) attachment {
  self.baby.avatarImage = attachment;
  [self saveObject:self.baby withTitle:[NSString stringWithFormat:@"Saving %@'s info", self.baby.name] andFailureMessage:@"Could not save baby's information" andBlock:^(NSError *error) {
    if(!error) {
      Baby.currentBaby = self.baby;
      [self dismiss];
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
  _imageData = UIImageJPEGRepresentation(photo, 0.5f);
  [self.takePhotoButton.layer removeAllAnimations];
  self.takePhotoButton.contentMode = UIViewContentModeCenter;
  [self.takePhotoButton setImage:photo forState:UIControlStateNormal];
  self.takePhotoButton.alpha = 1.0;
}




@end
