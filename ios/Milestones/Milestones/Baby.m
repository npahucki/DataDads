//
//  Baby.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/27/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "Baby.h"
#import <Parse/PFObject+Subclass.h>

@implementation Baby
@dynamic name;
@dynamic parentUserId;
@dynamic dueDate;
@dynamic birthDate;
@dynamic avatarImage;
@dynamic tags;
@dynamic isMale;

+ (NSString *)parseClassName {
  return @"Babies";
}
@end
