//
//  XMNDBHelper.h
//  XMNFMDBExample
//
//  Created by XMFraker on 17/1/11.
//  Copyright © 2017年 XMFraker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FMDB/FMDB.h>


/**
 *  处理FMDB,查找,更新DB数据库
 *
 */
@interface XMNDBHelper : NSObject

@property (copy, nonatomic, readonly, nonnull)   NSString *dbpath;

/**
 创建数据库.db文件
 
 默认创建路径为  "documents/db/" + dbname + ".db"

 @param dbname 数据库名称
 @return XMNDBHelper 实例 or nil
 */
- (nullable instancetype)initWithName:(nonnull NSString *)dbname;

/**
 创建数据库.db文件

 @param dbpath 数据库路径
 @return XMNDBHelper 实例 or nil
 */
- (nullable instancetype)initWithPath:(nonnull NSString *)dbpath;

/**
 修改dbname
 
 @param dbname 新的数据库名称
 */
- (void)setDBName:(nonnull NSString *)dbname;

/**
 修改数据库路径

 @param dbpath 新的数据库路径
 */
- (void)setDBPath:(nonnull NSString *)dbpath;

@end

#pragma mark - XMNDB核心操作方法

@interface XMNDBHelper (XMNDBCore)


/**
 同步执行数据库操作

 @param block block内执行数据库方法
 */
- (void)executeDB:(nonnull void(^)(FMDatabase * _Nonnull db))block;


/**
 执行数据库 事物操作

 @param block 具体操作
 */
- (void)executeTransaction:(nonnull BOOL(^)(XMNDBHelper * _Nonnull dbHelper))block;

/**
 执行更新操作语句
 update,alert,create等
 @param sql       需要执行的数据库语句
 @param arguments 参数
 @return 是否执行成功
 */
- (BOOL)executeUpdateSQL:(nonnull NSString *)sql withArguments:(nullable NSArray *)arguments;


/**
 执行查询数据库数量语句
 获取对应sql的执行结果数量
 @param sql       需要执行的数据库语句
 @param arguments 参数
 @return 执行结果
 */
- (nullable NSString *)executeScalarSQL:(nonnull NSString *)sql  withArguments:(nullable NSArray *)arguments;

@end


#pragma mark - XMNDB数据库相关管理方法

@interface XMNDBHelper (XMNDBManager)


/**
 判断对应class的数据表是否已经创建

 @param clazz 需要判断的clazz
 @return YES or NO
 */
- (BOOL)isTableCreatedWithClass:(nonnull Class)clazz;

/**
 判断对应的表 是否已经创建

 @param tableName 表名
 @return YES or NO
 */
- (BOOL)isTableCreatedWithName:(nonnull NSString *)tableName;

/**
 删除当前数据库内所有表
 */
- (void)dropAllTable;

/**
 根据提供的clazz删除对应数据库表

 @param clazz 对应clazz
 @return 是否执行成功  YES or NO
 */
- (BOOL)dropTableWithClass:(nonnull Class)clazz;

/**
 根据提供的clazz删除对应数据库表
 
 @param tableName 对应表名
 @return 是否执行成功  YES or NO
 */
- (BOOL)dropTableWithName:(nonnull NSString *)tableName;

@end

#pragma mark - XMNDB数据库查询语句

@class XMNDBQueryParams;
@interface XMNDBHelper (XMNDBExecute)

/**
 获取查询结果条数

 @param clazz 查询的实例 class
 @param where 查询条件
 @return 查询结果 数量
 */
- (NSInteger)queryCountOfClass:(nonnull Class)clazz where:(nullable id)where;
- (NSInteger)queryCountOfName:(nonnull NSString *)tableName where:(nullable id)where;
- (void)queryCountOfClass:(nonnull Class)clazz where:(nullable id)where completionBlock:(nonnull void(^)(NSInteger count))completionBlock;

/**
 判断对应的object是否存在
 如果Object 有primaryKeys 优先使用 主键判断
 否则 使用rowid 进行判断
 @param object 需要判断的object
 @return YES or NO
 */
- (BOOL)isObjectExists:(nonnull NSObject *)object;
- (BOOL)isExistsWithClass:(nonnull Class)clazz where:(nullable id)where;
- (BOOL)isExistsWithName:(nonnull NSString *)tableName where:(nullable id)where;

- (nullable NSArray *)searchWithParams:(nonnull XMNDBQueryParams *)params;
- (nullable NSArray *)searchWithClass:(nonnull Class)cls
                              columns:(nullable NSArray<NSString *> *)columns
                                where:(nullable id)where
                              orderBy:(nullable NSString *)orderBy
                              groupBy:(nullable NSString *)groupBy
                               offset:(NSInteger)offset
                                count:(NSInteger)count;



/**
 对数据库内数据进行插入或者更新操作
 如果数据已经存在 执行更新操作
         不存在 执行插入操作

 @param object 需要操作的object
 @return YES or NO
 */
- (BOOL)saveObject:(nonnull NSObject *)object;

/**
 批量操作大量数据
 使用了数据库的事物操作, 任意一条失败,则执行回滚

 @param objects 需要操作的数据
 @return YES or NO
 */
- (BOOL)saveObjects:(nonnull NSArray<NSObject *> *)objects;

/**
 删除一个object
 
 @param object 需要删除的object
 @return 删除成功 或者 失败
 */
- (BOOL)deleteObject:(nonnull NSObject *)object;

/**
 同步删除批量数据
 使用了数据库的事物操作, 任意一条删除失败,则执行回滚
 
 @param objects  需要删除的objects
 @return YES or NO
 */
- (BOOL)deleteObjects:(nonnull NSArray<NSObject *> *)objects;

/**
 插入数据库

 @param object 需要插入的Object
 @return YES or NO
 */
- (BOOL)insertObject:(nonnull NSObject *)object;


/**
 批量插入大量数据
 使用了数据库的事物操作, 任意一条失败,则执行回滚

 @param objects 需要插入的数据
 @return YES or NO
 */
- (BOOL)insertObjects:(nonnull NSArray<NSObject *> *)objects;

/**
 执行数据库更新操作
 将object 插入 或者 更新数据
 如果object 存在   执行更新语句操作
 不存在 执行插入语句操作
 @param object  需要更新 或者插入的数据
 @return YES or NO
 */
- (BOOL)updateObject:(nonnull NSObject *)object;

/**
 批量更新数据库
 使用了数据库的事物操作, 任意一条失败,则执行回滚

 @param objects 需要更新的objects
 @return YES or NO
 */
- (BOOL)updateObjects:(nonnull NSArray<NSObject *> *)objects;

@end

#pragma mark - XMNDB加密相关

@interface XMNDBHelper (XMNEncrypt)

- (BOOL)setEncryptionKey:(nullable NSString *)encryptionKey;

@end

#pragma mark - XMNDB日志相关

@interface XMNDBHelper (XMNDBLog)

+ (BOOL)xmn_dbLogError;
+ (void)xmn_setDBLogError:(BOOL)shouldLog;

@end

