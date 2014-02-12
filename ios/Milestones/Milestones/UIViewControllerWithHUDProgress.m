//
//  UIViewControllerWithHUDProgressViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 2/7/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "UIViewControllerWithHUDProgress.h"

@interface UIViewControllerWithHUDProgress ()

@end

@implementation UIViewControllerWithHUDProgress

-(void) showHUDWithMessage:(NSString*) msg andAnimation:(BOOL) animated {
  [self showHUD:animated];
  self.hud.labelText = msg;
}

-(void) showHUD: (BOOL) animated {
  if(!self.hud) {
    self.hud = [MBProgressHUD showHUDAddedTo:self.navigationController ? self.navigationController.view : self.view animated:animated];
    self.hud.animationType = MBProgressHUDAnimationFade;
    self.hud.dimBackground = YES;
  }
  if(self.hud.hidden) {
    [self.hud show:animated];
  }
}

-(void) saveObject:(PFObject*) object withTitle:(NSString*) title andFailureMessage:(NSString*)msg {
  [self showHUDWithMessage:title andAnimation:NO];
  self.hud.mode = MBProgressHUDModeIndeterminate;
  [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
    if(succeeded) {
      [self showSaveSuccessAndDismissDialog];
    } else {
      [self showSaveError:error withMessage:msg];
    }
  }];
}

-(void) showSaveSuccessAndDismissDialog {
  [self showHUD:NO];
  self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
  self.hud.mode = MBProgressHUDModeCustomView;
  UIViewControllerWithHUDProgress * me = self; // needed to prevent circular refs
  self.hud.completionBlock = ^{
    [me dismiss];
  };
  [self.hud hide:YES afterDelay:.5]; // when hidden will dismiss the dialog.
}

-(void) dismiss {
  if(self.navigationController) {
    [self.navigationController popToRootViewControllerAnimated:YES];
  } else {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
  }
}

-(void) showSaveError:(NSError*) error withMessage:(NSString*) msg {
  NSLog(@"%@ caused by %@", msg, error);
  [self.hud hide:NO];
  NSString * fullMsg = [NSString stringWithFormat:@"%@ Please make sure that you are conencted to a network and try again.",msg];
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"There is a small problem..." message:fullMsg delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
  [alert show];
}

-(void) showGeneralAlert:(NSString*) title withMessage:(NSString*) msg {
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
  [alert show];
}

@end
