//
//  BabyInfoPhotoControllerViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 4/5/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "BabyInfoPhotoViewController.h"
#import "FDTakeControllerNoStatusBar.h"

@interface BabyInfoPhotoViewController ()

@end

@implementation BabyInfoPhotoViewController {
  FDTakeController* _takeController;
  NSData * _imageData;
  BOOL _startedAnimation;
}


- (void)viewDidLoad
{
  [super viewDidLoad];
  NSAssert(self.baby,@"Expected baby would be set before view loads");

  self.takePhotoButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
  self.theLabel.font = [UIFont fontForAppWithType:Light andSize:31.0];
  if(self.baby.avatarImage) {
    [self.baby.avatarImage getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
      if(!error) {
        [self.takePhotoButton setImage:[UIImage imageWithData:data] forState:UIControlStateNormal];
      } else {
        NSLog(@"Failed to load image %@", error);
      }
    }];
  }
}

-(void) viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  [self.takePhotoButton.layer setCornerRadius:self.takePhotoButton.frame.size.width/2];
  self.takePhotoButton.layer.masksToBounds = YES;
  self.takePhotoButton.layer.borderWidth = 1;
  
  if(!_startedAnimation) {
    [UIButton animateWithDuration:1.0 delay:0.0 options:
     UIViewAnimationOptionAllowUserInteraction |UIViewAnimationOptionBeginFromCurrentState |UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat
                       animations:^{
                         self.takePhotoButton.alpha = .75;
                       } completion:nil];
    _startedAnimation = YES;
  }
}

- (IBAction)didClickPhotoButton:(id)sender {
  _takeController = [[FDTakeControllerNoStatusBar alloc] init];
  _takeController.delegate = self;
  _takeController.viewControllerForPresentingImagePickerController = self;
  _takeController.allowsEditingPhoto = YES;
  _takeController.allowsEditingVideo = NO;
  [_takeController takePhotoOrChooseFromLibrary];
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
  [self.takePhotoButton setImage:photo forState:UIControlStateNormal];
  self.takePhotoButton.alpha = 1.0;
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if(_imageData) { // Don't save blank images
    PFFile *file = [PFFile fileWithData:_imageData];
    self.baby.avatarImage = file;
  }
  ((UIViewController<ViewControllerWithBaby>*)segue.destinationViewController).baby = self.baby;
}


@end
