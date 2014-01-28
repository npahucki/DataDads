//
//  BabyInfoViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/21/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "BabyInfoViewController.h"
#import "Baby.h"
#import "MBProgressHUD.h"

@interface BabyInfoViewController ()
- (IBAction)didClickGoButton:(id)sender;


@end

@implementation BabyInfoViewController


- (void)viewDidLoad
{
  [super viewDidLoad];
  
  // Needed to dimiss the keyboard once a user clicks outside the text boxes
  UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
  [self.view addGestureRecognizer:singleTap];
  
  UIDatePicker *datePicker1 = [[UIDatePicker alloc]init];
  datePicker1.datePickerMode = UIDatePickerModeDate;
  [datePicker1 setDate:[NSDate date]];
  [datePicker1 addTarget:self action:@selector(updateDobTextField:) forControlEvents:UIControlEventValueChanged];
  [self.dobTextField setInputView:datePicker1];
  
  UIDatePicker *datePicker2 = [[UIDatePicker alloc]init];
  datePicker2.datePickerMode = UIDatePickerModeDate;
  [datePicker2 setDate:[NSDate date]];
  [datePicker2 addTarget:self action:@selector(updateDueDateTextField:) forControlEvents:UIControlEventValueChanged];
  [self.dueDateTextField setInputView:datePicker2];
}

-(void)handleSingleTap:(UITapGestureRecognizer *)sender{
  [self.view endEditing:YES];
}
- (IBAction)radioButtonTouched:(id)sender {
  [self.view endEditing:YES];
}

- (IBAction)didClickGoButton:(id)sender {

  if([self.dobTextField.text length] && [self.dueDateTextField.text length] && [self.babyName.text length]) {
    Baby* baby = [Baby object];
    // TODO: Baby avatar
    baby.name = self.babyName.text;
    baby.birthDate =  ((UIDatePicker*)self.dobTextField.inputView).date;
    baby.dueDate =  ((UIDatePicker*)self.dueDateTextField.inputView).date;
    baby.parentUserId = PFUser.currentUser.objectId;
    baby.isMale = self.genderControl.selectedSegmentIndex < 1;
    
    MBProgressHUD * hud = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
    hud.dimBackground = YES;
    hud.labelText = NSLocalizedString(@"Saving Baby Info", nil);
    [baby saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
      if(succeeded) {
        [MBProgressHUD hideHUDForView:self.view animated:NO];
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
      } else {
        NSLog(@"Could not save baby info: %@", error);
        [MBProgressHUD hideHUDForView:self.view animated:NO];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Could not save your baby's information. Please make sure that you are conencted to a network and try again." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
        [alert show];
      }
    }];
    
  } else {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Incomplete Data" message:@"Please fill in all fields." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
    [alert show];
  }
}

-(void)updateDobTextField:(id)sender
{
  UIDatePicker *picker = (UIDatePicker*)self.dobTextField.inputView;
  self.dobTextField.text = [self formatDate:picker.date];
}

-(void)updateDueDateTextField:(id)sender
{
  UIDatePicker *picker = (UIDatePicker*)sender;
  self.dueDateTextField.text = [self formatDate:picker.date];
}


- (NSString *)formatDate:(NSDate *)date
{
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
  NSString *formattedDate = [dateFormatter stringFromDate:date];
  return formattedDate;
}


@end
