//
//  Tip.m
//  Milestones
//
//  Created by Nathan  Pahucki on 5/28/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "PronounHelper.h"

@implementation Tip

@dynamic title;
@dynamic tipType;
@dynamic shortDescription;
@dynamic url;

- (NSString *)shortDescriptionForCurrentBaby {
    return [PronounHelper replacePronounTokens:self.shortDescription forBaby:Baby.currentBaby];
}

- (NSString *)titleForBaby:(Baby *)baby {
    return [PronounHelper replacePronounTokens:self.title forBaby:baby];
}

- (NSString *)titleForCurrentBaby {
    return [self titleForBaby:Baby.currentBaby];
}

+ (NSString *)parseClassName {
    return @"Tips";
}


@end
