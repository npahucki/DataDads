#import <XCTest/XCTest.h>
#import "NSDate+Utils.h"
#import "ExternalMediaFile.h"

@interface ExternalMediaFileTests : XCTestCase

@end

@implementation ExternalMediaFileTests

- (void)setUp {
    [super setUp];
    [Parse setApplicationId:@"NlJHBG0NZgFS8JP76DBjA31MBRZ7kmb7dVSQQz3U" clientKey:@"iMYPq4Fg751JyIOeHYnDH4LsuivOcm8uoi4DlwJ9"];
    [PFUser logInWithUsername:@"test2@test.com" password:@"password"];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testFileUploadToKnownURL {
    ExternalMediaFile * file = [ExternalMediaFile mediaFileFromUrl:[self createFileToUpload]];
    
    XCTestExpectation * expect = [self expectationWithDescription:@"Save Object"];

    [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        XCTAssert(!error);
        XCTAssert(succeeded);
        [expect fulfill];
    } progressBlock:^(int percentDone) {
        NSLog(@"Percent %d", percentDone);
    }];
    
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

- (void)testCallbackOnNon200StatusCode {
    ExternalMediaFile * file = [ExternalMediaFile mediaFileFromUrl:[self createFileToUpload]];
    [file setValue:@"http://dpmfmedia.s3.amazonaws.com/IMG_0325.JPG?AWSAccessKeyId=XX&Signature=YY" forKey:@"_externalUrl"];
    
    XCTestExpectation * expect = [self expectationWithDescription:@"Save Object"];
    [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        NSLog(@"DONE! Succeeded:%d Error:%@", succeeded, error);
        [expect fulfill];
    } progressBlock:^(int percentDone) {
        NSLog(@"Percent %d", percentDone);
    }];
    
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

-(NSURL *) createFileToUpload {
    NSString *tmpDirectory = NSTemporaryDirectory();
    NSString *tmpFile = [tmpDirectory stringByAppendingPathComponent:@"temp.txt"];
    NSData *data = [@"This is a test file - YAYA!" dataUsingEncoding:NSUTF8StringEncoding];
    [data writeToFile:tmpFile atomically:YES];
    return [NSURL fileURLWithPath:tmpFile];
}




@end
