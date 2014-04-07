//
//  MilestoneNotedViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/21/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "NoteMilestoneViewController.h"
#import "MilestoneAchievement.h"

@interface NoteMilestoneViewController ()

@end

@implementation NoteMilestoneViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  _imageOrVideo = nil;
  _imageOrVideoType = nil;
  
  NSAssert(self.achievement.standardMilestone || self.achievement.customTitle,@"one of standardMilestone or customTitle must be set");
  NSAssert(self.achievement.baby, @"baby must be set on acheivement before view loads");
  
  // Can't skip standard milestones
  self.skipButton.hidden = self.achievement.standardMilestone == nil;

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

-(void) viewWillAppear:(BOOL)animated {
  // This is needed to hack around the fact that the image picker turns on the status bar
  [[UIApplication sharedApplication] setStatusBarHidden:YES];
  [super viewWillAppear:animated];
}

- (IBAction)didClickTakePicture:(id)sender {
  [self.view endEditing:YES];
  _takeController = [[FDTakeController alloc] init];
  _takeController.delegate = self;
  _takeController.viewControllerForPresentingImagePickerController = self;
  _takeController.allowsEditingPhoto = YES;
  _takeController.allowsEditingVideo = NO;
  [_takeController takePhotoOrChooseFromLibrary];
}

- (IBAction)didClickSkipButton:(id)sender {
  [self.view endEditing:YES];
  [self showHUD:YES];
  // Override any user input when skipping
  ((UIDatePicker*)self.completionDateTextField.inputView).date = [NSDate date];
  self.achievement.skipped = YES;
  [self saveAchievementWithAttachment:nil andType:nil];
}

- (IBAction)didClickDoneButton:(id)sender {
  [self.view endEditing:YES];
  [self showHUD:YES];
  if(_imageOrVideo) {
    [self saveImageOrPhoto];
  } else {
    [self saveAchievementWithAttachment:nil andType:nil];
  }
}

-(void) saveImageOrPhoto {
  self.hud.mode = MBProgressHUDModeCustomView;
  self.hud.customView =  [[UIImageView alloc] initWithImage:[UIImage animatedImageNamed:@"progress-" duration:1.0f]];
  self.hud.labelText = NSLocalizedString(@"Uploading Photo", nil);
  PFFile *file = [PFFile fileWithData:_imageOrVideo];
  [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
    if(error) {
      [self showSaveError:error withMessage:@"Could not upload your photo."];
    } else {
      [self saveAchievementWithAttachment:file andType:_imageOrVideoType];
    }
  } progressBlock:^(int percentDone) {
    // This won't fucking work no matter what I do, after the first image change, no other images will be shown! I wasted 3 hours trying to get it to work
    // to no avial, will have to revisit sometime in the future.
    // The idea is to indicate the file progress by using one of the images (50 images) to correspond to the half the percent
    //    int idx = percentDone / 2;
    //    NSString * progressImageName = [NSString stringWithFormat:@"progress-%d.png", idx];
    //    self.hud.customView =  [[UIImageView alloc] initWithImage:[UIImage imageNamed:progressImageName]]];
  }];
}

-(void) saveAchievementWithAttachment:(PFFile*) attachment andType:(NSString*) type {
  self.hud.mode = MBProgressHUDModeCustomView;
  self.hud.customView =  [[UIImageView alloc] initWithImage:[UIImage animatedImageNamed:@"progress-" duration:1.0f]];
  self.hud.labelText = @"Noting milestone";
  self.achievement.attachment = attachment;
  self.achievement.attachmentType = type;
  self.achievement.completionDate =  ((UIDatePicker*)self.completionDateTextField.inputView).date;
  [self.achievement saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
    if(succeeded) {
      [[NSNotificationCenter defaultCenter] postNotificationName:kDDNotificationMilestoneNotedAndSaved object:self userInfo:@{@"" : self.achievement}];
      [self showSaveSuccessAndDismissDialog];
    } else {
      [self showSaveError:error withMessage:@"Could not note milestone."];
    }
  }];

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
}

- (void)takeController:(FDTakeController *)controller gotPhoto:(UIImage *)photo withInfo:(NSDictionary *)info
{
  // TODO: Support video too!
  _imageOrVideo = UIImageJPEGRepresentation(photo, 0.5f);
  _imageOrVideoType = @"image/jpg";
  self.takePictureButton.contentMode = UIViewContentModeCenter;
  [self.takePictureButton setBackgroundImage:photo forState:UIControlStateNormal];
}



@end
