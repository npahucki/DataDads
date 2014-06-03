//
//  BabyTests.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/29/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Baby.h"
#import "NSDate+Utils.h"

@interface BabyTests : XCTestCase

@end

@implementation BabyTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testPastDaysSinceBirthReturnsCorrectNumber
{
  Baby * baby = [Baby object];
  baby.birthDate = [NSDate dateInDaysFromNow:-2];
  XCTAssertEqual(baby.daysSinceBirth, 2);
}

- (void)testFutureDaysSinceBirthReturnsCorrectNumber
{
  Baby * baby = [Baby object];
  baby.birthDate = [NSDate dateInDaysFromNow:2];
  XCTAssertEqual(baby.daysSinceBirth, -1);
}


- (void)testPastDaysSinceDueReturnsCorrectNumber
{
  Baby * baby = [Baby object];
  baby.dueDate = [NSDate dateInDaysFromNow:-180];
  XCTAssertEqual(baby.daysSinceDueDate, (NSInteger) 180);
}

- (void)testFutureDaysSinceDueReturnsCorrectNumber
{
  Baby * baby = [Baby object];
  baby.dueDate = [NSDate dateInDaysFromNow:180];
  XCTAssertEqual(baby.daysSinceDueDate, (NSInteger) -179);
}

- (void)testFutureDaysSinceDueReturnsCorrectNumber2
{
  Baby * baby = [Baby object];
  baby.dueDate = [NSDate dateInDaysFromNow:180];
  XCTAssertEqual([baby daysSinceDueDate:[NSDate dateInDaysFromNow:181]], (NSInteger) 1);
}

- (void)testPastDaysSinceDueReturnsCorrectNumber2
{
  Baby * baby = [Baby object];
  baby.dueDate = [NSDate dateInDaysFromNow:1];
  XCTAssertEqual([baby daysSinceDueDate:[baby.dueDate dateByAddingDays:180]], (NSInteger) 180);
}




- (void)testDaysBetweenDueAndBirthDateWhenBornAfterDueDate
{
  Baby * baby = [Baby object];
  baby.dueDate = [NSDate dateInDaysFromNow:-3];
  baby.birthDate = [NSDate dateInDaysFromNow:-1];
  XCTAssertEqual(baby.daysMissedDueDate, (NSInteger)2);
  XCTAssertFalse(baby.wasBornPremature);
  
}

- (void)testDaysBetweenDueAndBirthDateWhenBornBeforeDueDate
{
  Baby * baby = [Baby object];
  baby.dueDate = [NSDate dateInDaysFromNow:1];
  baby.birthDate = [baby.dueDate dateByAddingDays:-5];
  NSLog(@"************* Due: %@, Birth: %@ Days: %ld", baby.dueDate, baby.birthDate, (long)baby.daysMissedDueDate);
  XCTAssertEqual(baby.daysMissedDueDate, (NSInteger)-5);
  XCTAssertTrue(baby.wasBornPremature);
  
}







@end
