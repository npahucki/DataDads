//
//  AlertThenDisappearView.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 7/1/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "AlertThenDisappearView.h"

@implementation AlertThenDisappearView {
    __weak UIView *_parentView;
    CGFloat _topPosition;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    //self.titleLabel.font = [UIFont fontForAppWithType:Book andSize:13];
    self.clipsToBounds = YES;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(10, 10);
    self.layer.shadowOpacity = 1;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
}

+ (AlertThenDisappearView *)instanceForViewController:(UIViewController *)controller {
    AlertThenDisappearView *alertView = [self instanceForView:controller.view];
    alertView->_topPosition = controller.navigationController.navigationBar.frame.size.height + controller.navigationController.navigationBar.frame.origin.y;
    return alertView;
}

+ (AlertThenDisappearView *)instanceForView:(UIView *)view {
    AlertThenDisappearView *alertView = [[NSBundle mainBundle] loadNibNamed:@"AlertThenDisappearView" owner:self options:nil][0];
    alertView.hidden = YES;
    alertView->_parentView = view;
    return alertView;
}

- (void)show {
    self.frame = CGRectMake(0, _topPosition, _parentView.bounds.size.width, 0);
    self.hidden = NO;
    [_parentView addSubview:self];

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
                                          completion:^(BOOL finished2) {
            [self removeFromSuperview];
        }];
    }];
}

- (void)showWithDelay:(NSTimeInterval)delay {
    [NSTimer scheduledTimerWithTimeInterval:delay target:self selector:@selector(show) userInfo:nil repeats:NO];
}


@end
