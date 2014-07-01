//
//  AlertThenDisappearView.h
//  DataParenting
//
//  Created by Nathan  Pahucki on 7/1/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AlertThenDisappearView : UIView

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;


+(AlertThenDisappearView *) instanceForViewController:(UIViewController*) controller;
-(void) show;
-(void) showWithDelay:(NSTimeInterval) delay;


@end
