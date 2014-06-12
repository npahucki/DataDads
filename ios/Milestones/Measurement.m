//
//  Measurement.m
//  Milestones
//
//  Created by Nathan  Pahucki on 6/12/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "Measurement.h"
#import <Parse/PFObject+Subclass.h>

@implementation Measurement

@dynamic unit;
@dynamic type;
@dynamic quantity;
@dynamic achievement;
@dynamic baby;

+ (NSString *)parseClassName {
  return @"Measurements";
}


@end
