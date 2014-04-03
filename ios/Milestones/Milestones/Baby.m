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

static Baby* _currentBaby;

+ (PFQuery*) queryForBabiesForUser:(PFUser*)user {
  PFQuery *query =  [self  query];
  [query whereKey:@"parentUserId" equalTo:user.objectId];
  return query;
}

-(NSInteger) daysSinceBirth {
  return [self daysSinceDate:self.birthDate];
}

-(NSInteger) daysSinceDueDate {
  return [self daysSinceDate:self.dueDate];
}

-(NSInteger) daysMissedDueDate {
  NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit fromDate:self.dueDate toDate:self.birthDate options:0];
  return [components day];
}

-(BOOL) wasBornPremature {
  return [self daysMissedDueDate] < 0;
}

-(NSInteger) daysSinceDate:(NSDate*) date {
  NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit fromDate:date toDate:[NSDate date] options:0];
  return [components day];
  
}

+ (NSString *)parseClassName {
  return @"Babies";
}

+ (Baby*) currentBaby {
  return _currentBaby;
}

+ (void) setCurrentBaby: (Baby*) baby {
  // If and only if the Baby object is different do we replace it and send the notfication again
  if(_currentBaby != baby) {
    _currentBaby = baby;
    // Let others know the current baby has changed so they can update thier views
    [[NSNotificationCenter defaultCenter]
        postNotificationName:kDDNotificationCurrentBabyChanged object:self userInfo:[NSDictionary dictionaryWithObject:_currentBaby forKey:@""]];
  }
}

@end
