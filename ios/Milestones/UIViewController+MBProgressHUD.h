//
//  UIViewController+UIViewController_MBProgressHUD.h
//  Milestones
//
//  Created by Nathan  Pahucki on 4/23/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

/**
Provides a few common methods for working with MBProgressHUDs.
This is any ViewController that may need to show some progress at some point
and should use the standard app defined progress indicator.
**/
@interface UIViewController (UIViewController_MBProgressHUD)

- (void)showHUD:(BOOL)animated withDimmedBackground:(BOOL)dimmed;

- (void)showHUDWithMessage:(NSString *)msg andAnimation:(BOOL)animated andDimmedBackground:(BOOL)dimmed;

- (void)showInProgressHUDWithMessage:(NSString *)msg andAnimation:(BOOL)animated andDimmedBackground:(BOOL)dimmed;

- (void)showSuccessThenRunBlock:(dispatch_block_t)block;

- (void)showErrorThenRunBlock:(NSError *)error withMessage:(NSString *)msg andBlock:(dispatch_block_t)block;


@end


