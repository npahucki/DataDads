//
//  BabyAssignedTip.m
//  Milestones
//
//  Created by Nathan  Pahucki on 5/28/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <Parse/PFObject+Subclass.h>


@implementation BabyAssignedTip

@dynamic baby;
@dynamic tip;
@dynamic isHidden;

+ (NSString *)parseClassName {
  return @"BabyAssignedTips";
}


@end
