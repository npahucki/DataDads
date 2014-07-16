//
//  NoConnectionAlertView.h
//  DataParenting
//
//  Created by Nathan  Pahucki on 7/1/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NoConnectionAlertView : UIView
@property(weak, nonatomic) IBOutlet UIButton *displayButton;

+ (void)createInstanceForController:(UIViewController *)controller;

@end
