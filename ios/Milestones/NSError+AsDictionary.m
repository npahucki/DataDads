//
// Created by Nathan  Pahucki on 2/9/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "NSError+AsDictionary.h"


@implementation NSError (AsDictionary)
- (NSMutableDictionary *)asDictionary {
    NSMutableDictionary *combinedAttributes = [NSMutableDictionary dictionary];
    combinedAttributes[@"code"] = @(self.code);
    combinedAttributes[@"domain"] = self.domain ? self.domain : [NSNull null];
    
    // Remove any keys that would make Mixpanel crash.
    for (id __unused k in self.userInfo) {
        id val = combinedAttributes[k];
        if( [val isKindOfClass:[NSString class]] ||
           [val isKindOfClass:[NSNumber class]] ||
           [val isKindOfClass:[NSNull class]] ||
           [val isKindOfClass:[NSArray class]] ||
           [val isKindOfClass:[NSDictionary class]] ||
           [val isKindOfClass:[NSDate class]] ||
           [val isKindOfClass:[NSURL class]]) {
            
            // Only copy valid values
            combinedAttributes[k] = val;
        }
        
    }
    return combinedAttributes;
}


@end