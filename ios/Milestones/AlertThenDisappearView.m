//
//  AlertThenDisappearView.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 7/1/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "AlertThenDisappearView.h"

@implementation AlertThenDisappearView {
    __weak UIViewController *_controller;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    //self.titleLabel.font = [UIFont fontForAppWithType:Book andSize:13];
    self.clipsToBounds = YES;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(10, 10);
    self.layer.shadowOpacity = 1;
    self.translatesAutoresizingMaskIntoConstraints = NO;
}

+ (AlertThenDisappearView *)instanceForViewController:(UIViewController *)controller {
    AlertThenDisappearView *alertView = [[[NSBundle mainBundle] loadNibNamed:@"AlertThenDisappearView" owner:self options:nil] objectAtIndex:0];
    alertView.hidden = YES;
    alertView->_controller = controller;
    return alertView;
}

- (void)show {
    float y = _controller.navigationController.navigationBar.frame.size.height + _controller.navigationController.navigationBar.frame.origin.y;
    self.frame = CGRectMake(0, y, _controller.view.bounds.size.width, 0);
    self.hidden = NO;
    [_controller.view addSubview:self];

    [UIView
            animateWithDuration:.5
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionLayoutSubviews
                     animations:^{
        self.frame = CGRectMake(0, self.frame.origin.y, self.frame.size.width, 44);
    }
                     completion:^(BOOL finished) {
        [self.titleLabel sizeToFit];
        [UIView
                animateWithDuration:0.5
                              delay:5.0
                            options:UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionLayoutSubviews
                         animations:^{
            self.frame = CGRectMake(0, self.frame.origin.y, self.frame.size.width, 0);
        }
                         completion:^(BOOL finished) {
            [self removeFromSuperview];
        }];
    }];
}

- (void)showWithDelay:(NSTimeInterval)delay {
    [NSTimer scheduledTimerWithTimeInterval:delay target:self selector:@selector(show) userInfo:nil repeats:NO];
}


@end
