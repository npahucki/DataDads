//
// Created by Nathan  Pahucki on 3/5/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "NoteMilestoneSlideOverViewController.h"
#import "NoteMilestoneViewController.h"


@implementation NoteMilestoneSlideOverViewController {
    NoteMilestoneViewController *_noteMilestoneViewController;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[NoteMilestoneViewController class]]) {
        _noteMilestoneViewController = ((NoteMilestoneViewController *) segue.destinationViewController);
        _noteMilestoneViewController.achievement = self.achievement;
    }
}

- (IBAction)didClickCanelButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)didClickNoteItButton:(id)sender {
    [_noteMilestoneViewController noteMilestoneWithBlock:nil];
}

@end