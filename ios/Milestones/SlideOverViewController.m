//
//  SlideOverViewController.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 3/3/15.
//  Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "SlideOverViewController.h"

@interface SlideOverViewController ()

@end

@implementation SlideOverViewController {
    UIView *_tranparentPaneView; // contains the pull out tab image and the view from the slideOverController
    CGFloat _contentInset; // Depends on the size of the pull out tab
    CGPoint _centerAtStartDrag;

}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Allow the pull tab to drag out the window -
    UIPanGestureRecognizer *pullTabDragRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveTransparentPane:)];
    [pullTabDragRecognizer setMinimumNumberOfTouches:1];
    [pullTabDragRecognizer setMaximumNumberOfTouches:1];
    pullTabDragRecognizer.delegate = self;
    // Make the view jump when the icon is tapped.
    UITapGestureRecognizer *pullTabTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(jumpTransparentPane:)];
    pullTabTapRecognizer.delegate = self;


    CGRect screenBounds = [UIScreen mainScreen].bounds;

    _pullTabImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:self.tabImageName]];
    _pullTabImageView.userInteractionEnabled = YES;
    _pullTabImageView.alpha = 0.75;
    _pullTabImageView.center = CGPointMake(screenBounds.size.width - _pullTabImageView.bounds.size.width / 2, screenBounds.size.height / 2);
    [_pullTabImageView addGestureRecognizer:pullTabTapRecognizer];
    _contentInset = _pullTabImageView.bounds.size.width;

    // This is the pane that the pullout tab and the slide out view are embedded in.
    _tranparentPaneView = [[UIView alloc] init];
    _tranparentPaneView.bounds = screenBounds;
    _tranparentPaneView.backgroundColor = [UIColor clearColor];
    _tranparentPaneView.center = CGPointMake(_pullTabImageView.bounds.size.width - screenBounds.size.width / 2, _tranparentPaneView.bounds.size.height / 2);
    [_tranparentPaneView addSubview:_pullTabImageView];
    [_tranparentPaneView addGestureRecognizer:pullTabDragRecognizer];
    [self.view addSubview:_tranparentPaneView];



    // This will populate the VCs using segues, if they have not already been defined
    if (!self.mainViewController) [self performSegueWithIdentifier:SEGUE_FOR_MAIN_VC sender:self];
    if (!self.slideOverViewController) [self performSegueWithIdentifier:SEGUE_FOR_SLIDE_OVER_VC sender:self];

    // Since the transparent may have been added first, we need to bring it to the top
    [self.view bringSubviewToFront:_tranparentPaneView];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    CGRect screenBounds = [UIScreen mainScreen].bounds;

    if ([segue.identifier isEqualToString:SEGUE_FOR_MAIN_VC]) {
        self.mainViewController = segue.destinationViewController;
        self.mainViewController.view.frame = screenBounds;
        [self addChildViewController:self.mainViewController];
        [self.view addSubview:self.mainViewController.view];
        [self.mainViewController didMoveToParentViewController:self];
    } else if ([segue.identifier isEqualToString:SEGUE_FOR_SLIDE_OVER_VC]) {
        self.slideOverViewController = segue.destinationViewController;
        [_tranparentPaneView addSubview:self.slideOverViewController.view];
        self.slideOverViewController.view.frame = CGRectInset(_tranparentPaneView.bounds, _contentInset, _contentInset);
        self.slideOverViewController.view.layer.borderColor = [UIColor appNormalColor].CGColor;
        self.slideOverViewController.view.layer.borderWidth = 1;
        [self addChildViewController:self.slideOverViewController];
        [self.slideOverViewController didMoveToParentViewController:self];
    }
}

- (void)jumpTransparentPane:(UIPanGestureRecognizer *)recognizer {
    CGPoint originalCenter = _tranparentPaneView.center;
    CGPoint newCenter = CGPointMake(originalCenter.x + _contentInset * 2, originalCenter.y);
    [UIView animateWithDuration:0.15 animations:^{
        _tranparentPaneView.center = newCenter;
    }                completion:^(BOOL finished) {
        [UIView animateWithDuration:0.15 animations:^{
            _tranparentPaneView.center = originalCenter;
        }                completion:nil];
    }];
}

- (void)moveTransparentPane:(UIPanGestureRecognizer *)recognizer {
    CGPoint translatedPoint = [recognizer translationInView:self.view];

    if (recognizer.state == UIGestureRecognizerStateBegan) {
        _centerAtStartDrag = recognizer.view.center;
    }

    CGPoint newCenter = CGPointMake(_centerAtStartDrag.x + translatedPoint.x, recognizer.view.center.y);
    recognizer.view.center = newCenter;

    if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGFloat velocityX = (CGFloat) (0.2 * [recognizer velocityInView:self.view].x);
        CGFloat finalX = newCenter.x + recognizer.view.bounds.size.width / 2 + velocityX;
        CGFloat animationDuration = (CGFloat) ((ABS(velocityX) * .0002) + .2);

        if (finalX < self.view.center.x) {
            // Send it back
            [UIView animateWithDuration:animationDuration animations:^{
                recognizer.view.center =
                        CGPointMake(_contentInset - recognizer.view.bounds.size.width / 2, recognizer.view.center.y);
            }                completion:nil];
        } else {
            [UIView animateWithDuration:animationDuration animations:^{
                // Commit to showing it
                recognizer.view.center = self.view.center;
            }                completion:nil];
        }
    }
}


@end
