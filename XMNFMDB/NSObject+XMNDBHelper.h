//
//  NSObject+XMNDBHelper.h
//  XMNFMDBExample
//
//  Created by XMFraker on 17/1/23.
//  Copyright © 2017年 XMFraker. All rights reserved.
//


#import "XMNDBHelper.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (XMNDBHelper)

/**
 获取当前Object 默认使用的DBHelper
 
 @return dbHelper 实例
 */
+ (XMNDBHelper *)xmn_usingDBHelper;


/**
 全局通用的日期格式化实例
 默认日期格式为 yyyy-MM-dd HH:mm:ss
 @return NSDateFormatter 实例
 */
+ (NSDateFormatter *)xmn_dateFormatter;

@end

@interface NSObject (XMNDBManagerUpdate)

/**
 执行数据库插入操作
 插入数据到数据库中, 已存在数据不做处理
 
 @return YES or NO
 */
- (BOOL)xmn_insert;

/**
 执行数据库更新操作
 如果数据库有此数据,则更新
 否则添加
 @return YES or NO
 */
- (BOOL)xmn_saveOrUpdate;

/**
 异步执行的 xmn_updateDB
 
 @param completionBlock 回调block
 */
- (void)xmn_saveOrUpdateWithCompletionBlock:(nullable void(^)(BOOL success))completionBlock;

/**
 删除当前Object
 
 @return YES or NO
 */
- (BOOL)xmn_deleteObject;

/**
 异步删除当前Object
 
 @param completionBlock 回调block
 */
- (void)xmn_deleteObjectWithCompletionBlock:(nullable void(^)(BOOL success))completionBlock;

@end


@interface NSObject (XMNDBHelperQuery)

/**
 根据主键从数据库中查询对应的NSObject对象
 
 @param     values 主键对应的值
 @return    NSOBject对象  or nil
 */
+ (nullable instancetype)xmn_objectForPrimaryKeys:(NSDictionary<NSString *, id> *)values;

/**
 根据rowID进行查询

 @param rowID 需要查询的rowID
 @return 查询结果
 */
+ (nullable instancetype)xmn_objectForRowID:(NSInteger)rowID;

/**
 配置查询条件进行查询

 @param queryParams 查询条件
 @return 查询结果
 */
+ (nullable NSArray *)xmn_objectsWithQueryParams:(XMNDBQueryParams *)queryParams;

/**
 获取符合where条件的所有数据

 @param whereCondition where条件  支持NSString or NSDictionary
 @return 查询结果
 */
+ (nullable NSArray *)xmn_objectsWithWhereCondition:(id)whereCondition;

/**
 获取当前Class所有的数据库结果

 @return 查询结果
 */
+ (nullable NSArray *)xmn_allObjects;


/**
 异步查询符合条件的objects

 @param queryParams     查询条件
 @param completionBlock 回调block
 */
+ (void)xmn_objectsWithQueryParams:(nullable XMNDBQueryParams *)queryParams
                   completionBlock:(void(^)(NSArray * objects))completionBlock;

/**
 异步查询符合条件的objects
 
 @param whereCondition     查询条件
 @param completionBlock     回调block
 */
+ (void)xmn_objectsWithWhereCondition:(nullable id)whereCondition
                      completionBlock:(void(^)(NSArray * objects))completionBlock;

@end

NS_ASSUME_NONNULL_END
