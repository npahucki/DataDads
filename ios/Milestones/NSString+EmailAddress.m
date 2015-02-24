//
// Created by Nathan  Pahucki on 1/9/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "NSString+EmailAddress.h"


@implementation NSString (EmailAddress)

- (BOOL)isValidEmailAddress {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:self] && ![[self lowercaseString] hasSuffix:@".con"];
}

@end