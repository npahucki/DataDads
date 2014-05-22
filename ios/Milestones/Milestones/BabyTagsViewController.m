//
//  BabyTagsViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 4/4/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "BabyTagsViewController.h"
#import "BabyInfoPhotoViewController.h"

@interface BabyTagsViewController ()

@end

@implementation BabyTagsViewController {
  BabyTagsTableViewController* _tagTableViewController;
}

// TODO: Check all tags the baby already has!

- (IBAction)didClickAddNewTag:(id)sender {
  [_tagTableViewController addNewTag:self.addTagTextField.text];
  self.addTagTextField.text = nil;
  [self.view endEditing:NO];
}

- (IBAction)didChageAddTagTextField:(id)sender {
  self.addTagButton.enabled = self.addTagTextField.text.length > 0;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  if([segue.identifier isEqual:@"embed"]) {
    _tagTableViewController = (BabyTagsTableViewController*) segue.destinationViewController;
  } else {
    self.baby.tags = [_tagTableViewController.selectedTags allObjects];
    ((UIViewController<ViewControllerWithBaby>*)segue.destinationViewController).baby = self.baby;
  }
}

@end
