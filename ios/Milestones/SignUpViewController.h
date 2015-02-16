//
//  SignupViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 4/18/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "MBProgressHUD.h"

@interface SignUpViewController : UIViewController <UITextFieldDelegate>

@property BOOL showExternal;
@property (weak, nonatomic) IBOutlet UIButton *loginWithFacebookButton;
@property (weak, nonatomic) IBOutlet UILabel *orSepLabel;
@property (weak, nonatomic) IBOutlet UITextField *emailAddressTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *signupButton;

+ (void)presentInController:(UIViewController *)vc andRunBlock:(PFBooleanResultBlock)block;

@end

