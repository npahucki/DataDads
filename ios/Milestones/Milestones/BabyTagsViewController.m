//
//  BabyTagsViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 4/4/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "BabyTagsViewController.h"
#import "BabyInfoPhotoControllerViewController.h"

@interface BabyTagsViewController ()

@end

@implementation BabyTagsViewController

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  if([segue.identifier isEqual:@"embed"]) {
    _tagTableViewController = (BabyTagsTableViewController*) segue.destinationViewController;
  } else {
    self.baby.tags = [_tagTableViewController.selectedTags allObjects];
    ((BabyInfoPhotoControllerViewController*) segue.destinationViewController).baby = self.baby;
  }
}

@end
