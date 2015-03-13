//
// Created by Nathan  Pahucki on 3/5/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "NoteMilestoneSlideOverViewController.h"
#import "NoteMilestoneViewController.h"
#import "NoteMilestoneSharingOptionsViewController.h"
#import "FollowConnectionsDataSource.h"


@implementation NoteMilestoneSlideOverViewController {
    NoteMilestoneViewController *_noteMilestoneViewController;
    NoteMilestoneSharingOptionsViewController *_sharingOptionsViewController;
    BOOL _showedSharingScreen;
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

- (void)viewDidLoad {
    [super viewDidLoad];
    if (!_sharingOptionsViewController.followConnectionsDataSource.hasAnyConnections) {
        self.navigationItem.rightBarButtonItem.title = @"Next";
    }
}

- (IBAction)didClickCanelButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)didClickNoteItButton:(id)sender {
    // TODO: We might need an A/B tet for this?
    if (_showedSharingScreen || _sharingOptionsViewController.followConnectionsDataSource.hasAnyConnections) {
        // Just note it!
        [_noteMilestoneViewController updateAchievementFromInputs];
        [_sharingOptionsViewController updateAchievementSharingOptions];
        [_noteMilestoneViewController noteMilestone];
    } else {
        // other wise always show the share dialog (annoying!)
        _showedSharingScreen = YES;
        self.navigationItem.rightBarButtonItem.title = @"Note It";
        [self setSlideOverToShowingPosition:YES];
    }
}

- (void)slideOutViewDidSlideOut {
    _showedSharingScreen = YES;
    self.navigationItem.rightBarButtonItem.title = @"Note It";
}


@end