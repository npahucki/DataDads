//
//  FDTakeControllerNoStatusBar.m
//  Milestones
//
//  Created by Nathan  Pahucki on 4/9/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "FDTakeControllerNoStatusBar.h"

@implementation FDTakeControllerNoStatusBar


/**
 Simply hide the status bar for the view controller in the UIImagePicker. If this is not done, then the status bar is shown 
 and messes up the background image for the Nav Bar. 
**/
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
  [[UIApplication sharedApplication] setStatusBarHidden:YES];
  navigationController.navigationBar.barStyle = UIBarStyleDefault;
  navigationController.navigationBar.translucent = NO;
}

@end
