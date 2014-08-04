//
//  UIViewControllerWithHUDProgressViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 2/7/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "UIViewControllerWithHUDProgress.h"

@interface UIViewControllerWithHUDProgress ()

@end

@implementation UIViewControllerWithHUDProgress

- (void)saveObject:(PFObject *)object withTitle:(NSString *)title andFailureMessage:(NSString *)msg andBlock:(PFBooleanResultBlock)block {
    [self showInProgressHUDWithMessage:title andAnimation:YES andDimmedBackground:YES];
    [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error) {
            [self showErrorThenRunBlock:error withMessage:msg andBlock:^{
                if (block) block(NO, error);
            }];
        } else {
            [self showSuccessThenRunBlock:^{
                if (block) block(YES, error);
            }];
        }
    }];
}

- (void)dismiss {
    if (self.navigationController) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    } else {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
