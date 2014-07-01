//
//  StandardMilestone.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/31/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "StandardMilestone.h"
#import <Parse/PFObject+Subclass.h>
#import "PronounHelper.h"


@implementation StandardMilestone

@dynamic title;
@dynamic shortDescription;
@dynamic enteredBy;
@dynamic url;
@dynamic rangeHigh;
@dynamic rangeLow;
@dynamic canCompare;

-(NSString*) titleForBaby:(Baby*) baby {
  return [PronounHelper replacePronounTokens:self.title forBaby:baby];
}

-(NSString*) titleForCurrentBaby {
  return  [self titleForBaby:Baby.currentBaby];
}




+ (NSString *)parseClassName {
  return @"StandardMilestones";
}


@end
