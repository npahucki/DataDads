//
// Created by Nathan  Pahucki on 2/9/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "NSMutableDictionary+JSON.h"


@implementation NSDictionary (JSON)

- (NSString *)toJsonString {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:0 error:nil];
    return jsonData ? [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] : nil;
}
@end