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

  // Needed to dimiss the keyboard once a user clicks outside the text boxes
  UITapGestureRecognizer *viewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
  [self.view addGestureRecognizer:viewTap];
}
- (IBAction)editingTitleDidEnd:(id)sender {
  [self.view endEditing:YES];
}
- (IBAction)titleLabelDidChange:(id)sender {
  self.doneButton.enabled = [self.titleTextField.text length] > 4;
}

-(void)handleSingleTap:(UITapGestureRecognizer *)sender {
  [self.view endEditing:NO];
}

- (IBAction)didClickCancelButton:(id)sender {
  self.achievement = nil;
  [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)didClickDoneButton:(id)sender {
    self.achievement.customTitle = self.titleTextField.text;
    self.achievement.customDescription = self.descriptionTextView.text;
    [self performSegueWithIdentifier:kDDSegueNoteMilestone sender:self];
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if([segue.identifier isEqualToString:kDDSegueNoteMilestone]) {
    ((NoteMilestoneViewController*)segue.destinationViewController).achievement = self.achievement;
  }
}

// So when the NoteMileStone sview closes, we close ourselves too and the NoteMilestone view does not
// need ot know from where it was invoked.
-(void) dismissViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion {
  [self.presentingViewController dismissViewControllerAnimated:animated completion:completion];
}

@end
