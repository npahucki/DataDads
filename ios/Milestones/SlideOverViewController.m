//
//  SlideOverViewController.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 3/3/15.
//  Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "SlideOverViewController.h"
#import "UIDevice+DetectBlur.h"

@implementation SlideOutViewControllerEmbedSegue
- (void)perform {
    NSAssert([self.sourceViewController isKindOfClass:[SlideOverViewController class]], @"SlideOutViewControllerEmbedSegue can only be used with SlideOverViewController as the source view controller");
    SlideOverViewController *slideOverVc = ((SlideOverViewController *) self.sourceViewController);
    if ([self.identifier isEqualToString:SEGUE_FOR_MAIN_VC]) {
        slideOverVc.mainViewController = self.destinationViewController;
    } else if ([self.identifier isEqualToString:SEGUE_FOR_SLIDE_OVER_VC]) {
        slideOverVc.slideOverViewController = self.destinationViewController;
    }
}
@end

@interface SlideOverViewController ()
@property(nonatomic) CGPoint centerPointForSlideOverHidden;
@property(nonatomic) CGPoint centerPointForSlideOverShowing;

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

    // TODO: Check to see if view is sized correctly here.
    self.view.frame = [UIScreen mainScreen].bounds; // At this point the view may not have the correct size
    CGRect viewBounds = self.view.bounds;

    _pullTabImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:self.tabImageName]];
    _pullTabImageView.userInteractionEnabled = YES;
    _pullTabImageView.alpha = 0.75;
    _pullTabImageView.center = CGPointMake((self.isSlideFromRight ? 0 : viewBounds.size.width) + _pullTabImageView.bounds.size.width / 2, viewBounds.size.height / 2);

    [_pullTabImageView addGestureRecognizer:pullTabTapRecognizer];
    _contentInset = _pullTabImageView.bounds.size.width;

    // This is the pane that the pullout tab and the slide out view are embedded in.
    _tranparentPaneView = [[UIView alloc] init];
    _tranparentPaneView.bounds = CGRectMake(0, 0, viewBounds.size.width + _contentInset, viewBounds.size.height);
    _tranparentPaneView.backgroundColor = [UIColor clearColor];
    _tranparentPaneView.center = self.centerPointForSlideOverHidden;
    [_tranparentPaneView addSubview:_pullTabImageView];
    [_tranparentPaneView addGestureRecognizer:pullTabDragRecognizer];
    [self.view addSubview:_tranparentPaneView];


    if (!self.mainViewController) [self performSegueWithIdentifier:SEGUE_FOR_MAIN_VC sender:self];
    if (!self.slideOverViewController) [self performSegueWithIdentifier:SEGUE_FOR_SLIDE_OVER_VC sender:self];
    [self installMainViewController];
    [self installSliderOverViewController];

    // Since the transparent may have been added first, we need to bring it to the top
    [self.view bringSubviewToFront:_tranparentPaneView];
}

- (void)installSliderOverViewController {
    NSAssert(self.slideOverViewController, @"Expected sliderOverViewController to be populated!");
    CGRect frameRect = CGRectMake(_isSlideFromRight ? _contentInset : 0,
            0, _tranparentPaneView.bounds.size.width - _contentInset, _tranparentPaneView.bounds.size.height);

    [self addChildViewController:self.slideOverViewController];

    if ([[UIDevice currentDevice] isBlurAvailable]) {
        // We can use ios 8 visual effects! Yay!
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurView.translatesAutoresizingMaskIntoConstraints = NO;
        blurView.frame = frameRect;
        self.slideOverViewController.view.frame = blurView.contentView.bounds;
        [blurView.contentView addSubview:self.slideOverViewController.view];
        [_tranparentPaneView addSubview:blurView];
    } else {
        // Fall back to using a blured image of the startup screen.
        UIView *opaqueView = [[UIView alloc] init];
        opaqueView.backgroundColor = [UIColor whiteColor];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"backgroundBlurry"]];
        imageView.alpha = 0.20;
        self.slideOverViewController.view.frame = opaqueView.frame = imageView.frame = frameRect;
        [_tranparentPaneView addSubview:opaqueView];
        [_tranparentPaneView addSubview:imageView]; // add behind the slideOverController
        [_tranparentPaneView addSubview:self.slideOverViewController.view];
    }

    [self.slideOverViewController didMoveToParentViewController:self];

}

- (void)installMainViewController {
    // TODO: use constraints!
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    NSAssert(self.mainViewController, @"Expected mainViewController to be populated!");
    self.mainViewController.view.frame = screenBounds;
    [self addChildViewController:self.mainViewController];
    [self.view addSubview:self.mainViewController.view];
    [self.mainViewController didMoveToParentViewController:self];
}

- (void)jumpTransparentPane:(UIPanGestureRecognizer *)recognizer {
    CGPoint originalCenter = _tranparentPaneView.center;
    CGPoint newCenter = CGPointMake(originalCenter.x + _contentInset * (_isSlideFromRight ? -2 : 2), originalCenter.y);
    [UIView animateWithDuration:0.15 animations:^{
        _tranparentPaneView.center = newCenter;
    }                completion:^(BOOL finished) {
        [UIView animateWithDuration:0.15 animations:^{
            _tranparentPaneView.center = originalCenter;
        }                completion:nil];
    }];
}

- (void)moveTransparentPane:(UIPanGestureRecognizer *)recognizer {
    [self.mainViewController.view endEditing:YES];
    [self.slideOverViewController.view endEditing:YES];

    CGPoint translatedPoint = [recognizer translationInView:self.view];

    if (recognizer.state == UIGestureRecognizerStateBegan) {
        _centerAtStartDrag = recognizer.view.center;
    }

    CGPoint newCenter = CGPointMake(_centerAtStartDrag.x + translatedPoint.x, recognizer.view.center.y);
    recognizer.view.center = newCenter;

    if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGFloat velocityX = (0.2F * [recognizer velocityInView:self.view].x);
        CGFloat finalX = newCenter.x + velocityX + recognizer.view.bounds.size.width / (_isSlideFromRight ? -2.0F : 2.0F);
        CGFloat animationDuration = ((ABS(velocityX) * .0002F) + .2F);

        BOOL commit = _isSlideFromRight ? finalX < self.view.center.x : finalX > self.view.center.x;
        if (commit) {
            // Commit to showing it
            [UIView animateWithDuration:animationDuration animations:^{
                recognizer.view.center = self.centerPointForSlideOverShowing;
            } completion:^(BOOL finished) {
                // Let views update themselves.
                for (UIViewController *vc in self.childViewControllers) {
                    if ([vc conformsToProtocol:@protocol(SlideOverViewControllerEventReceiver)]) {
                        [((id <SlideOverViewControllerEventReceiver>) vc)
                                viewDidFinishSlidingOut:self.slideOverViewController over:self.mainViewController];
                    }
                }
            }];
        } else {
            // Send it back
            [UIView animateWithDuration:animationDuration animations:^{
                recognizer.view.center = self.centerPointForSlideOverHidden;
            } completion:^(BOOL finished) {
                // Let views update themselves.
                for (UIViewController *vc in self.childViewControllers) {
                    if ([vc conformsToProtocol:@protocol(SlideOverViewControllerEventReceiver)]) {
                        [((id <SlideOverViewControllerEventReceiver>) vc)
                                viewDidFinishSlidingIn:self.slideOverViewController over:self.mainViewController];
                    }
                }
            }];
        }
    }
}

- (CGPoint)centerPointForSlideOverShowing {
    CGFloat centerX = self.view.center.x + (_contentInset / (_isSlideFromRight ? -2.0F : 2.0F));
    return CGPointMake(centerX, self.view.center.y);
}

- (CGPoint)centerPointForSlideOverHidden {
    CGFloat centerX = _isSlideFromRight ? self.view.center.x * 3.0F - _contentInset / 2.0F :
            _contentInset / 2 - self.view.center.x;
    return CGPointMake(centerX, (_tranparentPaneView.bounds.size.height / 2.0F));
}

@end
