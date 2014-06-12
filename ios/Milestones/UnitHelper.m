//
//  UnitHelper.m
//  Milestones
//
//  Created by Nathan  Pahucki on 6/12/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "UnitHelper.h"

@implementation UnitHelper


+(NSString *) unitForWeight {
  return [ParentUser currentUser].usesMetric ? @"kg" : @"lbs";
}

+(NSString *) unitForHeight {
  return [ParentUser currentUser].usesMetric ? @"cm" : @"in";
}


@end
