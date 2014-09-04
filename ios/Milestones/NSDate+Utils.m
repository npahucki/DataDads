//
//  NSDate+Utils.m
//  Milestones
//
//  Created by Nathan  Pahucki on 6/2/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "NSDate+Utils.h"

@implementation NSDate (NSDate_Utils)

- (NSString *)asISO8601String {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    return [dateFormatter stringFromDate:self];
}

+ (NSDate *)dateInDaysFromNow:(NSInteger)days {
    return [[NSDate date] dateByAddingDays:days];
}


- (NSInteger)daysDifferenceFromNow {
    return [[NSDate date] daysDifference:self];
}

- (NSInteger)daysDifference:(NSDate *)toDate {
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit fromDate:self toDate:toDate options:0];
    return [components day];
}

- (NSDate *)dateByAddingDays:(NSInteger)days {
    NSCalendar *gregorian = [[NSCalendar alloc]
            initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    [offsetComponents setDay:days];
    return [gregorian dateByAddingComponents:offsetComponents toDate:self options:0];
}

+ (NSString *)humanReadableDayRange:(NSInteger)rangeLow and:(NSInteger)rangeHigh {
    if (rangeLow < 30 && rangeHigh < 30) {
        return [NSString stringWithFormat:@"%d to %d days", (int) rangeLow, (int) rangeHigh];
    } else if (rangeLow < 365 && rangeHigh < 365) {
        return [NSString stringWithFormat:@"%d to %d months", (int) rangeLow / 30, (int) rangeHigh / 30];
    } else {
        return [NSString stringWithFormat:@"%@ to %@", [self humanReadableDays:rangeLow], [self humanReadableDays:rangeHigh]];
    }
}

+ (NSString *)humanReadableDays:(NSInteger)days {
    if (days < 30) {
        return [NSString stringWithFormat:@"%d day%@", (int) days, days == 1 ? @"" : @"s"];
    } else if (days < 365) {
        int months = (int) (days / 30.5F);
        return [NSString stringWithFormat:@"%d month%@", months, months == 1 ? @"" : @"s"];
    } else {
        int years = (int) days / 365;
        int remainingDays = days % 365;
        int months = (int) (remainingDays / 30.5);
        if (months >= 1) {
            return [NSString stringWithFormat:@"%d year%@ %d month%@", years, years == 1 ? @"" : @"s", months, months == 1 ? @"" : @"s"];
        } else {
            return [NSString stringWithFormat:@"%d year%@", years, years == 1 ? @"" : @"s"];
        }
    }

}


@end
