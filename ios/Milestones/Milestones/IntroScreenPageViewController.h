//
//  IntroScreenPageViewController.h
//  
//
//  Created by Nathan  Pahucki on 5/15/14.
//
//

#import <UIKit/UIKit.h>

@interface IntroScreenPageViewController : UIViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (strong, nonatomic) NSArray *pageTitles;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (weak, nonatomic) IBOutlet UIButton *loginNowButton;


@end
