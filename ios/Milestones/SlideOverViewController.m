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


@end

@implementation SlideOverViewController {
    UIView *_tranparentPaneView;            // contains the pull out tab image and the view from the slideOverController
    UIView *_contentView;                   // The view directly on the transparent pane, used for content.
    CGFloat _contentInset;                  // Depends on the size of the pull out tab
    CGPoint _centerAtStartDrag;
    BOOL _didLayoutAfterInitialPullOut;     // The subviews need layout the first time the tab is pulled out.

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

    _pullTabImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:self.tabImageName]];
    _pullTabImageView.userInteractionEnabled = YES;
    _pullTabImageView.alpha = 0.75;

    [_pullTabImageView addGestureRecognizer:pullTabTapRecognizer];
    _contentInset = _pullTabImageView.bounds.size.width;


    _contentView = [[UIView alloc] init];
    _contentView.backgroundColor = [UIColor clearColor];

    // This is the pane that the pullout tab and content view are embedded in.
    _tranparentPaneView = [[UIView alloc] init];
    _tranparentPaneView.backgroundColor = [UIColor clearColor];
    [_tranparentPaneView addSubview:_contentView];
    [_tranparentPaneView addSubview:_pullTabImageView];
    [_tranparentPaneView addGestureRecognizer:pullTabDragRecognizer];
    [self.view addSubview:_tranparentPaneView];


    if (!self.mainViewController) [self performSegueWithIdentifier:SEGUE_FOR_MAIN_VC sender:self];
    if (!self.slideOverViewController) [self performSegueWithIdentifier:SEGUE_FOR_SLIDE_OVER_VC sender:self];
    [self installMainViewController];
    [self installSliderOverViewController];

    [self resizeViews];
    [self setSlideOverToHiddenPosition:NO];

    // Since the transparent may have been added first, we need to bring it to the top
    [self.view bringSubviewToFront:_tranparentPaneView];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self resizeViews];
    // On iOS8, the topLayoutGuide is set correctly ONLY after the view is on the screen
    // but, we want the view to come sliding out with the final layout, so we need to correct the
    // constraint that was added by the OS for the slide over control.
    [self correctTopLayoutConstraint:self.slideOverViewController];
    // On iOS7, the topLayout guide is NEVER set correctly before the transition due to a bug in iOS7.
    // In this cases, it's required that we correct the topLayoutGuide even on the main view.
    // See http://stackoverflow.com/questions/20312765/navigation-controller-top-layout-guide-not-honored-with-custom-transition
    if ([[UIDevice currentDevice] osMajorVersion] == 7) {
        [self correctTopLayoutConstraint:self.mainViewController];
    }
}

// This is a bit of a hack to work around some odd behavior in the OS.
// iOS8 : Views not on the screen when layout happens don't get the nav bar included in the calc for the topLayoutGuide height.
// iOS7 : No views ever initially get the nav bar calculated into the topLayoutGuide height.
- (void)correctTopLayoutConstraint:(UIViewController *)vc {
    for (NSLayoutConstraint *c in vc.view.constraints) {
        if (c.firstItem == vc.topLayoutGuide &&
                c.secondItem == nil && c.firstAttribute == NSLayoutAttributeHeight) {
            c.constant = self.topLayoutGuide.length;
        }
    }
}


- (void)resizeViews {
    CGRect viewBounds = self.view.bounds;
    _tranparentPaneView.frame = CGRectMake(_tranparentPaneView.frame.origin.x, 0,
            viewBounds.size.width + _contentInset, viewBounds.size.height);
    _contentView.frame = CGRectMake(_isSlideFromRight ? _contentInset : 0,
            0, _tranparentPaneView.bounds.size.width - _contentInset, _tranparentPaneView.bounds.size.height);
    for (UIView *subView in _contentView.subviews) {
        subView.frame = _contentView.bounds;
    }
    _pullTabImageView.center = CGPointMake((self.isSlideFromRight ? 0 : viewBounds.size.width) +
            _pullTabImageView.bounds.size.width / 2, viewBounds.size.height / 2);

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
        blurView.frame = frameRect;
        self.slideOverViewController.view.frame = blurView.contentView.bounds;
        [blurView.contentView addSubview:self.slideOverViewController.view];
        [_contentView addSubview:blurView];
        [_contentView addSubview:self.slideOverViewController.view];
    } else {
        // Fall back to using a blured image of the startup screen.
        UIView *opaqueView = [[UIView alloc] init];
        opaqueView.backgroundColor = [UIColor whiteColor];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"backgroundBlurry"]];
        imageView.alpha = 0.20;
        self.slideOverViewController.view.frame = opaqueView.frame = imageView.frame = frameRect;
        [_contentView addSubview:opaqueView];
        [_contentView addSubview:imageView]; // add behind the slideOverController
        [_contentView addSubview:self.slideOverViewController.view];
    }

    [self.slideOverViewController didMoveToParentViewController:self];
}

- (void)installMainViewController {
    NSAssert(self.mainViewController, @"Expected mainViewController to be populated!");
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
    NSAssert(recognizer.view == _tranparentPaneView, @"Expected this method to only be called for _transparentPaneView");
    [self.mainViewController.view endEditing:YES];
    [self.slideOverViewController.view endEditing:YES];

    CGPoint translatedPoint = [recognizer translationInView:self.view];

    if (recognizer.state == UIGestureRecognizerStateBegan) {
        _centerAtStartDrag = recognizer.view.center;
    }


    CGPoint newCenter = _tranparentPaneView.center;
    newCenter.x = _centerAtStartDrag.x + translatedPoint.x;
    _tranparentPaneView.center = newCenter;


    if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGFloat velocityX = (0.2F * [recognizer velocityInView:self.view].x);
        CGFloat finalX = newCenter.x + velocityX + _tranparentPaneView.bounds.size.width / (_isSlideFromRight ? -2.0F : 2.0F);
        CGFloat animationDuration = ((ABS(velocityX) * .0002F) + .2F);

        BOOL commit = _isSlideFromRight ? finalX < self.view.center.x : finalX > self.view.center.x;
        if (commit) {
            [self setSlideOverToShowingPosition2:animationDuration];
        } else {
            [self setSlideOverToHiddenPosition2:animationDuration];
        }
    }
}

- (void)setSlideOverToShowingPosition:(BOOL)animated {
    [self setSlideOverToShowingPosition2:animated ? 0.5F : 0.0F];
}

- (void)setSlideOverToHiddenPosition:(BOOL)animated {
    [self setSlideOverToHiddenPosition2:animated ? 0.5F : 0.0F];
}

- (void)setSlideOverToShowingPosition2:(CGFloat)animationDuration {
    CGPoint center = _tranparentPaneView.center;
    center.x = self.view.center.x + (_contentInset / (_isSlideFromRight ? -2.0F : 2.0F));

    if (animationDuration > 0) {
        [UIView animateWithDuration:animationDuration animations:^{
            _tranparentPaneView.center = center;
        }                completion:^(BOOL finished) {
            [self informSubControllersOfSlideChange:YES];
        }];
    } else {
        _tranparentPaneView.center = center;
        [self informSubControllersOfSlideChange:YES];
    }
}

- (void)setSlideOverToHiddenPosition2:(CGFloat)animationDuration {
    CGPoint center = _tranparentPaneView.center;
    center.x = _isSlideFromRight ? self.view.center.x * 3.0F - _contentInset / 2.0F :
            _contentInset / 2 - self.view.center.x;

    if (animationDuration > 0) {
        [UIView animateWithDuration:animationDuration animations:^{
            _tranparentPaneView.center = center;
        }                completion:^(BOOL finished) {
            // Let views update themselves.
            [self informSubControllersOfSlideChange:NO];
        }];
    } else {
        _tranparentPaneView.center = center;
        [self informSubControllersOfSlideChange:NO];
    }
}

- (void)informSubControllersOfSlideChange:(BOOL)slideOut {
    for (UIViewController *vc in self.childViewControllers) {
        if ([vc conformsToProtocol:@protocol(SlideOverViewControllerEventReceiver)]) {
            id <SlideOverViewControllerEventReceiver> evr = (id <SlideOverViewControllerEventReceiver>) vc;
            if (slideOut) {
                [evr viewDidFinishSlidingOut:self.slideOverViewController over:self.mainViewController];
            } else {
                [evr viewDidFinishSlidingIn:self.slideOverViewController over:self.mainViewController];
            }
        }
    }
    if (slideOut)
        [self slideOutViewDidSlideOut];
    else
        [self slideOutViewDidSlideIn];
}

// Let's any sublcasses know of a change.
- (void)slideOutViewDidSlideOut {
}

- (void)slideOutViewDidSlideIn {
}

@end
