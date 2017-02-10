//
//  XMNLogTest.m
//  XMNFMDBExample
//
//  Created by XMFraker on 17/1/20.
//  Copyright © 2017年 XMFraker. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NSObject+XMNUtils.h"

@interface XMNLogTest : XCTestCase

@end

@implementation XMNLogTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

- (void)testLog {
    
    NSLog(@"--------------------\n\n\n");
    
    XMNLogEmergency(@"this is log info with params :%@",@{@"haha" : @"----"});
    XMNLogWarning(@"this is log info with params :%@",@{@"haha" : @"----"});
    XMNLogAlert(@"this is log info with params :%@",@{@"haha" : @"----"});
    XMNLogCritical(@"this is log info with params :%@",@{@"haha" : @"----"});
    XMNLogError(@"this is log info with params :%@",@{@"haha" : @"----"});
    XMNLogDebug(@"this is log info with params :%@",@{@"haha" : @"----"});
    XMNLogInfo(@"this is log info with params :%@",@{@"haha" : @"----"});
    XMNLogNotice(@"this is log info with params :%@",@{@"haha" : @"----"});
    
    int loglevel = XMNCurrentLogLevel - 1;
    if (loglevel >= 0) {
        XMNLogSetLoggerLevel(loglevel);
        [self testLog];
    }
    
}

@end
