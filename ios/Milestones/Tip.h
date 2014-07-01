//
//  Tip.h
//  Milestones
//
//  Created by Nathan  Pahucki on 5/28/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

typedef enum _TipType : NSUInteger {
  TipTypeNormal = 1,
  TipTypeWarning
  
} TipType;


@interface Tip : PFObject<PFSubclassing>

+ (NSString *)parseClassName;

@property NSString *title;
@property(readonly) NSString * titleForCurrentBaby;
@property NSString *shortDescription;
@property NSNumber* tipType;
@property NSString * url;

-(NSString*) titleForBaby:(Baby*) baby;

@end
