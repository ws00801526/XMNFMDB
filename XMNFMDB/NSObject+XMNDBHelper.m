//
//  NSObject+XMNDBHelper.m
//  XMNFMDBExample
//
//  Created by XMFraker on 17/1/23.
//  Copyright © 2017年 XMFraker. All rights reserved.
//

#import "NSObject+XMNDBHelper.h"
#import "NSObject+XMNUtils.h"
#import "NSObject+XMNDBModel.h"

static XMNDBHelper *dbHelper;
static NSDateFormatter *dateFormatter;
static dispatch_queue_t kXMNDBAsyncQueue;
static dispatch_once_t kXMNCreateDBAsyncQueueOnceToken;
@implementation NSObject (XMNDBHelper)

/**
 获取当前Object 默认使用的DBHelper
 
 @return dbHelper 实例
 */
+ (XMNDBHelper *)xmn_usingDBHelper {

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dbHelper = [[XMNDBHelper alloc] initWithName:@"com.XMFraker.XMNFMDB.db"];
    });
    return dbHelper;
}

+ (NSDateFormatter *)xmn_dateFormatter {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    });
    return dateFormatter;
}
@end


@implementation NSObject (XMNDBManagerUpdate)

- (BOOL)xmn_insert {
    
    if ([[self class] xmn_isSystemClass]) {
        
        XMNLogWarning(@"insert object is system class");
        return NO;
    }
    return [[[self class] xmn_usingDBHelper] insertObject:self];
}

- (BOOL)xmn_saveOrUpdate {
    
    if ([[self class] xmn_isSystemClass]) {

        XMNLogWarning(@"saveOrUpdate object is system class");
        return NO;
    }
    
    return [[[self class] xmn_usingDBHelper] saveObject:self];
}

- (void)xmn_saveOrUpdateWithCompletionBlock:(void (^)(BOOL))completionBlock {

    dispatch_once(&kXMNCreateDBAsyncQueueOnceToken, ^{
        kXMNDBAsyncQueue = dispatch_queue_create("com.XMFraker.XMNFMDB.kXMNDBAsyncQueue", DISPATCH_QUEUE_CONCURRENT);
    });
    
    __weak typeof(*&self) wSelf = self;
    dispatch_async(kXMNDBAsyncQueue, ^{
        __strong typeof(*&wSelf) self = wSelf;
        BOOL success = [self xmn_saveOrUpdate];
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock ? completionBlock(success) : nil;
        });
    });
}

/**
 删除当前Object
 
 @return YES or NO
 */
- (BOOL)xmn_deleteObject {
    
    if ([[self class] xmn_isSystemClass]) {
        XMNLogWarning(@"delete object is system class");
        return NO;
    }
    
    return [[[self class] xmn_usingDBHelper] deleteObject:self];
}

/**
 异步删除当前Object
 
 @param completionBlock 回调block
 */
- (void)xmn_deleteObjectWithCompletionBlock:(nullable void(^)(BOOL success))completionBlock {
    
    dispatch_once(&kXMNCreateDBAsyncQueueOnceToken, ^{
        kXMNDBAsyncQueue = dispatch_queue_create("com.XMFraker.XMNFMDB.kXMNDBAsyncQueue", DISPATCH_QUEUE_CONCURRENT);
    });
    
    __weak typeof(*&self) wSelf = self;
    dispatch_async(kXMNDBAsyncQueue, ^{
        __strong typeof(*&wSelf) self = wSelf;
        BOOL success = [self xmn_saveOrUpdate];
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock ? completionBlock(success) : nil;
        });
    });
}

@end

@implementation NSObject (XMNDBHelperQuery)

+ (nullable NSObject *)xmn_objectForPrimaryKeys:(NSDictionary *)values {
    
    if ([self xmn_isSystemClass]) {
        
        XMNLogWarning(@"query object is system class");
        return nil;
    }
    
    if (!values || !values.count) {
        XMNLogWarning(@"query object primary keys is nil");
        return nil;
    }
    
    XMNDBClassInfo *classInfo = [XMNDBClassInfo classInfoWithClass:self];
    NSArray <XMNDBPropertyInfo *> *primaryInfos = [[[values allKeys] xmn_map:^id _Nonnull(NSString  *obj, NSInteger index) {
        
        XMNDBPropertyInfo *propertyInfo = classInfo.propertyMapper[obj] ? : classInfo.columnMapper[obj];
        return propertyInfo ? : [NSNull null];
    }] xmn_filter:^BOOL(id  _Nonnull obj) {
        
        return [obj isKindOfClass:[NSNull class]];
    }];
    
    if (!primaryInfos || !primaryInfos.count) {
        
        XMNLogWarning(@"query object cannot find primary infos");
        return nil;
    }

    NSArray *whereConditions = [[primaryInfos xmn_filter:^BOOL(XMNDBPropertyInfo * _Nonnull obj) {
        return !obj.isPrimary || !obj.columnName || !obj.columnName.length;
    }] xmn_map:^id _Nonnull(XMNDBPropertyInfo * _Nonnull obj, NSInteger index) {
        
        NSString *key = obj.columnName;
        NSString *value = values[obj.columnName] ? : values[obj.propertyName];
        return [NSString stringWithFormat:@"%@ = '%@'", key, value];
    }];

    if (!whereConditions || !whereConditions.count) {
        XMNLogWarning(@"query object cannot get whereCoditions");
        return nil;
    }
    
    id object = [[[self xmn_usingDBHelper] searchWithClass:self
                                                   columns:nil
                                                     where:[whereConditions componentsJoinedByString:@"and"]
                                                   orderBy:nil
                                                   groupBy:nil
                                                    offset:0
                                                     count:1] firstObject];
    return object;
}


+ (nullable instancetype)xmn_objectForRowID:(NSInteger)rowID {
    
    if (rowID == NSNotFound) {
        XMNLogWarning(@"query object rowid is nil");
        return nil;
    }
    
    id object = [[[self xmn_usingDBHelper] searchWithClass:self
                                                   columns:nil
                                                     where:[NSString stringWithFormat:@"rowid = %@", @(rowID)]
                                                   orderBy:nil
                                                   groupBy:nil
                                                    offset:0
                                                     count:1] firstObject];
    return object;
}

+ (nullable NSArray<NSObject *> *)xmn_objectsWithWhereCondition:(id)whereCondition {
    
    return [[self xmn_usingDBHelper] searchWithClass:self
                                             columns:nil
                                               where:whereCondition
                                             orderBy:nil
                                             groupBy:nil
                                              offset:0
                                               count:NSUIntegerMax];
}

+ (nullable NSArray<NSObject *> *)xmn_objectsWithQueryParams:(XMNDBQueryParams *)queryParams {
    
    return [[self xmn_usingDBHelper] searchWithParams:queryParams];
}

+ (nullable NSArray<NSObject *> *)xmn_allObjects {
    
    return [[self xmn_usingDBHelper] searchWithClass:self
                                             columns:nil
                                               where:nil
                                             orderBy:nil
                                             groupBy:nil
                                              offset:0
                                               count:NSUIntegerMax];
}


/**
 异步查询符合条件的objects
 
 @param queryParams     查询条件
 @param completionBlock 回调block
 */
+ (void)xmn_objectsWithQueryParams:(XMNDBQueryParams *)queryParams
                   completionBlock:(void(^)(NSArray * objects))completionBlock {
    
    dispatch_once(&kXMNCreateDBAsyncQueueOnceToken, ^{
        kXMNDBAsyncQueue = dispatch_queue_create("com.XMFraker.XMNFMDB.kXMNDBAsyncQueue", DISPATCH_QUEUE_CONCURRENT);
    });
    
    __weak typeof(*&self) wSelf = self;
    dispatch_async(kXMNDBAsyncQueue, ^{
        __strong typeof(*&wSelf) self = wSelf;
        NSArray *objects = queryParams ? [self xmn_objectsWithQueryParams:queryParams] : [self xmn_allObjects];
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock ? completionBlock(objects) : nil;
        });
    });
}

/**
 异步查询符合条件的objects
 
 @param whereCondition     查询条件
 @param completionBlock     回调block
 */
+ (void)xmn_objectsWithWhereCondition:(id)whereCondition
                      completionBlock:(void(^)(NSArray * objects))completionBlock {
    
    dispatch_once(&kXMNCreateDBAsyncQueueOnceToken, ^{
        kXMNDBAsyncQueue = dispatch_queue_create("com.XMFraker.XMNFMDB.kXMNDBAsyncQueue", DISPATCH_QUEUE_CONCURRENT);
    });
    
    __weak typeof(*&self) wSelf = self;
    dispatch_async(kXMNDBAsyncQueue, ^{
        __strong typeof(*&wSelf) self = wSelf;
        NSArray *objects = whereCondition ? [self xmn_objectsWithWhereCondition:whereCondition] : [self xmn_allObjects];
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock ? completionBlock(objects) : nil;
        });
    });
}
@end
