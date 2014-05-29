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
@dynamic parentUser;
@dynamic dueDate;
@dynamic birthDate;
@dynamic avatarImage;
@dynamic tags;
@dynamic isMale;

static Baby* _currentBaby;

+ (PFQuery*) queryForBabiesForUser:(PFUser*)user {
  PFQuery *query =  [self  query];
  [query whereKey:@"parentUser" equalTo:user];
  return query;
}

-(NSInteger) daysSinceBirth {
  return [self daysSinceDate:self.birthDate];
}

-(NSInteger) daysSinceDueDate:(NSDate *) otherDate {
  return [self daysDifference:self.dueDate toDate:otherDate];
}


-(NSInteger) daysSinceDueDate {
  return [self daysSinceDate:self.dueDate];
}

-(NSInteger) daysMissedDueDate {
  return [self daysDifference:self.dueDate toDate:self.birthDate];
}

-(BOOL) wasBornPremature {
  return [self daysMissedDueDate] < 0;
}

-(NSInteger) daysSinceDate:(NSDate*) date {
  return [self daysDifference:date toDate:[NSDate date]];
}

-(NSInteger) daysDifference:(NSDate*) fromDate toDate:(NSDate*) toDate  {
  NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit fromDate:fromDate toDate:toDate  options:0];
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
     postNotificationName:kDDNotificationCurrentBabyChanged object:self userInfo:baby == nil ? nil : [NSDictionary dictionaryWithObject:_currentBaby forKey:@""]];
  }
}

@end
