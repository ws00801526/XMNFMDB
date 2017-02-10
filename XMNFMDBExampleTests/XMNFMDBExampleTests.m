//
//  XMNFMDBExampleTests.m
//  XMNFMDBExampleTests
//
//  Created by XMFraker on 17/1/20.
//  Copyright © 2017年 XMFraker. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NSObject+XMNDBHelper.h"
#import "NSObject+XMNUtils.h"

@interface XMNFMDBExampleTests : XCTestCase

@end

@implementation XMNFMDBExampleTests

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


- (void)testUIColor {
    
    
    UIColor *rgbColor = [UIColor xmn_colorWithRed:255 green:0 blue:255];
    NSAssert(rgbColor, @"生产RGBColor 出错");
    
    UIColor *rgbaColor = [UIColor xmn_colorWithRed:255 green:0 blue:255 alpha:.5f];
    NSAssert(rgbaColor, @"生产RGBAColor 出错");
    
    UIColor *hexColor = [UIColor xmn_colorWithHexString:@"#ff00ff"];
    NSAssert(hexColor, @"生产hexColor 出错");

    UIColor *hexaColor = [UIColor xmn_colorWithHexString:@"#ff00ff" alpha:.5f];
    NSAssert(hexaColor, @"生产hexaColor 出错");

    UIColor *randomColor = [UIColor xmn_randomColor];
    NSAssert(randomColor, @"生产randomColor 出错");

    XMNLogInfo([NSString stringWithFormat:@"rgbColor :%@ \n rgbaColor :%@ \n hexColor :%@ \n hexaColor :%@ \n randomColor :%@ \n", rgbColor,rgbaColor,hexColor,hexaColor,randomColor]);
    
}

- (void)testUIColorWithMarco {
    
    UIColor *rgbColor = RGB(255, 0, 255);
    NSAssert(rgbColor, @"生产RGBColor 出错");
    
    UIColor *rgbaColor = RGBA(255, 0, 255, .5f);
    NSAssert(rgbaColor, @"生产RGBAColor 出错");
    
    UIColor *hexColor = HEXColor(@"0xff00ff");
    NSAssert(hexColor, @"生产hexColor 出错");
    
    UIColor *hexaColor = HEXAColor(@"0xff00ff", .5f);
    NSAssert(hexaColor, @"生产hexaColor 出错");
    
    UIColor *randomColor = RGBRandom;
    NSAssert(randomColor, @"生产randomColor 出错");
    
    XMNLogInfo([NSString stringWithFormat:@"rgbColor :%@ \n rgbaColor :%@ \n hexColor :%@ \n hexaColor :%@ \n randomColor :%@ \n", rgbColor,rgbaColor,hexColor,hexaColor,randomColor]);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
