//
//  IntroScreenPageViewController.m
//  
//
//  Created by Nathan  Pahucki on 5/15/14.
//
//

#import "IntroScreenPageViewController.h"
#import "SignUpOrLoginViewController.h"

@interface IntroScreenPageViewController ()

@end

@implementation IntroScreenPageViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.continueButton.titleLabel.font = self.loginNowButton.titleLabel.font = [UIFont fontForAppWithType:Book andSize:21];
    [self.continueButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.loginNowButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];


    CGSize viewSize = [UIScreen mainScreen].bounds.size;
    NSString *viewOrientation = @"Portrait"; // only one supported for now
    NSArray *imagesDict = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"UILaunchImages"];
    NSString *launchImageName = nil;
    for (NSDictionary *dict in imagesDict) {
        CGSize imageSize = CGSizeFromString(dict[@"UILaunchImageSize"]);
        if (CGSizeEqualToSize(imageSize, viewSize) && [viewOrientation isEqualToString:dict[@"UILaunchImageOrientation"]]) {
            launchImageName = dict[@"UILaunchImageName"];
            break;
        }
    }

    self.backgroundImage.image = [UIImage imageNamed:launchImageName];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLogIn:) name:kDDNotificationUserLoggedIn object:nil];

}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)userDidLogIn:(NSNotification *)notification {
    // Hide this screen so the main view shows.
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[SignUpOrLoginViewController class]]) {
        ((SignUpOrLoginViewController *) segue.destinationViewController).loginMode = YES;
    }
}

@end
