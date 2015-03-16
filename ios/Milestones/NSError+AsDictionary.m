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
    // Take out the FB session (if it exists) since it can only be used on the main thread, and these values
    // ultimately get written on a background thread.
    [combinedAttributes removeObjectForKey:@"com.facebook.sdk:ErrorSessionKey"];
    return combinedAttributes;
}


@end