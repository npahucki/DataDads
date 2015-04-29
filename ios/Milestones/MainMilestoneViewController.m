//
//  MainMilestoneViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 4/1/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "MainMilestoneViewController.h"
#import "NoteMilestoneViewController.h"
#import "AchievementDetailsViewController.h"
#import "NoConnectionAlertView.h"
#import "AlertThenDisappearView.h"
#import "PronounHelper.h"
#import "SignUpOrLoginViewController.h"
#import "NoteMilestoneSlideOverViewController.h"
#import "AdFreeFeature.h"

#define AD_TRIGGER_LAUNCH_COUNT 2
#define AD_TRIGGER_MAX_TIME 60
#define AD_DISPLAY_TIME 7


@implementation MainMilestoneViewController {
    MilestoneAchievement *_currentAchievement;
    HistoryViewController *_historyController;
    BOOL _isMorganTouch;
    BOOL _isShowingSearchBar;
    UIDynamicAnimator *_animator;
    DataParentingAdView *_adView;
    NSDate *_dateLastAdShown;
    BOOL _productJustPurchased;

}


- (void)viewDidLoad {
    [super viewDidLoad];
    _productJustPurchased = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(babyUpdated:) name:kDDNotificationCurrentBabyChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(milestoneNotedAndSaved:) name:kDDNotificationMilestoneNotedAndSaved object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:kDDNotificationProductPurchased object:nil];

    [NoConnectionAlertView createInstanceForController:self];
    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(hideSearchBar)];
    swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    [self.searchBar addGestureRecognizer:swipeUp];


    // Add in another button to the right.
    self.searchButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"searchButton"] landscapeImagePhone:nil style:UIBarButtonItemStylePlain target:self action:@selector(didClickSearch:)];

    self.navigationItem.rightBarButtonItems = @[self.searchButton, self.addMilestoneButton];


    // NOTE: This could break in future versions....but the only ill effect will be not setting the custom properties.
    // Unfortunately, Apple does not provide a way to get access to the text field and the UIAppearance does not work for layer properties (apparently).
    UITextField *searchField = [self.searchBar valueForKey:@"_searchField"];
    searchField.layer.borderColor = [UIColor appInputBorderActiveColor].CGColor;
    searchField.layer.borderWidth = 1;
    searchField.layer.cornerRadius = 5;
    searchField.font = [UIFont fontForAppWithType:Book andSize:14];
    searchField.textColor = [UIColor appInputGreyTextColor];

}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self checkAndAskToLogInIfRecentPurchase];
    self.addMilestoneButton.enabled = Baby.currentBaby != nil;
    self.menuButton.enabled = Baby.currentBaby != nil;
    _isMorganTouch = NO; // Hack work around a double segue bug, caused by touching the cell too long
    [self showAdIfNeeded];
}

- (void)productPurchased:(id)productPurchased {
    _productJustPurchased = YES;
}

- (void)milestoneNotedAndSaved:(NSNotification *)notification {
    if (Baby.currentBaby && [ParentUser currentUser].showMilestoneStats) {
        MilestoneAchievement *achievement = notification.object;
        [achievement calculatePercentileRankingWithBlock:^(float percentile) {
            if (percentile >= 0) {
                NSDictionary *messageTextAttributes = @{NSFontAttributeName : [UIFont fontForAppWithType:Medium andSize:16.0], NSForegroundColorAttributeName : [UIColor appGreyTextColor]};
                NSDictionary *percentTextAttributes = @{NSFontAttributeName : [UIFont fontForAppWithType:Bold andSize:16.0], NSForegroundColorAttributeName : [UIColor appHeaderCounterActiveTextColor]};
                NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@'s growing up! Completed ", [PronounHelper replacePronounTokens:@"${He}" forBaby:Baby.currentBaby]] attributes:messageTextAttributes];
                if (percentile >= 50) {
                    [string appendAttributedString:[[NSAttributedString alloc] initWithString:@"before " attributes:messageTextAttributes]];
                } else {
                    percentile = 100 - percentile; // flip
                    [string appendAttributedString:[[NSAttributedString alloc] initWithString:@"after " attributes:messageTextAttributes]];
                }
                [string appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld%%", (long) percentile] attributes:percentTextAttributes]];
                [string appendAttributedString:[[NSAttributedString alloc] initWithString:@" of data-babies" attributes:messageTextAttributes]];

                AlertThenDisappearView *alert = [AlertThenDisappearView instanceForViewController:self];
                alert.titleLabel.font = nil; // Must clear this because it is set as part of UILabel's appearance.
                alert.titleLabel.attributedText = string;
                alert.imageView.image = [UIImage imageNamed:@"completedBest"];
                [alert showWithDelay:7];
            }
        }];
    }
}

- (void)babyUpdated:(NSNotification *)notification {
    [super babyUpdated:notification];
    Baby *baby = notification.object;
    self.addMilestoneButton.enabled = baby != nil;
    self.menuButton.enabled = baby != nil;
    if (!baby) {
        [self hideSearchBar];
    }
}

- (void)checkAndAskToLogInIfRecentPurchase {
    if (_productJustPurchased) {
        _productJustPurchased = NO;
        if (![ParentUser currentUser].isLoggedIn) {
            [[[UIAlertView alloc] initWithTitle:@"Make sure your pecious memories are safe!"
                                        message:@"Do you want to sign up now so we can backup your milestones and photos and videos in the cloud?"
                                       delegate:nil
                              cancelButtonTitle:@"Not Now"
                              otherButtonTitles:@"Yes", nil] showWithButtonBlock:^(NSInteger buttonIndex) {
                [UsageAnalytics trackSignupTrigger:@"promptAfterPurchase" withChoice:buttonIndex == 1];
                if (buttonIndex == 1) {
                    [SignUpOrLoginViewController presentSignUpInController:self andRunBlock:nil];
                }
            }];
        }
    }
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Embedded table
    if ([segue.destinationViewController isKindOfClass:[HistoryViewController class]]) {
        _historyController = ((HistoryViewController *) segue.destinationViewController);
        _historyController.delegate = self;
        return;
    }

    // Navigation Segues
    if ([segue.identifier isEqualToString:kDDSegueNoteMilestone] || [segue.identifier isEqualToString:kDDSegueNoteCustomMilestone]) {
        if ([segue.identifier isEqualToString:kDDSegueNoteCustomMilestone]) {
            [self createAchievementForMilestone:nil];
        }
        NSAssert(_currentAchievement, @"Expected currentAchievement to be set");
        [self hideSearchBar];
        NoteMilestoneSlideOverViewController *noteMilestoneViewController = (NoteMilestoneSlideOverViewController *)
                ((UINavigationController *) segue.destinationViewController).visibleViewController;
        noteMilestoneViewController.achievement = _currentAchievement;
    } else if ([segue.identifier isEqualToString:kDDSegueShowAchievementDetails]) {
        ((AchievementDetailsViewController *) segue.destinationViewController).achievement = _currentAchievement;
    }
}

- (void)hideSearchBar {
    if (_isShowingSearchBar) {
        self.searchButton.image = [UIImage imageNamed:@"searchButton"];
        [self.searchBar resignFirstResponder];
        _historyController.filterString = nil;
        CGFloat finalY = self.navigationController.navigationBar.frame.origin.y;
        _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
        _animator.delegate = self;
        UIGravityBehavior *gravityBehavior = [[UIGravityBehavior alloc] initWithItems:@[self.searchBar]];
        gravityBehavior.magnitude = -2.0f;
        [_animator addBehavior:gravityBehavior];

        UICollisionBehavior *collisionBehavior =
                [[UICollisionBehavior alloc] initWithItems:@[self.searchBar]];
        collisionBehavior.translatesReferenceBoundsIntoBoundary = NO;
        [collisionBehavior addBoundaryWithIdentifier:@"hideSearchBarBoundry" fromPoint:CGPointMake(0, finalY) toPoint:CGPointMake(self.searchBar.bounds.size.width, finalY)];
        collisionBehavior.collisionDelegate = self;
        [_animator addBehavior:collisionBehavior];
    }
}

- (void)collisionBehavior:(UICollisionBehavior *)behavior endedContactForItem:(id <UIDynamicItem>)item withBoundaryIdentifier:(id <NSCopying>)identifier {
    if ([@"hideSearchBarBoundry" isEqual:identifier]) {
        self.searchBar.hidden = YES;
        self.searchBar.text = nil;
        _isShowingSearchBar = NO;
    }
}

- (void)showSearchBar {
    CGFloat finalY = self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height + self.searchBar.bounds.size.height;
    if (!_isShowingSearchBar) {
        // Start it up above the frame so it can fall down.
        self.searchButton.image = [UIImage imageNamed:@"searchButton_active"];
        self.searchBar.frame = self.navigationController.navigationBar.frame;
        self.searchBar.hidden = NO;
        _isShowingSearchBar = YES;
        _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
        _animator.delegate = self;
        UIGravityBehavior *gravityBehavior = [[UIGravityBehavior alloc] initWithItems:@[self.searchBar]];
        gravityBehavior.magnitude = 2.0;
        [_animator addBehavior:gravityBehavior];

        UICollisionBehavior *collisionBehavior =
                [[UICollisionBehavior alloc] initWithItems:@[self.searchBar]];
        collisionBehavior.translatesReferenceBoundsIntoBoundary = NO;

        [collisionBehavior addBoundaryWithIdentifier:@"showSearchBarBoundry" fromPoint:CGPointMake(0, finalY) toPoint:CGPointMake(self.searchBar.bounds.size.width, finalY)];
        collisionBehavior.collisionDelegate = self;
        [_animator addBehavior:collisionBehavior];

        UIDynamicItemBehavior *elasticityBehavior =
                [[UIDynamicItemBehavior alloc] initWithItems:@[self.searchBar]];
        elasticityBehavior.elasticity = 0.3f;
        [_animator addBehavior:elasticityBehavior];
    }
}


- (void)didClickSearch:(id)sender {
    if (_isShowingSearchBar) {
        [self hideSearchBar];
    } else {
        [self showSearchBar];
    }
}

- (void)dynamicAnimatorDidPause:(UIDynamicAnimator *)animator {
    if (!self.searchBar.hidden) {
        [self.searchBar becomeFirstResponder];
    }
    _animator = nil;
}

#pragma mark HistoryViewControllerDelegate

- (void)standardMilestoneClicked:(StandardMilestone *)milestone {
    // This is a bug in the SWSwipeTableCell which fires both a short and long press gesture handler
    // events in row. The work around for now is to ignore any further touches until this view shows again.
    if (!_isMorganTouch) {
        _isMorganTouch = YES;
        [self createAchievementForMilestone:milestone];
        [self performSegueWithIdentifier:kDDSegueNoteMilestone sender:self];
    }
}

- (void)achievementClicked:(MilestoneAchievement *)achievement {
    // This is a bug in the SWSwipeTableCell which fires both a short and long press gesture handler
    // events in row. The work around for now is to ignore any further touches until this view shows again.
    if (!_isMorganTouch) {
        _isMorganTouch = YES;
        _currentAchievement = achievement;
        [self performSegueWithIdentifier:kDDSegueShowAchievementDetails sender:self];
    } else {
        NSLog(@"YOU GOT THE MORGAN TOUCH!!!!!");
    }

}

#pragma mark UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [UsageAnalytics trackSearch:searchBar.text];
    _historyController.filterString = searchBar.text;
    [searchBar resignFirstResponder]; // hide the keyboard
}

- (MilestoneAchievement *)createAchievementForMilestone:(StandardMilestone *)milestone {
    _currentAchievement = [MilestoneAchievement object];
    _currentAchievement.isSkipped = NO;
    _currentAchievement.isPostponed = NO;
    _currentAchievement.baby = Baby.currentBaby;
    _currentAchievement.completionDate = [NSDate date];
    if (milestone) _currentAchievement.standardMilestone = milestone;
    return _currentAchievement;
}

- (void)showAdIfNeeded {
    [FeatureManager ensureFeatureUnlocked:[[AdFreeFeature alloc] init] withBlock:^(BOOL purchased, NSError *error) {
        if (purchased) {
            if (_adView) {
                [_adView removeFromSuperview];
                _adView = nil;
            }
        } else {
            if (ParentUser.currentUser.launchCount > AD_TRIGGER_LAUNCH_COUNT) {
                if (!_dateLastAdShown || abs((int) _dateLastAdShown.timeIntervalSinceNow) > AD_TRIGGER_MAX_TIME) {
                    _dateLastAdShown = [NSDate date];
                    if (!_adView) {
                        _adView = [[DataParentingAdView alloc] initWithFrame:CGRectZero]; // adjust frame later
                        _adView.delegate = self;
                        _adView.containingViewController = self;
                        _adView.size = DataParentingAdViewSizeSmall;
                        _adView.layer.shadowColor = [UIColor blackColor].CGColor;
                        _adView.layer.shadowOpacity = 0.5;
                        _adView.hidden = YES;
                        [self.view addSubview:_adView];
                    }
                    [_adView attemptAdLoad];
                }
            }

        }
    }];
}

#pragma mark DataParentingAdViewDelegate

- (void)displayAdView {
    CGFloat y = self.tabBarController.tabBar.frame.origin.y - _adView.currentAdImageHeight;
    _adView.frame = CGRectMake(0, self.tabBarController.tabBar.frame.origin.y, _adView.currentAdImageWidth, _adView.currentAdImageHeight);
    _adView.hidden = NO;
    [UIView animateWithDuration:.5 animations:^{
        _adView.frame = CGRectMake(0, y, _adView.currentAdImageWidth, _adView.currentAdImageHeight);
    }                completion:^(BOOL finished) {
        [NSTimer scheduledTimerWithTimeInterval:AD_DISPLAY_TIME target:self selector:@selector(hideAdView) userInfo:nil repeats:NO];
    }];
}

- (void)hideAdView {
    CGFloat y = self.tabBarController.tabBar.frame.origin.y;
    [UIView animateWithDuration:.5 animations:^{
        _adView.frame = CGRectMake(0, y, _adView.currentAdImageWidth, _adView.currentAdImageHeight);
    }                completion:^(BOOL finished) {
        _adView.hidden = YES;
    }];
}

- (void)adClicked {
    [self hideAdView];
}


@end
