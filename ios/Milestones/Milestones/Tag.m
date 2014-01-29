//
//  Tag.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/29/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "Tag.h"
#import <Parse/PFObject+Subclass.h>

@implementation Tag

@dynamic languageId;
@dynamic tagName;
@dynamic relevance;

+ (NSString *)parseClassName {
  return @"Tags";
}


@end
