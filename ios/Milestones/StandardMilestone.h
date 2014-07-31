//
//  StandardMilestone.h
//  Milestones
//
//  Created by Nathan  Pahucki on 1/31/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>


@interface StandardMilestone : PFObject <PFSubclassing>

+ (NSString *)parseClassName;

@property NSString *title;
@property(readonly) NSString *titleForCurrentBaby;
@property NSString *enteredBy;
@property NSString *url;
@property NSNumber *rangeLow;
@property NSNumber *rangeHigh;
@property BOOL canCompare;

@property(readonly) NSString *humanReadableRange;

/*!
 * Returns the title with the correct pronoun replacements for the provided baby.
 */
- (NSString *)titleForBaby:(Baby *)baby;

@end
