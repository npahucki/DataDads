//
//  BabyInfoViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/21/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "BabyInfoViewController.h"
#import "MainViewController.h"
#import "Baby.h"
#import "Tag.h"
#import "MBProgressHUD.h"

@interface BabyInfoViewController ()
- (IBAction)didClickGoButton:(id)sender;


@end

@implementation BabyInfoViewController


- (void)viewDidLoad
{
  [super viewDidLoad];
  baby = [Baby object];
  
  // Needed to dimiss the keyboard once a user clicks outside the text boxes
  UITapGestureRecognizer *viewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
  [self.view addGestureRecognizer:viewTap];
  
  
  UIDatePicker *datePicker1 = [[UIDatePicker alloc]init];
  datePicker1.datePickerMode = UIDatePickerModeDate;
  datePicker1.date = [NSDate date];
  datePicker1.maximumDate = datePicker1.date;
  [datePicker1 addTarget:self action:@selector(updateDobTextField:) forControlEvents:UIControlEventValueChanged];
  [self.dobTextField setInputView:datePicker1];
  
  UIDatePicker *datePicker2 = [[UIDatePicker alloc]init];
  datePicker2.datePickerMode = UIDatePickerModeDate;
  datePicker2.date = [NSDate date];
  datePicker2.maximumDate = datePicker2.date;
  [datePicker2 addTarget:self action:@selector(updateDueDateTextField:) forControlEvents:UIControlEventValueChanged];
  [self.dueDateTextField setInputView:datePicker2];
  
  
  tagViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Tags"];
  tagViewController.delegate = self;
  [self.tagsTextField setInputView:tagViewController.view];
}

-(void)handleSingleTap:(UITapGestureRecognizer *)sender {
  [self.view endEditing:NO];
}

- (void)tagsDidFinishSelection:(NSOrderedSet *) tags {
  [self.view endEditing:YES];
  baby.tags = tags.array;
  self.tagsTextField.text = [NSString stringWithFormat:@"Tags: %@", [baby.tags componentsJoinedByString:@", "]];
}

- (IBAction)didSelectGender:(id)sender {
  [self.view endEditing:NO];
}

- (IBAction)didClickGoButton:(id)sender {
  
  if([self.dobTextField.text length] && [self.dueDateTextField.text length] && [self.babyName.text length] && self.genderControl.selectedSegmentIndex != -1) {
    // TODO: Baby avatar
    baby.name = self.babyName.text;
    baby.parentUserId = PFUser.currentUser.objectId;
    baby.isMale = self.genderControl.selectedSegmentIndex < 1;
    [self saveObject:baby withTitle:@"Saving Baby Info" andFailureMessage:@"Could not save your baby's information."];
  } else {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Incomplete Data" message:@"Please fill in all fields." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
    [alert show];
  }
}
- (IBAction)editingDidBeginForDueDate:(id)sender {
  if([self.dueDateTextField.text length] == 0) {
    UIDatePicker *dueDatePicker = (UIDatePicker*)self.dueDateTextField.inputView;
    UIDatePicker *birthDatePicker = (UIDatePicker*)self.dobTextField.inputView;
    dueDatePicker.date = birthDatePicker.date;
    [self updateDueDateTextField:self];
  }
}

-(void)updateDobTextField:(id)sender
{
  UIDatePicker *picker = (UIDatePicker*)self.dobTextField.inputView;
  baby.birthDate =  picker.date;
  self.dobTextField.text = [self formatDate:picker.date];
}

-(void)updateDueDateTextField:(id)sender
{
  UIDatePicker *picker = (UIDatePicker*)self.dueDateTextField.inputView;
  baby.dueDate = picker.date;
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
