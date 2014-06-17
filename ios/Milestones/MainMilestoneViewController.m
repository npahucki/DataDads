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



@implementation MainMilestoneViewController {
  MilestoneAchievement * _currentAchievment;
  HistoryViewController * _historyController;
  BOOL _isMorganTouch;
  BOOL _isShowingSearchBar;
  UIDynamicAnimator * _animator;
  
}


-(void) viewDidLoad {
  [super viewDidLoad];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(babyUpdated:) name:kDDNotificationCurrentBabyChanged object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(milestoneNotedAndSaved:) name:kDDNotificationMilestoneNotedAndSaved object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkReachabilityChanged:) name:kReachabilityChangedNotification object:nil];
  self.navigationItem.title = Baby.currentBaby.name;
  
  
  UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(hideSearchBar)];
  swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
  [self.searchBar addGestureRecognizer:swipeUp];
}

-(void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kDDNotificationMilestoneNotedAndSaved object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kDDNotificationCurrentBabyChanged object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

-(void) viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  self.addMilestoneButton.enabled = Baby.currentBaby != nil;
  self.menuButton.enabled = Baby.currentBaby != nil;
  _isMorganTouch = NO; // Hack work around a double segue bug, caused by touching the cell too long
}

-(void) networkReachabilityChanged:(NSNotification*)notification {
  if([Reachability isParseCurrentlyReachable]) {
    self.warningMsgButton.hidden = YES;
  } else {
    [self.warningMsgButton setTitle:@"Warning: there is no network connection" forState:UIControlStateNormal];
    [self.warningMsgButton setImage:[UIImage imageNamed:@"error-9"] forState:UIControlStateNormal];
    [self showWarningWindowAnimated];
  }
}

-(void) milestoneNotedAndSaved:(NSNotification*)notification {
  MilestoneAchievement * achievement = notification.object;
  [achievement calculatePercentileRankingWithBlock:^(float percentile) {
    if(percentile >= 0) {
      // Show the message once all the animations have settled down.
      [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(showWarningWindowAnimated) userInfo:nil repeats:false];
      [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(hideWarningWindowAnimated) userInfo:nil repeats:false];
      NSString * msg = [NSString stringWithFormat:@"%@ is ahead of %.02f%% of other babies for that milestone so far.", Baby.currentBaby.name,percentile];
      [self.warningMsgButton setTitle:msg forState:UIControlStateNormal];
      [self.warningMsgButton setImage:[UIImage imageNamed:@"success-8"] forState:UIControlStateNormal];
    }
  }];
}

-(void) babyUpdated:(NSNotification*)notification {
  self.addMilestoneButton.enabled = Baby.currentBaby != nil;
  self.menuButton.enabled = Baby.currentBaby != nil;
  self.navigationItem.title = Baby.currentBaby.name;
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  // Embedded table
  if([segue.destinationViewController isKindOfClass:[HistoryViewController class]]) {
    _historyController = ((HistoryViewController*)segue.destinationViewController);
    _historyController.delegate = self;
    return;
  }
  
  // Navigation Segues
  if([segue.identifier isEqualToString:kDDSegueNoteMilestone]) {
    NSAssert(_currentAchievment, @"Expected currentAchievement to be set");
    [self hideSearchBar];
    NoteMilestoneViewController* noteMilestoneViewController =  (NoteMilestoneViewController*)
    ((UINavigationController*)segue.destinationViewController ).visibleViewController;
    noteMilestoneViewController.achievement = _currentAchievment;
  } else if([segue.identifier isEqualToString:kDDSegueShowAchievementDetails]) {
    ((AchievementDetailsViewController*)segue.destinationViewController).achievement = _currentAchievment;
  }
}
- (IBAction)didClickAddNewMilestone:(id)sender {
  // Create an achievement with no milestone
  [self createAchievementForMilestone:nil];
}

-(void) hideSearchBar {
  if(_isShowingSearchBar ) {
    [self.searchBar resignFirstResponder];
    _historyController.filterString = nil;
    int finalY = self.navigationController.navigationBar.bounds.size.height + self.searchBar.bounds.size.height;
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor appNormalColor];
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
    self.searchBar.frame = CGRectMake(self.searchBar.frame.origin.x, -finalY, self.searchBar.frame.size.width, self.searchBar.frame.size.height);
    self.searchBar.hidden = NO;
    _isShowingSearchBar = YES;
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor appSelectedColor];
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


- (IBAction)didClickSearch:(id)sender {
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
  _historyController.filterString = searchBar.text;
  [searchBar resignFirstResponder]; // hide the keyboard
}

# pragma mark - Private

-(void) hideWarningWindowAnimated {
  if(!self.warningMsgButton.hidden) {
    [UIView transitionWithView:self.warningMsgButton
                      duration:1.0
                       options:UIViewAnimationOptionTransitionFlipFromBottom
                    animations:NULL
                    completion:nil];
    self.warningMsgButton.hidden = YES;
  }
}

-(void) showWarningWindowAnimated {
  if(self.warningMsgButton.hidden) {
    [UIView transitionWithView:self.warningMsgButton
                      duration:1.0
                       options:UIViewAnimationOptionTransitionFlipFromBottom
                    animations:NULL
                    completion:nil];
    self.warningMsgButton.hidden = NO;
  }
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




//-(void) bounceAddButton {
//  CAKeyframeAnimation *animation = [self jumpAnimation];
//	animation.duration = 1.5;
//  animation.repeatCount = 3;
//	[self.addMilestoneButton.layer addAnimation:animation forKey:@"jumping"];
//}
//
//- (CAKeyframeAnimation *)jumpAnimation
//{
//	// these three values are subject to experimentation
//	CGFloat initialMomentum = 250.0f; // positive is upwards, per sec
//	CGFloat gravityConstant = 250.0f; // downwards pull per sec
//	CGFloat dampeningFactorPerBounce = 0.6;  // percent of rebound
//  
//	// internal values for the calculation
//	CGFloat momentum = initialMomentum; // momentum starts with initial value
//	CGFloat positionOffset = 0; // we begin at the original position
//	CGFloat slicesPerSecond = 60.0f; // how many values per second to calculate
//	CGFloat lowerMomentumCutoff = 3.0f; // below this upward momentum animation ends
//  
//	CGFloat duration = 0;
//	NSMutableArray *values = [NSMutableArray array];
//  
//	do
//	{
//		duration += 1.0f/slicesPerSecond;
//		positionOffset+=momentum/slicesPerSecond;
//    
//		if (positionOffset<0)
//		{
//			positionOffset=0;
//			momentum=-momentum*dampeningFactorPerBounce;
//		}
//    
//		// gravity pulls the momentum down
//		momentum -= gravityConstant/slicesPerSecond;
//    
//		CATransform3D transform = CATransform3DMakeTranslation(0, -positionOffset, 0);
//		[values addObject:[NSValue valueWithCATransform3D:transform]];
//	} while (!(positionOffset==0 && momentum < lowerMomentumCutoff));
//  
//	CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
//	animation.repeatCount = 1;
//	animation.duration = duration;
//	animation.fillMode = kCAFillModeForwards;
//	animation.values = values;
//	animation.removedOnCompletion = YES; // final stage is equal to starting stage
//	animation.autoreverses = NO;
//  
//	return animation;
//}

@end
