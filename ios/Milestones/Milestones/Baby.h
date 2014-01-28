//
//  Baby.h
//  Milestones
//
//  Created by Nathan  Pahucki on 1/27/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <Parse/Parse.h>

@interface Baby : PFObject<PFSubclassing>

+ (NSString *)parseClassName;

@property NSString *name;
@property NSString *parentUserId;
@property NSDate *birthDate;
@property NSDate *dueDate;
@property BOOL isMale;
@property NSArray* tags;
@property PFFile* avatarImage;

@end
