//
//  XMNTestLogger.m
//  XMNFMDB
//
//  Created by XMFraker on 17/2/13.
//  Copyright © 2017年 ws00801526. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NSObject+XMNUtils.h"

@interface XMNTestLogger : XCTestCase

@end

@implementation XMNTestLogger

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}



- (void)testLogInfo {
    
    /** 设置当前可打印日志为 debug 级别 */
    XMNLogSetLoggerLevel(XMNLogLevelInfo);
    [self logAll];
}

- (void)testLogDebug {
    
    /** 设置当前可打印日志为 debug 级别 */
    XMNLogSetLoggerLevel(XMNLogLevelDebug);
    [self logAll];
}

- (void)testLogWarning {
    
    /** 设置当前可打印日志为 warning 级别 */
    XMNLogSetLoggerLevel(XMNLogLevelWarning);
    [self logAll];
}

- (void)logAll {
    
    XMNLogDebug(@"debug 日志");
    XMNLogInfo(@"info 日志");
    
    XMNLogNotice(@"notice 日志");
    XMNLogWarning(@"warning 日志");
    
    XMNLogError(@"error 日志");
    XMNLogCritical(@"critical 日志");
    
    XMNLogAlert(@"alert 日志");
    XMNLogEmergency(@"emergency 日志");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}



@end
