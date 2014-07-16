//
//  UIAlertView+BlockSupport.m
//  Milestones
//
//  Created by Nathan  Pahucki on 6/5/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "objc/runtime.h"

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


@end
