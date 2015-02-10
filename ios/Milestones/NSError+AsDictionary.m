//
// Created by Nathan  Pahucki on 2/9/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "NSError+AsDictionary.h"


@implementation NSError (AsDictionary)
- (NSMutableDictionary *)asDictionary {
    NSMutableDictionary *combinedAttributes = [NSMutableDictionary dictionaryWithDictionary:self.userInfo];
    combinedAttributes[@"code"] = @(self.code);
    combinedAttributes[@"domain"] = self.domain ? self.domain : [NSNull null];
    return combinedAttributes;
}


@end