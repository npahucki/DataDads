//
//  NotificationDetailViewController.h
//  DataParenting
//
//  Created by Nathan  Pahucki on 9/3/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NotificationDetailViewController : UIViewController
@property(weak, nonatomic) IBOutlet UITextView *detailTextView;
@property(strong, nonatomic) BabyAssignedTip *tipAssignment;

@end
