//
// Created by Nathan  Pahucki on 1/13/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface ParentUserTests : XCTestCase

@end

@implementation ParentUserTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testNameFromDevice {
    NSString *name;


    name = [ParentUser nameFromDeviceName:@"Nathan Pahucki's iPhone"];
    XCTAssert([name isEqualToString:@"Nathan Pahucki"], @"'%@' not equal to expected result", name);

    name = [ParentUser nameFromDeviceName:@"iPhone de Morgan Friedman"];
    XCTAssert([name isEqualToString:@"Morgan Friedman"], @"'%@' not equal to expected result", name);

    XCTAssertNil([ParentUser nameFromDeviceName:@"der iPhone von Pablo"]);
}

@end