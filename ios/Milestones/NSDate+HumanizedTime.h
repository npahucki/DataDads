//
//  NSDate+HumanizedTime.h
//  DataParenting
//
//  Created by Nathan  Pahucki on 6/19/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (HumanizedTime)

- (NSString *)stringWithHumanizedTimeDifference;

- (NSString *)stringWithHumanizedTimeDifference:(BOOL)withSuffix;

@end