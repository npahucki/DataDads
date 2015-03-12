//
// Created by Nathan  Pahucki on 3/11/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "SettingsPanelNavigationController.h"


@implementation SettingsPanelNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidFinishSlidingOut:(UIViewController *)slidingView over:(UIViewController *)otherVc {
    [self.topViewController viewDidAppear:YES];
}

- (void)viewDidFinishSlidingIn:(UIViewController *)slidingView over:(UIViewController *)otherVc {
    [self.topViewController viewDidDisappear:YES];
}

@end