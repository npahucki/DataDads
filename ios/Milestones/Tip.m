//
//  Tip.m
//  Milestones
//
//  Created by Nathan  Pahucki on 5/28/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <Parse/PFObject+Subclass.h>
#import "PronounHelper.h"

@implementation Tip

@dynamic title;
@dynamic shortDescription;
@dynamic tipType;
@dynamic url;

-(NSString*) titleForBaby:(Baby*) baby {
  return [PronounHelper replacePronounTokens:self.title forBaby:baby];
}

-(NSString*) titleForCurrentBaby {
  return  [self titleForBaby:Baby.currentBaby];
}

+ (NSString *)parseClassName {
  return @"Tips";
}


@end
