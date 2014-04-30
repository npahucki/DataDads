//
//  UIViewController+UIViewController_MBProgressHUD.m
//  Milestones
//
//  Created by Nathan  Pahucki on 4/23/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "UIViewController+MBProgressHUD.h"

@interface UIAlertViewWrapper : NSObject

@property (copy) void(^block)();


@end

@implementation UIAlertViewWrapper

- (void)alertViewCancel:(UIAlertView *)alertView {
  self.block();
}

@end


@implementation UIViewController (UIViewController_MBProgressHUD)

#pragma mark Custom HUD Methods.

-(void) showHUD: (BOOL) animated withDimmedBackground: (BOOL) dimmed {
  if(!_hud) {
    _hud = [MBProgressHUD showHUDAddedTo:self.navigationController ? self.navigationController.view : self.view animated:animated];
    _hud.animationType = MBProgressHUDAnimationFade;
    _hud.dimBackground = dimmed;
    _hud.completionBlock = nil;
  }
  [_hud show:animated];
  _hud.hidden = NO;
}

-(void) showHUDWithMessage:(NSString*) msg andAnimation:(BOOL) animated andDimmedBackground: (BOOL) dimmed {
  [self showHUD:animated withDimmedBackground:dimmed];
  _hud.labelText = msg;
}

-(void) showInProgressHUDWithMessage:(NSString*) msg andAnimation:(BOOL) animated andDimmedBackground: (BOOL) dimmed {
  [self showHUDWithMessage:msg andAnimation:animated andDimmedBackground:dimmed];
  _hud.mode = MBProgressHUDModeCustomView;
  _hud.customView =  [[UIImageView alloc] initWithImage:[UIImage animatedImageNamed:@"progress-" duration:1.0f]];
}

-(void) showSuccessThenRunBlock:(dispatch_block_t)block {
  [self showHUD:NO withDimmedBackground:_hud.dimBackground];
  UIImageView * animatedView = [self animatedImageView:@"success" frames:9];
  _hud.customView = animatedView;
  _hud.mode = MBProgressHUDModeCustomView;
  _hud.completionBlock = block;
  [animatedView startAnimating];
  [_hud hide:YES afterDelay:1.0f]; // when hidden will dismiss the dialog.
}

-(void) showErrorThenRunBlock:(NSError*) error withMessage:(NSString*) msg andBlock:(dispatch_block_t)block {
  NSLog(@"%@ caused by %@", msg ? msg : @"?", error);
  UIImageView * animatedView = [self animatedImageView:@"error" frames:9];
  _hud.customView = animatedView;
  _hud.mode = MBProgressHUDModeCustomView;
  if(msg) {
      _hud.completionBlock = ^{
        UIAlertViewWrapper * wrapper = [[UIAlertViewWrapper alloc] init];
        wrapper.block = block;
        // TODO: check for error 100 from Parse domain - this is internet connectivity error
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:msg message:error.localizedDescription delegate:wrapper cancelButtonTitle:@"Accept" otherButtonTitles:nil];
        [alert show];
      };
  } else {
    _hud.completionBlock = block;
  }
  [animatedView startAnimating];
  [_hud hide:NO afterDelay:1.5]; // when hidden will dismiss the dialog.
}

-(UIImageView*) animatedImageView:(NSString*) imageName frames:(int) count {
  NSMutableArray * images = [[NSMutableArray alloc] initWithCapacity:count];
  for(int i=0; i<count; i++) {
    [images addObject:[UIImage imageNamed:[NSString stringWithFormat:@"%@-%d.png",imageName, i]]];
  }
  UIImageView* view = [[UIImageView alloc] initWithImage:images[count - 1]];
  view.animationImages = images;
  view.animationDuration = .75;
  view.animationRepeatCount = 1;
  return view;
  
}


@end
