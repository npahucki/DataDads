//
//  SignupViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 4/18/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <Parse/Parse.h>
#import <Parse/PF_MBProgressHUD.h>
#import "MBProgressHUD.h"

@interface SignUpViewController : PFSignUpViewController <PF_MBProgressHUDDelegate>

@property (nonatomic, strong) MBProgressHUD * hud;

-(void) showStartSignUpProgress;

-(void) showSignupSuccessAndRunBlock:(dispatch_block_t)block;

-(void) showSignupError:(NSError*) error withMessage:(NSString*) msg;

@end

