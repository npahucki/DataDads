//
//  MilestoneNotedViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/21/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "NoteMilestoneViewController.h"
#import "StandardMilestoneAchievement.h"

@interface NoteMilestoneViewController ()

@end

@implementation NoteMilestoneViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  NSAssert(self.milestone,@"milestone must be set before view loads");
  NSAssert(self.baby, @"baby must be set before view loads");
  
  UIToolbar* datePickerToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
  datePickerToolbar.items = @[
                              [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                              [[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneWithDatePicker)]
                              ];
  [datePickerToolbar sizeToFit];
  
  UIDatePicker *datePicker = [[UIDatePicker alloc]init];
  datePicker.datePickerMode = UIDatePickerModeDate;
  datePicker.date = [NSDate date];
  datePicker.maximumDate = datePicker.date;
  [datePicker addTarget:self action:@selector(updateCompletionDateTextField:) forControlEvents:UIControlEventValueChanged];
  self.completionDateTextField.inputView = datePicker;
  self.completionDateTextField.inputAccessoryView = datePickerToolbar;
  [self updateCompletionDateTextField:datePicker]; // Make it have today's date by default
}

- (IBAction)didClickCancelButton:(id)sender {
  self.milestone = nil;
  self.baby = nil;
  [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];

}

- (IBAction)didClickTakePicture:(id)sender {
  [self.view endEditing:YES];
  if(!_takeController) {
    _takeController = [[FDTakeController alloc] init];
    _takeController.delegate = self;
    _takeController.viewControllerForPresentingImagePickerController = self;
    _takeController.allowsEditingPhoto = YES;
    _takeController.allowsEditingVideo = NO;
  }
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
  PFFile *file = [PFFile fileWithData:_imageOrVideo];
  [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
    if(error) {
      // TODO: Notification
      NSLog(@"Failed to upload file %@", error);
    } else {
      [self saveAchievementWithAttachment:file andType:_imageOrVideoType];
    }
  } progressBlock:^(int percentDone) {
    // TOOD: Progress HUD
    NSLog(@"Uploading file %d", percentDone);
  }];
}

-(void) saveAchievementWithAttachment:(PFFile*) attachment andType:(NSString*) type {
  StandardMilestoneAchievement * achievement = [StandardMilestoneAchievement object];
  achievement.attachment = attachment;
  achievement.attachmentType = type;
  achievement.baby = self.baby;
  achievement.milestone = self.milestone;
  achievement.completionDate =  ((UIDatePicker*)self.completionDateTextField.inputView).date;
  [achievement saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
    if(succeeded) {
      [[NSNotificationCenter defaultCenter] postNotificationName:kDDNotificationMilestoneNotedAndSaved object:self userInfo:@{@"" : achievement.milestone}];
      UIImageView *myImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]];
      myImageView.frame = self.view.frame;
      myImageView.alpha = 0.0;
      [myImageView sizeToFit];
      [self.view addSubview:myImageView];
      [UIView animateWithDuration:1.0 delay:0.0 options:0 animations:^{myImageView.alpha = 1.0;} completion:^(BOOL finished){
        [[NSNotificationCenter defaultCenter] postNotificationName:kDDNotificationMilestoneNoted object:self userInfo:@{@"" : achievement.milestone}];
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
      }];
    } else {
      // TODO: send to stats engine/logging
      NSLog(@"Failed to save achievment. Error: %@",error);
    }
  }]; // For now, save whenever we can

  // TODO: Show Ranking
  
}

-(void) doneWithDatePicker {
  [self.view endEditing:YES];
}

-(void)updateCompletionDateTextField:(id)sender
{
  UIDatePicker *picker = (UIDatePicker*)sender;
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
  self.completionDateTextField.text = [dateFormatter stringFromDate:picker.date];
}

#pragma mark - FDTakeDelegate

- (void)takeController:(FDTakeController *)controller didCancelAfterAttempting:(BOOL)madeAttempt
{
  // TODO: Log this for user interaction tracking
  //  UIAlertView *alertView;
//  if (madeAttempt)
//    alertView = [[UIAlertView alloc] initWithTitle:@"Example app" message:@"The take was cancelled after selecting media" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//  else
//    alertView = [[UIAlertView alloc] initWithTitle:@"Example app" message:@"The take was cancelled without selecting media" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//  [alertView show];
}

- (void)takeController:(FDTakeController *)controller gotPhoto:(UIImage *)photo withInfo:(NSDictionary *)info
{
  // TODO: Support video too!
  _imageOrVideo = UIImageJPEGRepresentation(photo, 0.5f);
  _imageOrVideoType = @"image/jpg";
  self.takePictureButton.contentMode = UIViewContentModeCenter;
  [self.takePictureButton setBackgroundImage:photo forState:UIControlStateNormal];
}

-(void) viewWillAppear:(BOOL)animated {
  // This is needed to hack around the fact that the image picker turns on the status bar
  [[UIApplication sharedApplication] setStatusBarHidden:YES];
  
}


@end
