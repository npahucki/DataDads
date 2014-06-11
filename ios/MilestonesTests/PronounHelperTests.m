//
//  PronounHelperTests.m
//  Milestones
//
//  Created by Nathan  Pahucki on 6/3/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PronounHelper.h"

@interface PronounHelperTests : XCTestCase

@property Baby* baby;

@end

@implementation PronounHelperTests

- (void)setUp
{
  [super setUp];
  self.baby = [Baby object];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testMaleBabyPronounReplacement
{
  self.baby.isMale = YES;
  NSString * testString = @"${He} does not like ${his} words fail ${him}. ${His} words are ${his:p} and ${he} relies on them";
  NSString * expectedString = @"He does not like his words fail him. His words are his and he relies on them";
  NSString * replacementString = [PronounHelper replacePronounTokens:testString forBaby:self.baby];
  NSLog(@"%@",replacementString);
  XCTAssertEqualObjects(replacementString , expectedString,@"At least one of the MALE pronouns was not replaced!");
}

- (void)testFemaleBabyPronounReplacement
{
  self.baby.isMale = NO;
  NSString * testString = @"${He} does not like ${his} words fail ${him}. ${His} words are ${his:p} and ${he} relies on them";
  NSString * expectedString = @"She does not like her words fail her. Her words are hers and she relies on them";
  NSString * replacementString = [PronounHelper replacePronounTokens:testString forBaby:self.baby];
  XCTAssertEqualObjects(replacementString , expectedString,@"At least one of the FEMALE pronouns was not replaced!");
}



@end
