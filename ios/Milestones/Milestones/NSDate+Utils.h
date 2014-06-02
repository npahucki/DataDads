//
//  NSDate+Utils.h
//  Milestones
//
//  Created by Nathan  Pahucki on 6/2/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (NSDate_Utils)

/*!
 * The difference in number of days from Now. If the result is negative, it means the target date happened N days before Now.
 * Postive denotes the target date happens after Now. 
 */
-(NSInteger) daysDifferenceFromNow;

/*!
 * The difference in days between the target date and the passed in date. If the result is negative, it means the date passed happened N days before
 * the target of the message, and postive denotes in the passed date happens after the target date.
 */
-(NSInteger) daysDifference:(NSDate*) toDate;

/*!
 * Returns a new date that it N days from Now. A negative number of days results in a past date
 * and a positive number a future date.
 */
+ (NSDate*) dateInDaysFromNow:(NSInteger)days;

/*!
 * Returns a new date that it N days from the target date. A negative number of days results in a past date 
 * and a positive number a future date.
 */
- (NSDate*) dateByAddingDays:(NSInteger)days;




@end
