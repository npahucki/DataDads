//
// Created by Nathan  Pahucki on 3/5/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "NoteMilestoneSlideOverViewController.h"
#import "NoteMilestoneViewController.h"
#import "NoteMilestoneSharingOptionsViewController.h"


@implementation NoteMilestoneSlideOverViewController {
    NoteMilestoneViewController *_noteMilestoneViewController;
    NoteMilestoneSharingOptionsViewController *_sharingOptionsViewController;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[NoteMilestoneViewController class]]) {
        _noteMilestoneViewController = ((NoteMilestoneViewController *) segue.destinationViewController);
        _noteMilestoneViewController.achievement = self.achievement;

    } else if ([segue.destinationViewController isKindOfClass:[NoteMilestoneSharingOptionsViewController class]]) {
        _sharingOptionsViewController = (NoteMilestoneSharingOptionsViewController *) segue.destinationViewController;
        _sharingOptionsViewController.achievement = self.achievement;
    }
}

- (IBAction)didClickCanelButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)didClickNoteItButton:(id)sender {
    // TODO: We might need to show the sharing options if the user has no connections.
    [_sharingOptionsViewController updateAchievementSharingOptions];
    [_noteMilestoneViewController noteMilestone];
}

@end