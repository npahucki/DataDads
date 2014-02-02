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

- (IBAction)didClickTakePicture:(id)sender {
}

- (IBAction)didClickCancelButton:(id)sender {
  self.milestone = nil;
  self.baby = nil;
  [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];

}

- (IBAction)didClickDoneButton:(id)sender {
  [self.view endEditing:YES];
  StandardMilestoneAchievement * achievement = [StandardMilestoneAchievement object];
  achievement.baby = self.baby;
  achievement.milestone = self.milestone;
  achievement.completionDate =  ((UIDatePicker*)self.completionDateTextField.inputView).date;
  [achievement saveEventually:^(BOOL succeeded, NSError *error) {
    if(succeeded) {
      [[NSNotificationCenter defaultCenter] postNotificationName:kDDNotificationMilestoneNotedAndSaved object:self userInfo:@{@"" : achievement.milestone}];
    } else {
      // TODO: send to stats engine/logging
      NSLog(@"Failed to save achievment. Error: %@",error);
    }
  }]; // For now, save whenever we can

  // TODO: Show Ranking
  
  UIImageView *myImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]];
  myImageView.frame = self.view.frame;
  myImageView.alpha = 0.0;
  [myImageView sizeToFit];
  [self.view addSubview:myImageView];
  [UIView animateWithDuration:1.0 delay:0.0 options:0 animations:^{myImageView.alpha = 1.0;} completion:^(BOOL finished){
    [[NSNotificationCenter defaultCenter] postNotificationName:kDDNotificationMilestoneNoted object:self userInfo:@{@"" : achievement.milestone}];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
  }];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  
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


@end
