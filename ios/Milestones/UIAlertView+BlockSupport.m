//
//  UIAlertView+BlockSupport.m
//  Milestones
//
//  Created by Nathan  Pahucki on 6/5/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "objc/runtime.h"
#import "NSString+EmailAddress.h"

@implementation UIAlertView (BlockSupport)

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    UIAlertViewResultBlock block = objc_getAssociatedObject(self, @"block");
    block(buttonIndex);
}

- (void)showWithButtonBlock:(UIAlertViewResultBlock)block {
    objc_setAssociatedObject(self, @"block", block, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.delegate = self;
    [self show];
}

- (void)showEmailPromptWithBlock:(PFStringResultBlock)block {
    self.alertViewStyle = UIAlertViewStylePlainTextInput;
    __block UITextField *alertTextField = [self textFieldAtIndex:0];
    alertTextField.keyboardType = UIKeyboardTypeEmailAddress;
    alertTextField.placeholder = @"Email Address";
    [self showWithButtonBlock:^(NSInteger buttonIndex) {
        if (buttonIndex == 1) {
            if ([alertTextField.text isValidEmailAddress]) {
                block(alertTextField.text, nil);
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Whoops!" message:@"Please enter a valid email address." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] showWithButtonBlock:^(NSInteger buttonIndex2) {
                    [self showEmailPromptWithBlock:block];
                }];
            }
        } else {
            block(nil, nil);
        }
    }];
}


@end
