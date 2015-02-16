//
//  SignupViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 4/18/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "MBProgressHUD.h"

@interface SignUpOrLoginViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIButton *loginWithFacebookButton;
@property (weak, nonatomic) IBOutlet UILabel *orSepLabel;
@property (weak, nonatomic) IBOutlet UITextField *emailAddressTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property(weak, nonatomic) IBOutlet UIButton *actionButton;
@property(weak, nonatomic) IBOutlet UIButton *forgotPasswordButton;
@property(weak, nonatomic) IBOutlet UILabel *titleLabel;

// YES will show buttons for login, and NO (default) will show buttons for signup.
@property BOOL loginMode; // Should be set before viewDidLoad!

+ (void)presentSignUpInController:(UIViewController *)vc andRunBlock:(PFBooleanResultBlock)block;

@end

