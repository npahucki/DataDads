//
//  Tag.h
//  Milestones
//
//  Created by Nathan  Pahucki on 1/29/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <Parse/Parse.h>

@interface Tag : PFObject <PFSubclassing>

+ (NSString *)parseClassName;

@property NSString *languageId;
@property NSString *tagName;

@end
