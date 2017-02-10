//
//  XMNDBTest.m
//  XMNFMDBExample
//
//  Created by XMFraker on 17/1/23.
//  Copyright © 2017年 XMFraker. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "XMNTeacher.h"
#import "NSObject+XMNUtils.h"
#import "NSObject+XMNDBModel.h"
#import "NSObject+XMNDBHelper.h"

#ifndef XMNASYNC_TEST_START
#define XMNASYNC_TEST_START                 __block BOOL hasCalledBack = NO;
#define XMNASYNC_TEST_DONE                  hasCalledBack = YES;
#define XMNASYNC_TEST_END_TIMEOUT(timeout)  NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:timeout];\
while (hasCalledBack == NO && [loopUntil timeIntervalSinceNow] > 0) { \
[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:loopUntil]; \
} \
if (!hasCalledBack) { XCTFail(@"Timeout"); }
#define XMNASYNC_TEST_END                   XMNASYNC_TEST_END_TIMEOUT(10)
#endif

@interface XMNDBTest : XCTestCase

@end

@implementation XMNDBTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [XMNDBHelper xmn_setDBLogError:YES];
    
//    XMNLogSetLoggerLevel(XMNLogLevelWarning);
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

- (void)testCreateDB {

    NSAssert([NSFileManager xmn_fileExists:[XMNTeacher xmn_usingDBHelper].dbpath], @"create db failed");
    
    NSLog(@"create db :%@ \nsql :%@",[XMNTeacher xmn_tableName],[XMNTeacher xmn_createTableSQL]);
}

- (void)testDropDB {
    
    [[XMNStudent xmn_usingDBHelper] dropAllTable];
}

- (void)testInsertDB {

    XMNLogInfo(@"db path :%@",[XMNTeacher xmn_usingDBHelper].dbpath);
    
    XMNTeacher *teacher = [[XMNTeacher alloc] init];
    teacher.name = @"Jhon Smith";
    teacher.age = 32;

    NSAssert([teacher xmn_saveOrUpdate], @"insert db failed");
    
    teacher.age = -10;
    NSAssert(![teacher xmn_saveOrUpdate], @"age is not valid cannot be saved but its succed");
    
    teacher.name = nil;
    NSAssert(![teacher xmn_saveOrUpdate], @"name is nil cannot be saved but its succed");
}

- (void)testInsertDBs {
    
    XMNTeacher *teacher = [[XMNTeacher alloc] init];
    teacher.name = @"Will Smith";
    teacher.age = 18;
    teacher.faceColor = [UIColor yellowColor];
    teacher.rect = CGRectMake(0, 100, 200, 300);
    teacher.mutableName = [NSMutableString stringWithString:@"Will Smith Mutable"];
    
    XMNClass *teacClass = [[XMNClass alloc] init];
    teacClass.name = @"数学";
    teacClass.time = @"2015-10-22 13:11:10";

    teacher.teacClass = teacClass;
    
//    NSAssert([teacher xmn_saveDB], @"insert db failed");
    
    NSMutableArray *students = [NSMutableArray array];
    for (int i = 0; i< 100; i++) {
        XMNStudent *student = [[XMNStudent alloc] init];
        student.name = [NSString stringWithFormat:@"student_%02d",i];
        student.age = arc4random() % 100 + 5;
        [students addObject:student];
    }
    
    for (int i = 0; i<50; i++) {
        
        [students addObject:@(i * (arc4random() % 5))];
    }
    
    [students addObject:[NSDate date]];
    [students addObject:RGB(100, 200, 100)];
    teacClass.students = [students copy];
    
    XMNTick
    [[XMNTeacher xmn_usingDBHelper] executeTransaction:^BOOL(XMNDBHelper * _Nonnull dbHelper) {
       
        [teacher xmn_saveOrUpdate];

//        for (int i = 0; i < 3000; i++) {
//            
//            teacher.name = [NSString stringWithFormat:@"teacher :%d",i];
//            [teacher xmn_saveDB];
//        }
        return YES;
    }];
    XMNTock
    
    [self testQueryDB];
}


- (void)testInsertHugeStudents {
    
    [[XMNStudent xmn_usingDBHelper] dropTableWithClass:[XMNStudent class]];
    
    XMNLogSetLoggerLevel(XMNLogLevelWarning);
    XMNTick
    NSMutableArray *students = [NSMutableArray array];
    for (int i = 0; i < 10000; i ++) {
        XMNStudent *student = [[XMNStudent alloc] init];
        student.name = [NSString stringWithFormat:@"student_%05d",i];
        student.age = arc4random() % 100 + 5;
        [students addObject:student];
    }
    BOOL success = [[XMNStudent xmn_usingDBHelper] insertObjects:students];
    XMNTock
    XMNLogSetLoggerLevel(XMNLogLevelInfo);
    XCTAssertTrue(success);
}

- (void)testQueryDB {
    
    __block XMNTick
    XMNASYNC_TEST_START
    [XMNStudent xmn_objectsWithQueryParams:nil
                           completionBlock:^(NSArray * _Nonnull objects) {
                              
                               NSLog(@"async objects");
                               XMNTock
                               XMNASYNC_TEST_DONE
                           }];
    XMNASYNC_TEST_END
    

    //    [self measureBlock:^{
//        [XMNStudent xmn_allObjects];
//    }];
    
//    NSArray *objects = [[XMNTeacher xmn_usingDBHelper] searchWithClass:[XMNTeacher class] columns:nil where:nil orderBy:nil groupBy:nil offset:0 count:NSIntegerMax];
//    NSLog(@"objects :%@",objects);
    
//    NSArray *allObjects = [XMNTeacher xmn_allObjects];
//    NSLog(@"all Objects :%@",allObjects);
//    XCTAssertNotNil(allObjects);
    
//    XMNTeacher *rowIDTeacher = [XMNTeacher xmn_objectForRowID:1];
//    NSLog(@"this is rowID TEACHER :%@",rowIDTeacher);
//    XCTAssertNotNil(rowIDTeacher);
//    
//    XMNTeacher *primaryKeyTeacher = [XMNTeacher xmn_objectForPrimaryKeys:@{@"name" : @"Will Smith"}];
//    NSLog(@"this is primaryKeyTeacher TEACHER :%@",primaryKeyTeacher);
//    XCTAssertNotNil(primaryKeyTeacher);
//    
//    {
//        XMNDBQueryParams *queryParams = [[XMNDBQueryParams alloc] initWithToCls:[XMNStudent class]];
//        queryParams.count = 20;
//        queryParams.offset = 20;
//        //    queryParams.where = @"name > 'student_40'";
//        queryParams.whereDictionary = @{@"name" : @"> 'student_60'"};
//        NSArray *queryStudents = [XMNStudent xmn_objectsWithQueryParams:queryParams];
//        XCTAssertNotNil(queryStudents);
//    }
//    
//    {
//        NSArray *queryStudents = [XMNStudent xmn_objectsWithWhereCondition:@{@"name" : @"> 'student_60'"}];
//        XCTAssertNotNil(queryStudents);
//    }
//    
//    
//    {
//        XMNDBQueryParams *queryParams = [[XMNDBQueryParams alloc] initWithToCls:[XMNStudent class]];
//        queryParams.orderBy = @"myage desc";
//        //    queryParams.where = @"name > 'student_40'";
//        queryParams.whereDictionary = @{@"name" : @"> 'student_60'"};
//        NSArray *queryStudents = [XMNStudent xmn_objectsWithQueryParams:queryParams];
//        XCTAssertNotNil(queryStudents);
//    }
}

- (void)testDeleteObject {
    
//    XMNStudent *student = [XMNStudent xmn_objectForRowID:99];
    XMNStudent *student = [XMNStudent xmn_objectForPrimaryKeys:@{@"name" : @"student_98"}];

    if (student) {
        BOOL success =  [student xmn_deleteObject];
        if (success) {
            /** 重新添加会数据库 */
            [student xmn_saveOrUpdate];
        }
        XCTAssertTrue(success);
    }
}


/**
 测试事物删除objects
 */
- (void)testDeleteObjects {
    
    NSArray <XMNStudent *> *students = [XMNStudent xmn_objectsWithWhereCondition:@{@"name" : @"> 'student_58'"}];
    
//    [students lastObject].rowID = NSIntegerMax;
//    [students lastObject].name = @"dsakdsald;sa";
    BOOL success = [[XMNStudent xmn_usingDBHelper] deleteObjects:students];
    if (success) {
        
        /** 重新添加会数据库 */
//        [self testInsertObjects:students];
    }
    XCTAssertTrue(success);
}

- (void)testInsertObjects:(NSArray *)objects {
    
    BOOL success = [[XMNStudent xmn_usingDBHelper] insertObjects:objects];
    XCTAssertTrue(success);
}

@end
