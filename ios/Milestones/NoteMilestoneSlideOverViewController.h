//
// Created by Nathan  Pahucki on 3/5/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//
// Exists to pass along the milestone achievement to the NoteMilestoneViewController.
//

#import <Foundation/Foundation.h>
#import "SlideOverViewController.h"

@class NoteMilestoneViewController;


@interface NoteMilestoneSlideOverViewController : SlideOverViewController
@property(nonatomic, strong) MilestoneAchievement *achievement;

@end