//
//  NSDate+HumanizedTime.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 6/19/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "NSDate+HumanizedTime.h"

#define NSDATE_TABLE_NAME @"NSDateHumanizedTime"

@implementation NSDate (HumanizedTime)

- (NSString *)stringWithHumanizedTimeDifference {
    return [self stringWithHumanizedTimeDifference:YES];
}


- (NSString *)stringWithHumanizedTimeDifference:(BOOL)withSuffix {

    NSTimeInterval timeInterval = [self timeIntervalSinceNow];

    int secondsInADay = 3600 * 24;
    int secondsInAYear = 3600 * 24 * 365;
    int yearsDiff = abs(timeInterval / secondsInAYear);
    int daysDiff = abs(timeInterval / secondsInADay);
    int hoursDiff = abs((abs(timeInterval) - (daysDiff * secondsInADay)) / 3600);
    int minutesDiff = abs((abs(timeInterval) - ((daysDiff * secondsInADay) + (hoursDiff * 60))) / 60);
    //int secondsDiff = (abs(timeInterval) - ((daysDiff * secondsInADay) + (hoursDiff * 3600) + (minutesDiff * 60)));

    NSString *positivity = withSuffix ? [NSString stringWithFormat:@"%@", timeInterval < 0 ? NSLocalizedStringFromTable(@"AgoKey", NSDATE_TABLE_NAME, @"") : NSLocalizedStringFromTable(@"LaterKey", NSDATE_TABLE_NAME, @"")] : @"";


    //Some languages don't need whitespeces between words.
    NSArray *languagesWithNoSpace = [NSArray arrayWithObjects:@"zh-Hans", @"ja", nil];
    NSString *spaceBetweenWords = @" ";
    for (NSString *languageWithNoSpace in languagesWithNoSpace) {
        if ([[[NSLocale preferredLanguages] objectAtIndex:0] isEqualToString:languageWithNoSpace]) {
            spaceBetweenWords = @"";
        }
    }

    if (yearsDiff >= 1) {
        int monthsDiff = (daysDiff / 30) - (yearsDiff * 12);
        NSString *diffString = [NSString stringWithFormat:@"%d%@%@", yearsDiff, spaceBetweenWords, NSLocalizedStringFromTable(yearsDiff == 1 ? @"YearKey" : @"YearsKey", NSDATE_TABLE_NAME, @"")];
        if (monthsDiff > 0) {
            diffString = [NSString stringWithFormat:@"%@%@%d%@%@", diffString, spaceBetweenWords, monthsDiff, spaceBetweenWords, NSLocalizedStringFromTable(monthsDiff == 1 ? @"MonthKey" : @"MonthsKey", NSDATE_TABLE_NAME, @"")];
        }
        return [NSString stringWithFormat:@"%@%@%@", diffString, spaceBetweenWords, positivity];
    } else if (daysDiff >= 30) {
        int monthsDiff = daysDiff / 30;
        int remainingDays = daysDiff % 30;
        NSString *diffString = [NSString stringWithFormat:@"%d%@%@", monthsDiff, spaceBetweenWords, NSLocalizedStringFromTable(monthsDiff == 1 ? @"MonthKey" : @"MonthsKey", NSDATE_TABLE_NAME, @"")];
        if (remainingDays >= 1) {
            diffString = [NSString stringWithFormat:@"%@%@%d%@%@", diffString, spaceBetweenWords, remainingDays, spaceBetweenWords, NSLocalizedStringFromTable(remainingDays == 1 ? @"DayKey" : @"DaysKey", NSDATE_TABLE_NAME, @"")];
        }
        return [NSString stringWithFormat:@"%@%@%@", diffString, spaceBetweenWords, positivity];
    } else if (daysDiff > 0) {
        if (hoursDiff == 0 || daysDiff > 2)
            return [NSString stringWithFormat:@"%d%@%@%@%@", daysDiff, spaceBetweenWords, daysDiff == 1 ? NSLocalizedStringFromTable(@"DayKey", NSDATE_TABLE_NAME, @"") : NSLocalizedStringFromTable(@"DaysKey", NSDATE_TABLE_NAME, @""), spaceBetweenWords, positivity];
        else
            return [NSString stringWithFormat:@"%d%@%@%@%d%@%@%@%@", daysDiff, spaceBetweenWords, daysDiff == 1 ? NSLocalizedStringFromTable(@"DayKey", NSDATE_TABLE_NAME, @"") : NSLocalizedStringFromTable(@"DaysKey", NSDATE_TABLE_NAME, @""), spaceBetweenWords, hoursDiff, spaceBetweenWords, NSLocalizedStringFromTable(@"HoursKey", NSDATE_TABLE_NAME, @""), spaceBetweenWords, positivity];
    }
    else {
        if (hoursDiff == 0) {
            if (minutesDiff == 0)
                return [NSString stringWithFormat:@"%@%@%@", NSLocalizedStringFromTable(@"SecondKey", NSDATE_TABLE_NAME, @""), spaceBetweenWords, positivity];
            else
                return [NSString stringWithFormat:@"%d%@%@%@%@", minutesDiff, spaceBetweenWords, minutesDiff == 1 ? NSLocalizedStringFromTable(@"MinuteKey", NSDATE_TABLE_NAME, @"") : NSLocalizedStringFromTable(@"MinutesKey", NSDATE_TABLE_NAME, @""), spaceBetweenWords, positivity];
        }
        else {
            if (hoursDiff == 1)
                return [NSString stringWithFormat:@"%@%@%@%@%@", NSLocalizedStringFromTable(@"AboutKey", NSDATE_TABLE_NAME, @""), spaceBetweenWords, NSLocalizedStringFromTable(@"HourKey", NSDATE_TABLE_NAME, @""), spaceBetweenWords, positivity];
            else
                return [NSString stringWithFormat:@"%d%@%@%@%@", hoursDiff, spaceBetweenWords, NSLocalizedStringFromTable(@"HoursKey", NSDATE_TABLE_NAME, @""), spaceBetweenWords, positivity];
        }
    }
}

@end