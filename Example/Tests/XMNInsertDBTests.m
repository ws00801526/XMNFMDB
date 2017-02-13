//
//  XMNInsertDBTests.m
//  XMNFMDB
//
//  Created by XMFraker on 17/2/13.
//  Copyright © 2017年 ws00801526. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <YYModel/YYModel.h>

#import "NSObject+XMNUtils.h"
#import "NSObject+XMNDBHelper.h"

@interface XMNTestPerson : NSObject

@property (assign, nonatomic) NSInteger age;
@property (assign, nonatomic) BOOL sex;
@property (copy, nonatomic)   NSString *name;


@property (assign, nonatomic, getter=isSingle) BOOL single;


@end

@implementation XMNTestPerson

+ (NSSet<NSString *> *)xmn_primaryKeys {
    
    return [NSSet setWithArray:@[@"name"]];
}

- (BOOL)isSingle {
    
    return _single;
}

@end


@interface XMNTestTeacher : XMNTestPerson

@property (copy, nonatomic)   NSString *failmyName;


@end

@implementation XMNTestTeacher

/** 测试子类重写primaryKeys */
//+ (NSSet<NSString *> *)xmn_primaryKeys {
//    
//    return [NSSet setWithArray:@[@"failmyName"]];
//}

@end

@interface XMNInsertDBTests : XCTestCase

@property (strong, nonatomic) XMNTestTeacher *teacher;

@end

@implementation XMNInsertDBTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    id json = @{@"age" : @"15",
                @"name" : @"Will Smith",
                @"sex" : @0};
    
    self.teacher = [XMNTestTeacher yy_modelWithJSON:json];
    self.teacher.single = YES;
    NSLog(@"this is db path : %@",[[NSObject xmn_usingDBHelper] dbpath]);
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInsertSingleObject {
    
    XMNTestTeacher *queryTeacher;
    
    BOOL insertSuccess = [self.teacher xmn_insert];
    XCTAssertTrue(insertSuccess);
    
    /** 测试使用primaryKey 查询teacher */
    queryTeacher = [XMNTestTeacher xmn_objectForPrimaryKeys:@{@"name" : @"Will Smith"}];
    XCTAssertNotNil(queryTeacher);
    XCTAssertEqualObjects(queryTeacher.name, @"Will Smith");
//    XCTAssertEqual(queryTeacher.age, 15);
    XCTAssertEqual(queryTeacher.sex, 0);
    
    self.teacher.age = 20;
    BOOL updateSuccess = [self.teacher xmn_saveOrUpdate];
    XCTAssertTrue(updateSuccess);

    queryTeacher = [XMNTestTeacher xmn_objectForPrimaryKeys:@{@"name" : @"Will Smith"}];
    XCTAssertEqual(queryTeacher.age, 20);
}

- (void)testInsertHugeObjects {
    
    XMNLogSetLoggerLevel(XMNLogLevelWarning);
    NSMutableArray *persons = [NSMutableArray array];
    for (int i = 0; i < 20000; i ++) {
        XMNTestPerson *person = [[XMNTestPerson alloc] init];
        person.name = [NSString stringWithFormat:@"Person :%ld",(long)i];
        person.age = arc4random()  % 100 + 1;
        person.sex = arc4random() % 2 ;
        person.age = arc4random() % 2;
        [persons addObject:person];
    }
    
    BOOL insertSuccess = [[XMNTestPerson xmn_usingDBHelper] insertObjects:persons];
    XCTAssertTrue(insertSuccess);
    XMNLogSetLoggerLevel(XMNLogLevelInfo);
}


- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        [self testInsertSingleObject];
    }];
}

@end
