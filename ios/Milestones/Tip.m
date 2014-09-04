//
//  Tip.m
//  Milestones
//
//  Created by Nathan  Pahucki on 5/28/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "PronounHelper.h"
#import "NSDate+Utils.h"

@implementation Tip

@dynamic title;
@dynamic tipType;
@dynamic shortDescription;
@dynamic url;
@dynamic rangeHigh;
@dynamic rangeLow;

- (NSString *)shortDescriptionForCurrentBaby {
    return [PronounHelper replacePronounTokens:self.shortDescription forBaby:Baby.currentBaby];
}

- (NSString *)titleForBaby:(Baby *)baby {
    return [PronounHelper replacePronounTokens:self.title forBaby:baby];
}

- (NSString *)titleForCurrentBaby {
    return [self titleForBaby:Baby.currentBaby];
}

- (NSString *)humanReadableRange {
    return [NSDate humanReadableDayRange:self.rangeLow.integerValue and:self.rangeHigh.integerValue];
}


+ (NSString *)parseClassName {
    return @"Tips";
}


@end
