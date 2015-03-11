//
// Created by Nathan  Pahucki on 3/4/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <hipmob/HMContentChatViewController.h>
#import "SlideOverViewController.h"

@interface HipmobViewController : UIViewController <HMChatViewDelegate, UITextViewDelegate>
@property(weak, nonatomic) IBOutlet UILabel *titleLabel;
@property(weak, nonatomic) IBOutlet UIImageView *statusImageView;
@property(weak, nonatomic) IBOutlet UIView *chatContainerView;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *chatContainerBottomConstraint;

@property(strong, nonatomic) HMChatView *chatView;

@end