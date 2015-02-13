//
//  FollowConnectionsNothingToShowViewController.h
//  DataParenting
//
//  Created by Nathan  Pahucki on 1/16/15.
//  Copyright (c) 2015 DataParenting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainFollowConnectionsViewController.h"

@interface FollowConnectionsNothingToShowViewController : UIViewController
@property(weak, nonatomic) IBOutlet UILabel *promptTextLabel;
@property(weak, nonatomic) IBOutlet UIButton *startButton;
@property(weak, nonatomic) IBOutlet UIImageView *arrowImageView;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *arrowImageViewBottomConstraint;

@property(strong, nonatomic) MainFollowConnectionsViewController *mainFollowController;

@end
