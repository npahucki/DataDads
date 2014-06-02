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
#import "BabyInfoPhotoViewController.h"
#import "NSDate+Utils.h"

#define MIN_DUE_BEFORE -60
#define MAX_DUE_AFTER 21



@interface BabyInfoViewController ()

@end

@implementation BabyInfoViewController {
  BOOL _dueDateDirty;
}


- (void)viewDidLoad
{
  [super viewDidLoad];
  self.maleLabel.highlightedTextColor = [UIColor appNormalColor];
  self.femaleLabel.highlightedTextColor = [UIColor appNormalColor];
  // Needed to dimiss the keyboard once a user clicks outside the text boxes
  UITapGestureRecognizer *viewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
  [self.view addGestureRecognizer:viewTap];
  self.babyName.delegate = self;
  self.dobTextField.picker.maximumDate = [NSDate date];
  
  if(self.baby) {
    self.babyName.text = self.baby.name;
    self.maleButton.selected = self.baby.isMale;
    ((UIDatePicker*)self.dobTextField.inputView).date = self.baby.birthDate;
    ((UIDatePicker*)self.dueDateTextField.inputView).date = self.baby.dueDate;
  } else {
    self.baby = [Baby object];
  }
}
- (IBAction)didChangeBirthDateField:(id)sender {
  
}

-(void)handleSingleTap:(UITapGestureRecognizer *)sender {
  [self.view endEditing:NO];
}

- (IBAction)didClickMaleButton:(id)sender {
  [self.view endEditing:NO];
  self.maleButton.selected = YES;
  self.maleLabel.highlighted = YES;
  self.femaleButton.selected = NO;
  self.femaleLabel.highlighted = NO;
  [self updateNextButtonState];
}

- (IBAction)didClickFemaleButton:(id)sender {
  [self.view endEditing:NO];
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

- (IBAction)textFieldEditingDidEnd:(id)sender {
  if(sender == self.dueDateTextField) _dueDateDirty = YES;
  if(sender == self.dobTextField) {
    self.dueDateTextField.picker.maximumDate =  [self.dobTextField.date dateByAddingDays:MAX_DUE_AFTER];
    self.dueDateTextField.picker.minimumDate =  [self.dobTextField.date dateByAddingDays:MIN_DUE_BEFORE];
    if(!_dueDateDirty)
      self.dueDateTextField.date = self.dobTextField.date;
  }
  [self updateNextButtonState];
}

-(void) updateNextButtonState {
  self.nextButton.enabled = self.dueDateTextField.text.length && self.dobTextField.text.length && self.babyName.text.length > 1 && (self.maleButton.isSelected || self.femaleButton.isSelected);
  
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  self.baby.name = self.babyName.text;
  self.baby.isMale = self.maleButton.isSelected;
  self.baby.birthDate = ((UIDatePicker*)self.dobTextField.inputView).date;
  self.baby.dueDate = ((UIDatePicker*)self.dueDateTextField.inputView).date;
  ((UIViewController<ViewControllerWithBaby>*)segue.destinationViewController).baby = self.baby;
}

- (IBAction)didClickCancelButton:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}


@end
