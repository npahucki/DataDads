//
//  LoginViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 1/21/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "MBProgressHUD.h"

@interface LoginViewController : PFLogInViewController<PFLogInViewControllerDelegate,PFSignUpViewControllerDelegate>

@property (nonatomic, strong) UIImageView * orSep;
@property (nonatomic, strong) UIView * signupSep;
@property (nonatomic, strong) UIDynamicAnimator* animator;
@property (nonatomic, strong) MBProgressHUD * hud;


@end
