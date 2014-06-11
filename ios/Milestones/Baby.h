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
@property PFUser *parentUser;
@property NSDate *birthDate;
@property NSDate *dueDate;
@property BOOL isMale;
@property NSArray* tags;
@property PFFile* avatarImage;
@property PFFile* avatarImageThumbnail;

@property (readonly) NSInteger daysSinceBirth;
@property (readonly) NSInteger daysSinceDueDate;
@property (readonly) NSInteger daysMissedDueDate;
@property (readonly) BOOL wasBornPremature;

/**
 Returns a query that queries all the babies for the user passed in
*/
+ (PFQuery*) queryForBabiesForUser:(PFUser*)user;
+ (Baby*) currentBaby;
+ (void) setCurrentBaby:(Baby*)baby;

-(NSInteger) daysSinceDueDate:(NSDate *) otherDate;
-(NSInteger) daysSinceBirthDate:(NSDate *) otherDate;



@end


