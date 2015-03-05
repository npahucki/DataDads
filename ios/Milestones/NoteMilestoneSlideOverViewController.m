//
// Created by Nathan  Pahucki on 3/5/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "NoteMilestoneSlideOverViewController.h"
#import "NoteMilestoneViewController.h"


@implementation NoteMilestoneSlideOverViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[NoteMilestoneViewController class]]) {
        ((NoteMilestoneViewController *) segue.destinationViewController).achievement = self.achievement;
    }
}

@end