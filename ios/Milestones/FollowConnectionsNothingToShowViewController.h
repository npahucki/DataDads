//
//  FollowConnectionsNothingToShowViewController.h
//  DataParenting
//
//  Created by Nathan  Pahucki on 1/16/15.
//  Copyright (c) 2015 DataParenting. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FollowConnectionsNothingToShowViewController : UIViewController
@property(weak, nonatomic) IBOutlet UILabel *promptTextLabel;
@property(weak, nonatomic) IBOutlet UIButton *signupButton;
@property(weak, nonatomic) IBOutlet UIImageView *addContactArrowImageView;
@property(weak, nonatomic) IBOutlet UIImageView *signupNowArrowImageView;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *addContactArrowImageViewTopConstraint;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *signupNowArrowImageViewBottomConstraint;
@property(weak, nonatomic) IBOutlet UILabel *helloLabel;

@end
