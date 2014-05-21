//
//  MainMilestoneViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 4/1/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "MainMilestoneViewController.h"
#import "SettingsViewController.h"
#import "NoteMilestoneViewController.h"



@implementation MainMilestoneViewController {
  MilestoneAchievement * _currentAchievment;
  HistoryViewController * _historyController;
  BOOL _isMorganTouch;
}


-(void) viewDidLoad {
  [super viewDidLoad];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(babyUpdated:) name:kDDNotificationCurrentBabyChanged object:nil];
  self.navigationItem.title = Baby.currentBaby.name;
}

-(void) viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  self.addMilestoneButton.enabled = Baby.currentBaby != nil;
  self.menuButton.enabled = Baby.currentBaby != nil;
  _isMorganTouch = NO; // Hack work around a double segue bug, caused by touching the cell too long
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
    ((NoteMilestoneViewController*)segue.destinationViewController).achievement = _currentAchievment;
  } else if([segue.identifier isEqualToString:kDDSegueShowAchievementDetails]) {
    // TODO: Set Achievement
    //    ((MilestoneDetailsViewController*)segue.destinationViewController).achievement = _currentAchievment;
  }/* else if([segue.identifier isEqualToString:kDDSegueCreateCustomMilestone]) {
    ((NoteMilestoneViewController*)segue.destinationViewController).achievement = _currentAchievment;

    
    //((CreateMilestoneViewController*)segue.destinationViewController).achievement = [self createAchievementForMilestone:nil];
  }*/
}
- (IBAction)didClickAddNewMilestone:(id)sender {
  // Create an achievement with no milestone 
  [self createAchievementForMilestone:nil];
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
    [self performSegueWithIdentifier:kDDSegueShowAchievementDetails sender:self];
  } else {
    // TODO: Log this to somewhere to see how many people have the morgan touch.
    NSLog(@"YOU GOT THE MORGAN TOUCH!!!!!");
  }
  
}

# pragma mark - Private

//-(void) logCurrentAchievement {
//  NSAssert(_currentAchievment,@"Expected current acheivement to be set!");
//  [self showInProgressHUDWithMessage:@"Making it so.." andAnimation:YES andDimmedBackground:YES];
//  [_currentAchievment saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
//    if(succeeded) {
//      [self showSuccessThenRunBlock:nil];
//      // Note, firing the event, may make the progress dialog disappear before the animation completes.
//      [[NSNotificationCenter defaultCenter] postNotificationName:kDDNotificationMilestoneNotedAndSaved object:self userInfo:@{@"" : _currentAchievment}];
//      _currentAchievment = nil;
//    } else {
//      [self showErrorThenRunBlock:error withMessage:@"Could not note ignore/postpone" andBlock:nil];
//    }
//  }];
//}

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
