//
// Created by Nathan  Pahucki on 2/9/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "NSError+NewCategory.h"


@implementation NSError (NewCategory)
- (NSMutableDictionary *)asDictionary {
    NSMutableDictionary *combinedAttributes = [NSMutableDictionary dictionaryWithDictionary:self.userInfo];
    combinedAttributes[@"code"] = @(self.code);
    combinedAttributes[@"domain"] = self.domain ? self.domain : [NSNull null];
    return combinedAttributes;
}

- (NSString *)asJSONString {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self asDictionary] options:0 error:nil];
    return jsonData ? [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] : nil;
}


@end