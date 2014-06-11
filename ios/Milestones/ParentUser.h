//
//  ParentUser.h
//  Milestones
//
//  Created by Nathan  Pahucki on 6/5/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <Parse/Parse.h>

@interface ParentUser : PFUser<PFSubclassing>

@property NSString * screenName;
@property BOOL isMale;
@property BOOL autoPublishToFacebook;

@end