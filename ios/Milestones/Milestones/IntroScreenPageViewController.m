//
//  IntroScreenPageViewController.m
//  
//
//  Created by Nathan  Pahucki on 5/15/14.
//
//

#import "IntroScreenPageViewController.h"
#import "IntroScreenContentViewController.h"

@interface IntroScreenPageViewController ()

@end

@implementation IntroScreenPageViewController {
  NSUInteger _nextIndex;
}


- (void)viewDidLoad
{
  [super viewDidLoad];
  _pageTitles = @[@"Help create Parenting Science...",
                  @"By compiling your baby's milestones, fun and serious",
                  @"We'll share the data anonymously -- and show you each one's comparative data",
                  @"We'll start showing you tips & risks, based on how your baby is developing",
                  @"Once you've noted ~30 milestones, we'll get better at predicting what comes next.\n\nLets go!"
                  ];
  
  // Create page view controller
  self.pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"IntroScreenPageViewController"];
  self.pageViewController.dataSource = self;
  self.pageViewController.delegate = self;
  
  IntroScreenContentViewController *startingViewController = [self viewControllerAtIndex:0];
  NSArray *viewControllers = @[startingViewController];
  [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
  
  // Change the size of page view controller
  self.pageViewController.view.frame = CGRectMake(0, 44, self.view.frame.size.width, self.view.frame.size.height - 88);
  
  [self addChildViewController:_pageViewController];
  [self.view insertSubview:_pageViewController.view belowSubview:self.continueButton];
  [self.pageViewController didMoveToParentViewController:self];
  
  
  self.loginNowButton.titleLabel.font = [UIFont fontForAppWithType:Bold andSize:23];
  
}

- (IBAction)didClickContinueButton:(id)sender {
  if(_nextIndex == _pageTitles.count - 1) {
    [self performSegueWithIdentifier:kDDSegueEnterBabyInfo sender:self];
  } else {
    UIViewController *currentViewController = [self.pageViewController.viewControllers objectAtIndex:0];
    UIViewController *nextViewController = [self pageViewController:self.pageViewController viewControllerAfterViewController:currentViewController];
    if(nextViewController) {
      // We need to simulate the same methods as would swiping the page because they do not get fired for us automatically.
      [self pageViewController:self.pageViewController willTransitionToViewControllers:@[nextViewController]];
      __weak IntroScreenPageViewController * weakSelf = self;
      [self.pageViewController setViewControllers:@[nextViewController]
                                      direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:^(BOOL finished) {
                                        [weakSelf pageViewController:weakSelf.pageViewController didFinishAnimating:YES previousViewControllers:@[currentViewController] transitionCompleted:YES];
                                      }];
    }
  }
  
}


#pragma mark - Page View Controller Data Source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
  NSUInteger index = ((IntroScreenContentViewController*) viewController).pageIndex;
  
  if ((index == 0) || (index == NSNotFound)) {
    return nil;
  }
  
  index--;
  return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
  NSUInteger index = ((IntroScreenContentViewController*) viewController).pageIndex;
  if (index == NSNotFound) {
    return nil;
  }
  
  index++;
  if (index == [self.pageTitles count]) {
    return nil;
  }
  return [self viewControllerAtIndex:index];
}

- (IntroScreenContentViewController *)viewControllerAtIndex:(NSUInteger)index
{
  if (([_pageTitles count] == 0) || (index >= [_pageTitles count])) {
    return nil;
  }
  
  // Create a new view controller and pass suitable data.
  IntroScreenContentViewController *introScreenViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"IntroScreenContentViewController"];
  introScreenViewController.text = self.pageTitles[index];
  introScreenViewController.pageIndex = index;
  return introScreenViewController;
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
  return _pageTitles.count;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
  return 0;
}

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers {
    IntroScreenContentViewController* controller =  [pendingViewControllers firstObject];
    _nextIndex = controller.pageIndex;
  
    // Button animated effect
    [UIView transitionWithView:self.continueButton
                    duration:0.5
                     options:UIViewAnimationOptionTransitionCrossDissolve
                  animations:NULL
                  completion:^(BOOL finished) {
                     if(_nextIndex == _pageTitles.count - 1) {
                       [self.continueButton setTitle:@"Get Started" forState:UIControlStateNormal];
                     } else {
                       [self.continueButton setTitle:@"Continue" forState:UIControlStateNormal];
                     }
                    // Make the continue button reappear
                    [UIView transitionWithView:self.continueButton
                                      duration:0.5
                                       options:UIViewAnimationOptionTransitionCrossDissolve
                                    animations:nil
                                    completion:nil];
                    self.continueButton.hidden = NO;
                  }];
    self.continueButton.hidden = YES;
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {

  
  if(completed && finished) {
    if(_nextIndex == 0) {
      [UIView transitionWithView:self.loginNowButton
                        duration:0.4
                         options:UIViewAnimationOptionTransitionCrossDissolve
                      animations:nil
                      completion:nil];
      self.loginNowButton.hidden = NO;
    } else {
      [UIView transitionWithView:self.loginNowButton
                        duration:0.4
                         options:UIViewAnimationOptionTransitionCrossDissolve
                      animations:nil
                      completion:nil];
      self.loginNowButton.hidden = YES;
    }
  }
  
}

@end
