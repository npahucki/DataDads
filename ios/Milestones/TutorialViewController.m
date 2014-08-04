//
//  TutorialViewController.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 7/29/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "TutorialViewController.h"

@interface TutorialViewController ()

@end

@implementation TutorialViewController {
    NSArray *_imageNames;
    NSUInteger _currentIndex;
    NSTimer *_currentTimer;
}


- (void)viewDidLoad {
    _imageNames = @[@"Tutorial-Screen-1.jpg", @"Tutorial-Screen-2.jpg", @"Tutorial-Screen-3.jpg", @"Tutorial-Screen-3d.jpg", @"Tutorial-Screen-4.jpg",@"Tutorial-Screen-4d.jpg", @"Tutorial-Screen-5.jpg", @"Tutorial-Screen-1.jpg"];
    [super viewDidLoad];
    [self advanceToNextPage];
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(advanceToNextPage)];
    [self.view addGestureRecognizer:singleTap];
}

- (void)advanceToNextPage {
    [_currentTimer invalidate];
    if (_currentIndex == _imageNames.count) {
        [self dismiss];
    } else {
        UIImage *toImage = [UIImage imageNamed:_imageNames[_currentIndex]];
        [UIView transitionWithView:self.view
                          duration:0.5f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
            self.imageView.image = toImage;
        } completion:NULL];
        _currentIndex++;
        NSTimeInterval time = _currentIndex == 1 || _currentIndex == _imageNames.count ? 2.0 : 7.0;
        _currentTimer = [NSTimer scheduledTimerWithTimeInterval:time target:self selector:@selector(advanceToNextPage) userInfo:nil repeats:NO];
    }
}


- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


@end
