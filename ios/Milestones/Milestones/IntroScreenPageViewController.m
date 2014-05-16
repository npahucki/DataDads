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
  _pageTitles = @[@"Help Create Parenting Science....\n\n...By Crowdsourcing Baby Data\n\nHere's How!",
                  
                  
                  @"• Answer 4 simple questions about your Baby\n\n• Select fun & serious milestones your Baby completes, whenever he does\n\n• We'll show you the comparative data as you note them\n\nThen...",
                  
                  @"• We'll start showing you tips & risks, based on how your baby is developing\n\n• Once you've recorded ~30 milestones, we'll get better at predicting the next ones\n\n• Have fun & Say hi: team@dataparenting"
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
  [self.view addSubview:_pageViewController.view];
  [self.pageViewController didMoveToParentViewController:self];
  
  
  self.loginNowButton.titleLabel.font = [UIFont fontForAppWithType:Bold andSize:23];
  
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
  if (([self.pageTitles count] == 0) || (index >= [self.pageTitles count])) {
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
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {

  
  if(completed && finished) {
    if(_nextIndex == 0) {
      [UIView transitionWithView:self.loginNowButton
                        duration:0.4
                         options:UIViewAnimationOptionTransitionCrossDissolve
                      animations:NULL
                      completion:NULL];
      self.loginNowButton.hidden = NO;
    } else {
      [UIView transitionWithView:self.loginNowButton
                        duration:0.4
                         options:UIViewAnimationOptionTransitionCrossDissolve
                      animations:NULL
                      completion:NULL];
      self.loginNowButton.hidden = YES;
    }
  }
  
}

- (IBAction)didClickLoginNow:(id)sender {
  NSLog(@"Log in now!");
}


@end
