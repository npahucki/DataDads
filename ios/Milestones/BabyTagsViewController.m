//
//  BabyTagsViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 4/4/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "BabyTagsViewController.h"
#import "NoConnectionAlertView.h"

@interface BabyTagsViewController ()

@end

@implementation BabyTagsViewController {
    BabyTagsTableViewController *_tagTableViewController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [NoConnectionAlertView createInstanceForController:self];
}

- (void)reclacControlEnabledState {
    BOOL enabled = [Reachability isParseCurrentlyReachable];
    self.addTagButton.enabled = enabled && self.addTagTextField.text.length > 0;
    self.addTagTextField.enabled = enabled;
}

- (IBAction)didChangeAddTagTextField:(id)sender {
    [self reclacControlEnabledState];
}

- (IBAction)didClickAddNewTag:(id)sender {
    [_tagTableViewController addNewTag:self.addTagTextField.text];
    self.addTagTextField.text = nil;
    [self.view endEditing:NO];
    self.addTagButton.enabled = NO;
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqual:@"embed"]) {
        _tagTableViewController = (BabyTagsTableViewController *) segue.destinationViewController;
        _tagTableViewController.selectedTags = [NSSet setWithArray:self.baby.tags];
    } else {
        self.baby.tags = [_tagTableViewController.selectedTags allObjects];
        [super prepareForSegue:segue sender:sender];
    }
}

@end
