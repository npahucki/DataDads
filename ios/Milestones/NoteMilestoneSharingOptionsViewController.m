//
//  NoteMilestoneSharingOptionsViewController.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 3/6/15.
//  Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "NoteMilestoneSharingOptionsViewController.h"
#import "NoteMilestoneSharingTableViewController.h"
#import "FollowConnectionsDataSource.h"
#import "InviteContactsAddressBookDataSource.h"


@implementation NoteMilestoneSharingOptionsViewController {
    NoteMilestoneSharingTableViewController *_sharingTableViewController;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[NoteMilestoneSharingTableViewController class]]) {
        _sharingTableViewController = (NoteMilestoneSharingTableViewController *) segue.destinationViewController;
        _sharingTableViewController.contactsDataSource = [[InviteContactsAddressBookDataSource alloc] init];
        _sharingTableViewController.followConnectionsDataSource = [[FollowConnectionsDataSource alloc] init];
    }
}

- (void)viewDidFinishSlidingOut:(UIViewController *)slidingView over:(UIViewController *)otherVc {
    BOOL enableFacebook = ParentUser.currentUser.autoPublishToFacebook && [PFFacebookUtils userHasAuthorizedPublishPermissions:ParentUser.currentUser];
    [self.enableFacebookButton setOn:enableFacebook animated:NO];

    BOOL enableFollowers = ParentUser.currentUser.autoShareWithFollowers && _sharingTableViewController.hasConnections;
    [self.enableFollowersSwitch setOn:enableFollowers animated:NO];
    if (enableFollowers) { // Reload to make sure we have the latest data.
        [_sharingTableViewController loadObjects];
    }
}

- (void)viewDidFinishSlidingIn:(UIViewController *)slidingView over:(UIViewController *)otherVc {

}


- (IBAction)didChangeEnableFacebookSwitch:(id)sender {
    // TODO: Move from NOteMilestone controller. 
}

- (IBAction)didChangeFollowersSwitch:(id)sender {
    if (self.enableFollowersSwitch.on) {
        if (_sharingTableViewController.hasConnections) {
            _sharingTableViewController.tableView.hidden = NO;
            // TODO: Allow to invite friends!
            // OR: Always allow to invite friends?
        } else {
            _sharingTableViewController.tableView.hidden = YES;
        }
    }
}


@end
