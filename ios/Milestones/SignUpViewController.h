//
//  SignupViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 4/18/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <Parse/Parse.h>
#import <Parse/PF_MBProgressHUD.h>
#import "MBProgressHUD.h"

@interface SignUpViewController : PFSignUpViewController <PF_MBProgressHUDDelegate, PFSignUpViewControllerDelegate>

@property(nonatomic, strong) MBProgressHUD *hud;
@property(nonatomic, strong) UIImageView *orSep;
@property(nonatomic, strong) UILabel *orLabel;
@property(nonatomic, strong) UIView *signupSep;
@property(nonatomic, strong) UIButton *facebookButton;
@property(nonatomic, strong) NSArray *facebookPermissions;
@property BOOL showExternal;

- (void)showStartSignUpProgress;

- (void)showSignupSuccessAndRunBlock:(dispatch_block_t)block;

- (void)showSignupError:(NSError *)error withMessage:(NSString *)msg;

@end

