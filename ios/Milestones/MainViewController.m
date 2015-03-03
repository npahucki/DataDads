//
//  MainViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/27/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <hipmob/HMService.h>
#import "MainViewController.h"
#import "OnboardingStepViewController.h"
#import "SWRevealViewController.h"

@implementation MainViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLogOut) name:kDDNotificationUserLoggedOut object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateApplicationBadgeFromTabs) name:UIApplicationWillResignActiveNotification object:nil];


    SWRevealViewController *revealViewController = self.revealViewController;
    revealViewController.frontViewPosition = FrontViewPositionLeftSideMost;
    revealViewController.toggleAnimationType = SWRevealToggleAnimationTypeEaseOut;

    if (revealViewController) {
//        [self.revealButtonItem setTarget: self.revealViewController];
//        [self.revealButtonItem setAction: @selector( revealToggle: )];
        [self.view addGestureRecognizer:revealViewController.panGestureRecognizer];
    }
    
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)userDidLogOut {
    // Put us back on the main screen.
    [self setSelectedIndex:0];
}

- (void)viewDidAppear:(BOOL)animated {
    ParentUser *user = ParentUser.currentUser;
    if (user) {
        if ([user objectForKey:@"isMale"] != nil) { // If the isMale is not set, it means that they did not finish the signup process.
            [UsageAnalytics identify:user];
            [[HMService sharedService] setUser:user.objectId];
            if (user.hasEmail) [[HMService sharedService] updateEmail:user.email];
            if (user.fullName) [[HMService sharedService] updateEmail:user.fullName];

            // Make sure the user is eventually set, even if somehow it didn't get set on login or when the user was created.
            PFInstallation *installation = [PFInstallation currentInstallation];
            if (![installation objectForKey:@"user"]) {
                [installation setObject:[PFUser currentUser] forKey:@"user"];
                [installation saveEventually];
            }

            if (Baby.currentBaby == nil) {
                // Finally, we must have at least one baby's info on file
                PFQuery *query = [Baby queryForBabiesForUser:PFUser.currentUser];
                query.cachePolicy = [Reachability isParseCurrentlyReachable] ? kPFCachePolicyCacheThenNetwork : kPFCachePolicyCacheOnly;
                __block BOOL cachedResult = YES;
                [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                    if (!error) {
                        // NOTE: This block gets called twice, once for cache, then once for network
                        // With the Cache then Network Policy both are always called.
                        if ([objects count] > 0) {
                            // First call will be cache, we use that, then when the network call is complete
                            // If and only if the Baby object is different do we replace it and send the notfication again
                            Baby *newBaby = [objects firstObject];
                            if (![Baby currentBaby] || [newBaby.updatedAt compare:[Baby currentBaby].updatedAt] == NSOrderedDescending) {
                                [Baby setCurrentBaby:newBaby];
                                if (newBaby) [self showTutorialPromptIfNeeded:user];
                            }
                        } else if (!cachedResult) { // Don't show the baby screen when there are simply no objects in the cache.
                            // Must show the enter baby screen since there are none registered yet
                            [self performSegueWithIdentifier:@"enterBabyInfo" sender:self];
                        }
                    } else {
                        if (error.code != kPFErrorCacheMiss) {
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Small Problem" message:@"Could not load info for your baby. You may want to check that you have an internet connection and/or try again a little later" delegate:nil cancelButtonTitle:@"Accept" otherButtonTitles:nil, nil];
                            [alert show];
                            NSLog(@"Error trying to load baby : %@", error);
                        }
                    }

                    // Flip the bit
                    if (cachedResult) {
                        cachedResult = NO;
                    }
                }];
            }
            [super viewDidAppear:animated];
        } else {
            // Missing user Info, perhaps didn't complete the signup process
            [self performSegueWithIdentifier:kDDSegueEnterBabyInfo sender:self];
            [[[UIAlertView alloc] initWithTitle:@"Ooops!" message:@"It looks like we didn't finish your last attempt to signup - let's finish it now!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    } else {
        [self performSegueWithIdentifier:@"showIntroScreen" sender:self];
    }


}

// Run when the app is going to the background
- (void)updateApplicationBadgeFromTabs {
    NSInteger totalBadgeCount = 0;
    for (UIViewController *vc in self.viewControllers) {
        totalBadgeCount += vc.tabBarItem.badgeValue.integerValue;
    }
    [PFInstallation currentInstallation].badge = totalBadgeCount;
    [[PFInstallation currentInstallation] saveEventually];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kDDSegueEnterBabyInfo]) {
        OnboardingStepViewController * topController = (OnboardingStepViewController *) ((UINavigationController *)segue.destinationViewController).topViewController;
        topController.baby = Baby.currentBaby;
    }
}

- (void)showTutorialPromptIfNeeded:(ParentUser *)user {
    if (!user.shownTutorialPrompt) {
        user.shownTutorialPrompt = YES;

        if (MPTweakValue(@"ShowTutorialMandatory", YES)) {
            [[[UIAlertView alloc] initWithTitle:@"Before You Get Started"
                                        message:@"You will be shown a quick tutorial on how things work. You can watch it again anytime under 'account preferences'"
                                       delegate:nil
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil] showWithButtonBlock:^(NSInteger buttonIndex) {
                [self performSegueWithIdentifier:@"showTutorial" sender:self];
            }];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Welcome!"
                                        message:@"If you want to get a feel for how things work, there is a tutorial availble under 'account preferences'"
                                       delegate:nil
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil] show];
        }
    }
}


@end
