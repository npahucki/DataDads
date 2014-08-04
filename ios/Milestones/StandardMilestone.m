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

- (NSString *)humanReadableRange {
    NSInteger rangeLow = self.rangeLow.integerValue;
    NSInteger rangeHigh = self.rangeHigh.integerValue;

    if (rangeLow < 30 && rangeHigh < 30) {
        return [NSString stringWithFormat:@"%d to %d days", (int)rangeLow, (int)rangeHigh];
    } else if (rangeLow < 365 && rangeHigh < 365) {
        return [NSString stringWithFormat:@"%d to %d months", (int)rangeLow / 30, (int)rangeHigh / 30];
    } else {
        return [NSString stringWithFormat:@"%@ to %@", [self humanReadableDays:rangeLow], [self humanReadableDays:rangeHigh]];
    }
}

- (NSString *)humanReadableDays:(NSInteger)days {
    if (days < 30) {
        return [NSString stringWithFormat:@"%d day%@", (int)days, days == 1 ? @"" : @"s"];
    } else if (days < 365) {
        int months = (int) (days / 30.5F);
        return [NSString stringWithFormat:@"%d month%@", months, months == 1 ? @"" : @"s"];
    } else {
        int years = (int)days / 365;
        int remainingDays = days % 365;
        int months = (int) (remainingDays / 30.5);
        if (months >= 1) {
            return [NSString stringWithFormat:@"%d year%@ %d month%@", years, years == 1 ? @"" : @"s", months, months == 1 ? @"" : @"s"];
        } else {
            return [NSString stringWithFormat:@"%d year%@", years, years == 1 ? @"" : @"s"];
        }
    }

}

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
