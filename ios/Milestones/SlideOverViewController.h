//
//  SlideOverViewController.h
//  DataParenting
//
//  Created by Nathan  Pahucki on 3/3/15.
//  Copyright (c) 2015 DataParenting. All rights reserved.
//

#import <UIKit/UIKit.h>

#define SEGUE_FOR_MAIN_VC @"main"
#define SEGUE_FOR_SLIDE_OVER_VC @"slideOver"

@protocol SlideOverViewControllerEventReceiver

- (void)viewDidFinishSlidingOut:(UIViewController *)slidingView over:(UIViewController *)otherVc;

- (void)viewDidFinishSlidingIn:(UIViewController *)slidingView over:(UIViewController *)otherVc;

@end

@interface SlideOutViewControllerEmbedSegue : UIStoryboardSegue
@end

@interface SlideOverViewController : UIViewController <UIScrollViewDelegate, UIGestureRecognizerDelegate>

// Designed to be set from IB
@property BOOL isSlideFromRight;
@property(strong, nonatomic) NSString *tabImageName;

// These must be set before viewDidLoad is called - or they will be replaced with VCs from storyboard segues.
@property(strong, nonatomic) UIViewController *mainViewController;
@property(strong, nonatomic) UIViewController *slideOverViewController;


// Exposed to allow manipulation if needed.
@property(readonly) UIImageView *pullTabImageView;


@end
