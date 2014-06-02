//
//  NSDate+Utils.m
//  Milestones
//
//  Created by Nathan  Pahucki on 6/2/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "NSDate+Utils.h"

@implementation NSDate (NSDate_Utils)

+(NSDate*) dateInDaysFromNow:(NSInteger)days {
  return [[NSDate date] dateByAddingDays:days];
}


-(NSInteger) daysDifferenceFromNow {
  return [[NSDate date] daysDifference:self];
}

-(NSInteger) daysDifference:(NSDate*) toDate  {
  NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit fromDate:self toDate:toDate  options:0];
  return [components day];
}

- (NSDate*) dateByAddingDays:(NSInteger)days {
  NSCalendar *gregorian = [[NSCalendar alloc]
                           initWithCalendarIdentifier:NSGregorianCalendar];
  NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
  [offsetComponents setDay:days];
  return [gregorian dateByAddingComponents:offsetComponents toDate:self options:0];
}



@end
