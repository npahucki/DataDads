//
//  CreateMilestoneViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/21/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "CreateMilestoneViewController.h"
#import "NoteMilestoneViewController.h"

@interface CreateMilestoneViewController ()

@end

@implementation CreateMilestoneViewController


- (void)viewDidLoad
{
  [super viewDidLoad];
  NSAssert(self.achievement, @"Expected achievment would be set before view is loaded");
  
  self.descriptionTextView.text = DESCRIPTION_PLACEHOLDER_TEXT;

  // Needed to dimiss the keyboard once a user clicks outside the text boxes
  UITapGestureRecognizer *viewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
  [self.view addGestureRecognizer:viewTap];
  
}
- (IBAction)titleLabelDidChange:(id)sender {
  self.nextButton.enabled = [self.titleTextField.text length] > 2;
}

-(void)handleSingleTap:(UITapGestureRecognizer *)sender {
  [self.view endEditing:NO];
}

- (IBAction)editingTitleDidEnd:(id)sender {
  [self.descriptionTextView becomeFirstResponder];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
  if ([textView.text isEqualToString:DESCRIPTION_PLACEHOLDER_TEXT]) {
    textView.text = @"";
  }
  [textView becomeFirstResponder];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
  if ([textView.text isEqualToString:@""]) {
    textView.text = DESCRIPTION_PLACEHOLDER_TEXT;
    textView.textColor = [UIColor lightGrayColor];
  } else {
    _descriptionDirty = YES;
  }
  [textView resignFirstResponder];
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if([segue.identifier isEqualToString:kDDSegueNoteMilestone]) {
    self.achievement.customTitle = self.titleTextField.text;
    self.achievement.customDescription = self.descriptionTextView.text;
    ((NoteMilestoneViewController*)segue.destinationViewController).achievement = self.achievement;
  }
}

@end
