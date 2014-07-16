//
//  StandardMilestone.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/31/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "PronounHelper.h"


@implementation StandardMilestone

@dynamic title;
@dynamic enteredBy;
@dynamic url;
@dynamic rangeHigh;
@dynamic rangeLow;
@dynamic canCompare;

- (NSString *)titleForBaby:(Baby *)baby {
    return [PronounHelper replacePronounTokens:self.title forBaby:baby];
}

- (NSString *)titleForCurrentBaby {
    return [self titleForBaby:Baby.currentBaby];
}


+ (NSString *)parseClassName {
    return @"StandardMilestones";
}


@end
