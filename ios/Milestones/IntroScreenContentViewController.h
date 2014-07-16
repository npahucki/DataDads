//
//  IntroScreenViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 5/15/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IntroScreenContentViewController : UIViewController

@property NSUInteger pageIndex;
@property NSString *text;
@property(weak, nonatomic) IBOutlet UILabel *titleLabel;

@end
