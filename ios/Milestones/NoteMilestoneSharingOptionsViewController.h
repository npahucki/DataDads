//
//  NoteMilestoneSharingOptionsViewController.h
//  DataParenting
//
//  Created by Nathan  Pahucki on 3/6/15.
//  Copyright (c) 2015 DataParenting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SlideOverViewController.h"

@interface NoteMilestoneSharingOptionsViewController : UIViewController <SlideOverViewControllerEventReceiver>
@property(weak, nonatomic) IBOutlet UISwitch *enableFacebookButton;
@property(weak, nonatomic) IBOutlet UISwitch *enableFollowersSwitch;

@end
