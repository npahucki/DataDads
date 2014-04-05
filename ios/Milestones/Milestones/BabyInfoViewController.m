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
#import "BabyTagsViewController.h"

@interface BabyInfoViewController ()

@end

@implementation BabyInfoViewController


- (void)viewDidLoad
{
  [super viewDidLoad];
  // Needed to dimiss the keyboard once a user clicks outside the text boxes
  UITapGestureRecognizer *viewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
  [self.view addGestureRecognizer:viewTap];
  
  self.babyName.delegate = self;

  UIToolbar * toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width, 44)];
  toolBar.items = @[[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"completeIcon"] style:UIBarButtonItemStyleBordered target:self action:@selector(handleSingleTap:)]];

  
  UIDatePicker *datePicker1 = [[UIDatePicker alloc]init];
  datePicker1.datePickerMode = UIDatePickerModeDate;
  datePicker1.date = [NSDate date];
  datePicker1.maximumDate = datePicker1.date;
  [datePicker1 addTarget:self action:@selector(updateDobTextField:) forControlEvents:UIControlEventValueChanged];
  [self.dobTextField setInputView:datePicker1];
  [self.dobTextField setInputAccessoryView:toolBar];
  self.dobTextField.delegate = self;
  
  UIDatePicker *datePicker2 = [[UIDatePicker alloc]init];
  datePicker2.datePickerMode = UIDatePickerModeDate;
  datePicker2.date = [NSDate date];
  datePicker2.maximumDate = datePicker2.date;
  [datePicker2 addTarget:self action:@selector(updateDueDateTextField:) forControlEvents:UIControlEventValueChanged];
  [self.dueDateTextField setInputView:datePicker2];
  [self.dueDateTextField setInputAccessoryView:toolBar];
  self.dueDateTextField.delegate = self;

}

-(void)handleSingleTap:(UITapGestureRecognizer *)sender {
  [self.view endEditing:NO];
}

- (IBAction)didClickMaleButton:(id)sender {
  self.maleButton.selected = YES;
  self.maleLabel.highlighted = YES;
  self.femaleButton.selected = NO;
  self.femaleLabel.highlighted = NO;
  [self updateNextButtonState];
}

- (IBAction)didClickFemaleButton:(id)sender {
  self.femaleButton.selected = YES;
  self.femaleLabel.highlighted = YES;
  self.maleButton.selected = NO;
  self.maleLabel.highlighted = NO;
  [self updateNextButtonState];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
  [textField resignFirstResponder];
  return YES;
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
  self.dobTextField.text = [self formatDate:picker.date];
}

-(void)updateDueDateTextField:(id)sender
{
  UIDatePicker *picker = (UIDatePicker*)self.dueDateTextField.inputView;
  self.dueDateTextField.text = [self formatDate:picker.date];
}
- (IBAction)textFieldEditingDidEnd:(id)sender {
  [self updateNextButtonState];
}

-(void) updateNextButtonState {
  self.nextButton.enabled = self.dueDateTextField.text.length && self.dobTextField.text.length && self.babyName.text.length > 1 && (self.maleButton.isSelected || self.femaleButton.isSelected);
}

- (NSString *)formatDate:(NSDate *)date
{
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
  NSString *formattedDate = [dateFormatter stringFromDate:date];
  return formattedDate;
}


-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  Baby* baby = [Baby object];
  baby.parentUserId = PFUser.currentUser.objectId;
  baby.name = self.babyName.text;
  baby.isMale = self.maleButton.isSelected;
  baby.birthDate = ((UIDatePicker*)self.dobTextField.inputView).date;
  baby.dueDate = ((UIDatePicker*)self.dueDateTextField.inputView).date;
  ((BabyTagsViewController*) segue.destinationViewController).baby = baby;
}


@end
