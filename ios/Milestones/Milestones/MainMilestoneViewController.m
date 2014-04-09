//
//  MainMilestoneViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 4/1/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "MainMilestoneViewController.h"
#import "CreateMilestoneViewController.h"
#import "SettingsViewController.h"

@implementation MainMilestoneViewController


-(void) viewDidLoad {
  [super viewDidLoad];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(babyUpdated:) name:kDDNotificationCurrentBabyChanged object:nil];
  self.babyNameLabel.font =  [UIFont fontWithName:@"GothamRounded-Bold" size:21.0];
  self.babyNameLabel.text = nil; // remove place holder text
}

-(void) babyUpdated:(NSNotification*)notification {
  self.babyNameLabel.text = Baby.currentBaby.name;
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  MilestoneAchievement * achievement = [MilestoneAchievement object];
  achievement.baby = Baby.currentBaby;
  if([segue.identifier isEqualToString:kDDSegueCreateCustomMilestone]) {
    ((CreateMilestoneViewController*)segue.destinationViewController).achievement = achievement;
  }
}

-(void) bounceAddButton {
  CAKeyframeAnimation *animation = [self jumpAnimation];
	animation.duration = 1.5;
  animation.repeatCount = 3;
	[self.addMilestoneButton.layer addAnimation:animation forKey:@"jumping"];
}

- (CAKeyframeAnimation *)jumpAnimation
{
	// these three values are subject to experimentation
	CGFloat initialMomentum = 250.0f; // positive is upwards, per sec
	CGFloat gravityConstant = 250.0f; // downwards pull per sec
	CGFloat dampeningFactorPerBounce = 0.6;  // percent of rebound
  
	// internal values for the calculation
	CGFloat momentum = initialMomentum; // momentum starts with initial value
	CGFloat positionOffset = 0; // we begin at the original position
	CGFloat slicesPerSecond = 60.0f; // how many values per second to calculate
	CGFloat lowerMomentumCutoff = 3.0f; // below this upward momentum animation ends
  
	CGFloat duration = 0;
	NSMutableArray *values = [NSMutableArray array];
  
	do
	{
		duration += 1.0f/slicesPerSecond;
		positionOffset+=momentum/slicesPerSecond;
    
		if (positionOffset<0)
		{
			positionOffset=0;
			momentum=-momentum*dampeningFactorPerBounce;
		}
    
		// gravity pulls the momentum down
		momentum -= gravityConstant/slicesPerSecond;
    
		CATransform3D transform = CATransform3DMakeTranslation(0, -positionOffset, 0);
		[values addObject:[NSValue valueWithCATransform3D:transform]];
	} while (!(positionOffset==0 && momentum < lowerMomentumCutoff));
  
	CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
	animation.repeatCount = 1;
	animation.duration = duration;
	animation.fillMode = kCAFillModeForwards;
	animation.values = values;
	animation.removedOnCompletion = YES; // final stage is equal to starting stage
	animation.autoreverses = NO;
  
	return animation;
}

@end
