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

-(void) viewDidLoad {
  [super viewDidLoad];
  [self networkReachabilityChanged:nil]; // set the initial loading based on connectivity
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkReachabilityChanged:) name:kReachabilityChangedNotification object:nil];
  
  // TODO: Check all tags the baby already has!
  
}

-(void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

-(void) networkReachabilityChanged:(NSNotification*)notification {
  [self reclacControlEnabledState];
}

-(void) reclacControlEnabledState {
  BOOL enabled = [Reachability isParseCurrentlyReachable];
  self.addTagButton.enabled = enabled && self.addTagTextField.text.length > 0;
  self.addTagTextField.enabled = enabled;
}

- (IBAction)didChageAddTagTextField:(id)sender {
  [self reclacControlEnabledState];
}

- (IBAction)didClickAddNewTag:(id)sender {
  [_tagTableViewController addNewTag:self.addTagTextField.text];
  self.addTagTextField.text = nil;
  [self.view endEditing:NO];
  self.addTagButton.enabled = NO;
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
