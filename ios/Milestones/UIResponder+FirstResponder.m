//
// Created by Nathan  Pahucki on 2/16/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "UIResponder+FirstResponder.h"


static __weak id currentFirstResponder;

@implementation UIResponder (FirstResponder)
+ (id)currentFirstResponder {
    currentFirstResponder = nil;
    [[UIApplication sharedApplication] sendAction:@selector(findFirstResponder:) to:nil from:nil forEvent:nil];
    return currentFirstResponder;
}

- (void)findFirstResponder:(id)sender {
    currentFirstResponder = self;
}
@end