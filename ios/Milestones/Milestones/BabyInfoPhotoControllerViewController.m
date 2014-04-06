//
//  BabyInfoPhotoControllerViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 4/5/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "BabyInfoPhotoControllerViewController.h"

@interface BabyInfoPhotoControllerViewController ()

@end

@implementation BabyInfoPhotoControllerViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.theLabel.font = [UIFont fontWithName:@"GothamRounded-Light" size:31.0];
}

-(void) viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [UIButton animateWithDuration:1.0 delay:1.0 options:
   UIViewAnimationOptionAllowUserInteraction| UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse
                     animations:^{
                       self.takePhotoButton.transform = CGAffineTransformScale(self.takePhotoButton.transform, 0.95, 0.95);
                     } completion:^(BOOL finished) {
                       
                     }];

}


-(void) viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
}

- (IBAction)didClickPhotoButton:(id)sender {



}

- (IBAction)didClickDoneButton:(id)sender {

}


@end
