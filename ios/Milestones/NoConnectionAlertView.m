//
//  NoConnectionAlertView.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 7/1/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "NoConnectionAlertView.h"

@implementation NoConnectionAlertView {
  BOOL _isShowing;
}

-(void) awakeFromNib {
  [super awakeFromNib];
  NSMutableAttributedString * title = [[NSMutableAttributedString alloc] initWithString:@"Warning:" attributes:@{NSFontAttributeName : [UIFont fontForAppWithType:Book andSize:17]}];
  [title appendAttributedString:[[NSAttributedString alloc] initWithString:@"No internet connection available" attributes:@{NSFontAttributeName : [UIFont fontForAppWithType:Book andSize:12]}]];
  [self.displayButton setAttributedTitle:title forState:UIControlStateNormal];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkReachabilityChanged:) name:kReachabilityChangedNotification object:nil];
}

-(void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+(void) createInstanceForController:(UIViewController*) controller {
  NoConnectionAlertView * alertView =[[[NSBundle mainBundle] loadNibNamed:@"NoConnectionAlertView" owner:self options:nil] objectAtIndex:0];
  // TODO: Might need to conside if the edges extend below the navigation bar
  float y =  controller.navigationController.navigationBar.frame.size.height + controller.navigationController.navigationBar.frame.origin.y;
  alertView.frame = CGRectMake(0,y,controller.view.bounds.size.width,0);
  alertView.hidden = YES;
  [controller.view addSubview:alertView];
}

-(void) networkReachabilityChanged:(NSNotification*)notification {
  if([Reachability isParseCurrentlyReachable]) {
    if(_isShowing) {
      _isShowing = NO;
      [UIView
       animateWithDuration:0.5
       animations:^{
         self.frame = CGRectMake(0,self.frame.origin.y,self.frame.size.width,0);
       } completion:^(BOOL finished) {
         self.hidden = YES;
       }];
    }
  } else {
    if(!_isShowing) {
      _isShowing = YES;
      self.hidden = NO;
      [UIView
       animateWithDuration:0.5
       animations:^{
         self.frame = CGRectMake(0,self.frame.origin.y,self.frame.size.width,44);
       }];
    }
  }
}


@end
