//
// Created by Nathan  Pahucki on 4/29/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "AdFreeFeature.h"


@implementation AdFreeFeature

- (BFTask *)checkForUnlockStatus {
    return [BFTask taskWithResult:@(YES)];
}

@end