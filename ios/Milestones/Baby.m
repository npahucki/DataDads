//
//  Baby.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/27/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "NSDate+Utils.h"

@implementation Baby

@dynamic name;
@dynamic parentUser;
@dynamic dueDate;
@dynamic birthDate;
@dynamic avatarImage;
@dynamic avatarImageThumbnail;
@dynamic tags;
@dynamic isMale;

static Baby *_currentBaby;

+ (PFQuery *)queryForBabiesForUser:(PFUser *)user {
    PFQuery *query = [self query];
    [query whereKey:@"parentUser" equalTo:user];
    return query;
}


- (NSInteger)daysSinceDueDate {
    return -1 * [self.dueDate daysDifferenceFromNow];
}

- (NSInteger)daysSinceBirth {
    return -1 * [self.birthDate daysDifferenceFromNow]; // will be negative since it happened in the past
}

- (NSInteger)daysSinceDueDate:(NSDate *)otherDate {
    return [self.dueDate daysDifference:otherDate];
}

- (NSInteger)daysSinceBirthDate:(NSDate *)otherDate {
    return [self.birthDate daysDifference:otherDate];
}


- (NSInteger)daysMissedDueDate {
    return [self.dueDate daysDifference:self.birthDate];
}

- (BOOL)wasBornPremature {
    return [self daysMissedDueDate] < 0;
}

- (NSString *)ageAtDateFormattedAsNiceString:(NSDate *)date {
    NSCalendarUnit unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comps = [calendar components:unitFlags fromDate:self.birthDate toDate:date options:0];
    NSString *format = @"";
    if (comps.year >= 1) format = [NSString stringWithFormat:@"%i year%s ", (int) comps.year, [self s:comps.year]];
    if (comps.month >= 1) format = [NSString stringWithFormat:@"%@%i month%s ", format, (int) comps.month, [self s:comps.month]];
    if (comps.day >= 1) format = [NSString stringWithFormat:@"%@%i day%s ", format, (int) comps.day, [self s:comps.day]];
    return format.length ? [NSString stringWithFormat:@"%@old", format] : @"newborn";
}

- (char *)s:(NSInteger)number {
    return number != 1 ? "s" : "";
}


+ (NSString *)parseClassName {
    return @"Babies";
}

+ (Baby *)currentBaby {
    return _currentBaby;
}

+ (void)setCurrentBaby:(Baby *)baby {
    // If and only if the Baby object is different do we replace it and send the notfication again
    if (_currentBaby != baby) {
        _currentBaby = baby;
        // Let others know the current baby has changed so they can update thier views
        [[NSNotificationCenter defaultCenter]
                postNotificationName:kDDNotificationCurrentBabyChanged object:_currentBaby];
    }
}

@end
