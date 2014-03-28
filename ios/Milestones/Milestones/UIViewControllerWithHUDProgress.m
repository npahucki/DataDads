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
  //if(self.hud.hidden) {
    [self.hud show:animated];
  //}
}

-(void) saveObject:(PFObject*) object withTitle:(NSString*) title andFailureMessage:(NSString*)msg {
  [self showHUDWithMessage:title andAnimation:NO];
  self.hud.mode = MBProgressHUDModeCustomView;
  self.hud.customView =  [[UIImageView alloc] initWithImage:[UIImage animatedImageNamed:@"progress-" duration:1.0f]];
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
  UIImageView * animatedView = [self animatedImageView:@"success" frames:9];
  self.hud.customView = animatedView;
  [animatedView startAnimating];
  self.hud.mode = MBProgressHUDModeCustomView;
  UIViewControllerWithHUDProgress * me = self; // needed to prevent circular refs
  self.hud.completionBlock = ^{
    [me dismiss];
  };
  [self.hud hide:YES afterDelay:1.0f]; // when hidden will dismiss the dialog.
}

-(void) dismiss {
  if(self.navigationController) {
    [self.navigationController popToRootViewControllerAnimated:YES];
  } else {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
  }
}

-(void) showSaveError:(NSError*) error withMessage:(NSString*) msg {
  UIImageView * animatedView = [self animatedImageView:@"error" frames:9];
  self.hud.customView = animatedView;
  self.hud.mode = MBProgressHUDModeCustomView;
  [animatedView startAnimating];
  NSString * fullMsg = [NSString stringWithFormat:@"%@ Please make sure that you are conencted to a network and try again.",msg];
  NSLog(@"%@ caused by %@", msg, error);
  self.hud.completionBlock = ^{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"There is a small problem..." message:fullMsg delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
    [alert show];
  };
  [self.hud hide:NO afterDelay:1.5]; // when hidden will dismiss the dialog.
}

-(void) showGeneralAlert:(NSString*) title withMessage:(NSString*) msg {
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
  [alert show];
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
