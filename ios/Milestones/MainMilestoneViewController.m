//
//  MainMilestoneViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 4/1/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "MainMilestoneViewController.h"
#import "OverviewViewController.h"
#import "NoteMilestoneViewController.h"
#import "AchievementDetailsViewController.h"
#import "Baby.h"
#import "UIImage+FX.h"
#import "NoConnectionAlertView.h"
#import "AlertThenDisappearView.h"

#define AD_TRIGGER_LAUNCH_COUNT 2
#define AD_TRIGGER_MAX_TIME 60 * 1
#define AD_DISPLAY_TIME 5


@implementation MainMilestoneViewController {
  MilestoneAchievement * _currentAchievment;
  HistoryViewController * _historyController;
  BOOL _isMorganTouch;
  BOOL _isShowingSearchBar;
  UIDynamicAnimator * _animator;
  NoConnectionAlertView * _noConnectionAlert;
  DataParentingAdView *_adView;
  NSDate * _dateLastAdShown;
}


-(void) viewDidLoad {
  [super viewDidLoad];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(babyUpdated:) name:kDDNotificationCurrentBabyChanged object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(milestoneNotedAndSaved:) name:kDDNotificationMilestoneNotedAndSaved object:nil];

  [NoConnectionAlertView createInstanceForController:self];

  _adView = [[DataParentingAdView alloc] initWithFrame:CGRectZero]; // adjust frame later
  _adView.delegate = self;
  _adView.containingViewController = self;
  _adView.size = DataParentingAdViewSizeMedium;
  _adView.layer.shadowColor = [UIColor blackColor].CGColor;
  _adView.layer.shadowOpacity = 0.5;
  [self.view addSubview:_adView];

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

-(void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  self.addMilestoneButton.enabled = Baby.currentBaby != nil;
  self.menuButton.enabled = Baby.currentBaby != nil;
  _isMorganTouch = NO; // Hack work around a double segue bug, caused by touching the cell too long
  
  [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(showAdIfNeeded) userInfo:nil repeats:YES];

}

-(void) milestoneNotedAndSaved:(NSNotification*)notification {
  MilestoneAchievement * achievement = notification.object;
  [achievement calculatePercentileRankingWithBlock:^(float percentile) {
    if(percentile >= 0) {
      AlertThenDisappearView * alert = [AlertThenDisappearView instanceForViewController:self];
      NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:Baby.currentBaby.name attributes:@{NSFontAttributeName : [UIFont fontForAppWithType:Bold andSize:13]}];
      [string appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" is ahead of %.02f%% of other babies for that milestone so far.",percentile] attributes:@{NSFontAttributeName : [UIFont fontForAppWithType:Medium andSize:13]}]];
      alert.titleLabel.font = nil; // Must clear this because it is set as part of UILabel's appearance.
      alert.titleLabel.attributedText = string;
      alert.imageView.image = [UIImage imageNamed:@"completedBest"];
      [alert showWithDelay:3];
    }
  }];
}

-(void) babyUpdated:(NSNotification*)notification {
  Baby * baby = Baby.currentBaby;
  self.addMilestoneButton.enabled = baby != nil;
  self.menuButton.enabled = baby != nil;
  
  PFFile * imageFile = baby.avatarImageThumbnail ? baby.avatarImageThumbnail : baby.avatarImage;
  if(imageFile) {
    [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
      if(!error) {
        UIImage * image = [[UIImage alloc] initWithData:data];
        if(image) {
          [self.babyMenuButton setImage:image forState:UIControlStateNormal];
          [self.babyMenuButton setImage: [image imageWithAlpha:.70] forState:UIControlStateHighlighted];
          self.babyMenuButton.layer.borderColor = [UIColor appNormalColor].CGColor;

          CALayer *innerShadowLayer = [CALayer layer];
          innerShadowLayer.contents = (id)[UIImage imageNamed: @"avatarButtonShadow"].CGImage;
          innerShadowLayer.contentsCenter = CGRectMake(10.0f/21.0f, 10.0f/21.0f, 1.0f/21.0f, 1.0f/21.0f);
          innerShadowLayer.frame = CGRectInset(self.babyMenuButton.bounds, 2.5,2.5);
          [self.babyMenuButton.layer addSublayer:innerShadowLayer];
          self.babyMenuButton.layer.borderWidth = 3;
          self.babyMenuButton.layer.cornerRadius = self.babyMenuButton.bounds.size.width / 2 ;
          self.babyMenuButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
          self.babyMenuButton.clipsToBounds = YES;
          self.babyMenuButton.showsTouchWhenHighlighted = YES;
        }
      }
    }];
  }
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  // Embedded table
  if([segue.destinationViewController isKindOfClass:[HistoryViewController class]]) {
    _historyController = ((HistoryViewController*)segue.destinationViewController);
    _historyController.delegate = self;
    return;
  } else if([segue.identifier isEqualToString:kDDSegueShowSettings]) {
    ((OverviewViewController *)[((UINavigationController *)segue.destinationViewController) childViewControllers][0]).milestoneCount = _historyController.model.countOfAchievements;
  }

  
  // Navigation Segues
  if([segue.identifier isEqualToString:kDDSegueNoteMilestone] || [segue.identifier isEqualToString:kDDSegueNoteCustomMilestone]) {
    if([segue.identifier isEqualToString:kDDSegueNoteCustomMilestone]) {
      [self createAchievementForMilestone:nil];
    }
    NSAssert(_currentAchievment, @"Expected currentAchievement to be set");
    [self hideSearchBar];
    NoteMilestoneViewController* noteMilestoneViewController =  (NoteMilestoneViewController*)
    ((UINavigationController*)segue.destinationViewController ).visibleViewController;
    noteMilestoneViewController.achievement = _currentAchievment;
  } else if([segue.identifier isEqualToString:kDDSegueShowAchievementDetails]) {
    ((AchievementDetailsViewController*)segue.destinationViewController).achievement = _currentAchievment;
  }
}

-(void) hideSearchBar {
  if(_isShowingSearchBar ) {
    self.searchButton.image = [UIImage imageNamed:@"searchButton"];
    [self.searchBar resignFirstResponder];
    _historyController.filterString = nil;
    int finalY = self.navigationController.navigationBar.bounds.size.height + self.searchBar.bounds.size.height;
    _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    UIGravityBehavior* gravityBehavior = [[UIGravityBehavior alloc] initWithItems:@[self.searchBar]];
    gravityBehavior.magnitude = -2.0;
    [_animator addBehavior:gravityBehavior];
    
    UICollisionBehavior* collisionBehavior =
    [[UICollisionBehavior alloc] initWithItems:@[ self.searchBar]];
    collisionBehavior.translatesReferenceBoundsIntoBoundary = NO;
    [collisionBehavior addBoundaryWithIdentifier:@"hideSearchBarBoundry" fromPoint:CGPointMake(0, -finalY) toPoint:CGPointMake(self.searchBar.bounds.size.width, -finalY)];
    collisionBehavior.collisionDelegate = self;
    [_animator addBehavior:collisionBehavior];
  }
}

- (void)collisionBehavior:(UICollisionBehavior*)behavior endedContactForItem:(id <UIDynamicItem>)item withBoundaryIdentifier:(id <NSCopying>)identifier {
  if([@"hideSearchBarBoundry" isEqual:identifier]) {
    self.searchBar.hidden = YES;
    self.searchBar.text = nil;
    _isShowingSearchBar = NO;
  } else if([@"showSearchBarBoundry" isEqual:identifier]) {
    //[self.searchBar becomeFirstResponder];
  }
}

-(void) showSearchBar {
  int finalY = self.navigationController.navigationBar.bounds.size.height + self.searchBar.bounds.size.height;
  if(!_isShowingSearchBar) {
    // Start it up above the frame so it can fall down.
    self.searchButton.image = [UIImage imageNamed:@"searchButton_active"];
    self.searchBar.frame = CGRectMake(self.searchBar.frame.origin.x, -finalY, self.searchBar.frame.size.width, self.searchBar.frame.size.height);
    self.searchBar.hidden = NO;
    _isShowingSearchBar = YES;
    _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    UIGravityBehavior* gravityBehavior = [[UIGravityBehavior alloc] initWithItems:@[self.searchBar]];
    gravityBehavior.magnitude = 2.0;
    [_animator addBehavior:gravityBehavior];
    
    UICollisionBehavior* collisionBehavior =
    [[UICollisionBehavior alloc] initWithItems:@[ self.searchBar]];
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
  if(_isShowingSearchBar ) {
    [self hideSearchBar];
  } else {
    [self showSearchBar];
  }
}

#pragma mark HistoryViewControllerDelegate

-(void) standardMilestoneClicked:(StandardMilestone*) milestone {
  // TODO: Find the cause of this bug: If you click for a longer time on the tablecell, it somehow triggers two rapid
  // events in row. I think this is caused by a bug in the Swipable Table Cell we are using. The work around for now
  // is to ignore any further touches until this view shows again.
  if(!_isMorganTouch) {
    _isMorganTouch = YES;
    [self createAchievementForMilestone:milestone];
    [self performSegueWithIdentifier:kDDSegueNoteMilestone sender:self];
  } else {
    // TODO: Log this to somewhere to see how many people have the morgan touch.
    NSLog(@"YOU GOT THE MORGAN TOUCH!!!!!");
  }
}

-(void) achievementClicked:(MilestoneAchievement*) achievement {
  if(!_isMorganTouch) {
    _isMorganTouch = YES;
    _currentAchievment = achievement;
    [self performSegueWithIdentifier:kDDSegueShowAchievementDetails sender:self];
  } else {
    // TODO: Log this to somewhere to see how many people have the morgan touch.
    NSLog(@"YOU GOT THE MORGAN TOUCH!!!!!");
  }
  
}

#pragma mark UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
  [UsageAnalytics trackSearch:searchBar.text];
  _historyController.filterString = searchBar.text;
  [searchBar resignFirstResponder]; // hide the keyboard
}

-(MilestoneAchievement*) createAchievementForMilestone:(StandardMilestone*) milestone {
  _currentAchievment = [MilestoneAchievement object];
  _currentAchievment.isSkipped = NO;
  _currentAchievment.isPostponed = NO;
  _currentAchievment.baby = Baby.currentBaby;
  _currentAchievment.completionDate =  [NSDate date];
  if(milestone) _currentAchievment.standardMilestone = milestone;
  return _currentAchievment;
}

-(void) showAdIfNeeded {
  if(ParentUser.currentUser.launchCount > AD_TRIGGER_LAUNCH_COUNT) {
    if(!_dateLastAdShown || abs(_dateLastAdShown.timeIntervalSinceNow) > AD_TRIGGER_MAX_TIME) {
      [_adView attemptAdLoad];
    }
  }
}

#pragma mark DataParentingAdViewDelegate

-(void) displayAdView {
  CGFloat x = arc4random_uniform(2) ? -_adView.currentAdImageWidth : _adView.currentAdImageWidth;
  CGFloat y = arc4random_uniform(2) ? -_adView.currentAdImageHeight : _adView.currentAdImageHeight;
  _adView.alpha = 1.0;
  _adView.frame = CGRectMake(x,y,_adView.currentAdImageWidth, _adView.currentAdImageHeight);
  _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
  UISnapBehavior *snap = [[UISnapBehavior alloc] initWithItem:_adView snapToPoint:self.view.center];
  [snap setDamping:0.5];
  [_animator addBehavior:snap];
  [NSTimer scheduledTimerWithTimeInterval:AD_DISPLAY_TIME target:self selector:@selector(hideAdView) userInfo:nil repeats:NO];
  _dateLastAdShown = [NSDate date];
}

-(void) hideAdView {
  [UIView animateWithDuration:.5 animations:^{
    _adView.alpha = 0.0;
  }];
}

-(void) adClicked {
  [self hideAdView];
}


@end
