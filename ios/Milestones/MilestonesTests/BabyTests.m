//
//  BabyTests.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/29/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Baby.h"

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

- (void)testDaysSinceBirthReturnsCorrectNumber
{
  Baby * baby = [Baby object];
  baby.birthDate = [self dateFromDaysFromToday:-2];
  XCTAssert(baby.daysSinceBirth == 2);
}

- (void)testDaysSinceDueReturnsCorrectNumber
{
  Baby * baby = [Baby object];
  baby.dueDate = [self dateFromDaysFromToday:-180];
  XCTAssertEqual(baby.daysSinceDueDate, (NSInteger) 180);
}

- (void)testDaysBetweenDueAndBirthDateWhenBornAfterDueDate
{
  Baby * baby = [Baby object];
  baby.dueDate = [self dateFromDaysFromToday:-3];
  baby.birthDate = [self dateFromDaysFromToday:-1];
  XCTAssertEqual(baby.daysMissedDueDate, (NSInteger)2);
  XCTAssertFalse(baby.wasBornPremature);
  
}

- (void)testDaysBetweenDueAndBirthDateWhenBornBeforeDueDate
{
  Baby * baby = [Baby object];
  baby.dueDate = [self dateFromDaysFromToday:1];
  baby.birthDate = [self dateFor:-5 fromDate:baby.dueDate];
  NSLog(@"************* Due: %@, Birth: %@ Days: %ld", baby.dueDate, baby.birthDate, (long)baby.daysMissedDueDate);
  XCTAssertEqual(baby.daysMissedDueDate, (NSInteger)-5);
  XCTAssertTrue(baby.wasBornPremature);
  
}



- (NSDate*) dateFromDaysFromToday:(NSInteger)days {
  return [self dateFor:days fromDate:[NSDate date]];
}

- (NSDate*) dateFor:(NSInteger)days fromDate:(NSDate*)date {
  NSCalendar *gregorian = [[NSCalendar alloc]
                           initWithCalendarIdentifier:NSGregorianCalendar];
  NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
  [offsetComponents setDay:days];
  return [gregorian dateByAddingComponents:offsetComponents toDate:date options:0];
}



@end
