//
//  UIViewController+UIViewController_MBProgressHUD.m
//  Milestones
//
//  Created by Nathan  Pahucki on 4/23/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "UIViewController+MBProgressHUD.h"

@implementation UIViewController (UIViewController_MBProgressHUD)


- (MBProgressHUD *)hud {
    return [MBProgressHUD HUDForView:self.navigationController ? self.navigationController.view : self.view];
}

#pragma mark Custom HUD Methods.

- (void)showHUD:(BOOL)animated withDimmedBackground:(BOOL)dimmed {
    if (!self.hud) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController ? self.navigationController.view : self.view animated:animated];
        hud.animationType = MBProgressHUDAnimationFade;
        hud.completionBlock = nil;
    }
    self.hud.dimBackground = dimmed;
    [self.hud show:animated];
    self.hud.hidden = NO;
}

- (void)showHUDWithMessage:(NSString *)msg andAnimation:(BOOL)animated andDimmedBackground:(BOOL)dimmed {
    [self showHUD:animated withDimmedBackground:dimmed];
    self.hud.labelText = msg;
}

- (void)showInProgressHUDWithMessage:(NSString *)msg andAnimation:(BOOL)animated andDimmedBackground:(BOOL)dimmed {
    [self showHUDWithMessage:msg andAnimation:animated andDimmedBackground:dimmed];
    self.hud.mode = MBProgressHUDModeCustomView;
    self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage animatedImageNamed:@"progress-" duration:1.0f]];
}

- (void)showSuccessThenRunBlock:(dispatch_block_t)block {
    [self showHUD:NO withDimmedBackground:self.hud.dimBackground];
    UIImageView *animatedView = [self animatedImageView:@"success" frames:9];
    self.hud.customView = animatedView;
    self.hud.mode = MBProgressHUDModeCustomView;
    self.hud.completionBlock = block;
    [animatedView startAnimating];
    [self.hud hide:YES afterDelay:1.0f]; // when hidden will dismiss the dialog.
}

- (void)showErrorThenRunBlock:(NSError *)error withMessage:(NSString *)msg andBlock:(dispatch_block_t)block {
    [UsageAnalytics trackError:error forOperationNamed:@"SaveObject" andAdditionalProperties:@{@"errorMessage" : msg}];
    UIImageView *animatedView = [self animatedImageView:@"error" frames:9];
    self.hud.customView = animatedView;
    self.hud.mode = MBProgressHUDModeCustomView;
    if (msg) {
        self.hud.completionBlock = ^{
            // TODO: check for error 100 from Parse domain - this is internet connectivity error
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:msg message:error.localizedDescription delegate:nil cancelButtonTitle:@"Accept" otherButtonTitles:nil];
            [alert showWithButtonBlock:^(NSInteger buttonIndex) {
                block();
            }];
        };
    } else {
        self.hud.completionBlock = block;
    }
    [animatedView startAnimating];
    [self.hud hide:NO afterDelay:1.5]; // when hidden will dismiss the dialog.
}

- (UIImageView *)animatedImageView:(NSString *)imageName frames:(int)count {
    NSMutableArray *images = [[NSMutableArray alloc] initWithCapacity:count];
    for (int i = 0; i < count; i++) {
        [images addObject:[UIImage imageNamed:[NSString stringWithFormat:@"%@-%d.png", imageName, i]]];
    }
    UIImageView *view = [[UIImageView alloc] initWithImage:images[count - 1]];
    view.animationImages = images;
    view.animationDuration = .75;
    view.animationRepeatCount = 1;
    return view;

}


@end
