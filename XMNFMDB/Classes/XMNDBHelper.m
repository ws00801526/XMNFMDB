//
//  XMNDBHelper.m
//  XMNFMDBExample
//
//  Created by XMFraker on 17/1/11.
//  Copyright © 2017年 XMFraker. All rights reserved.
//

#import "XMNDBHelper.h"
#import <sqlite3.h>

#import "NSObject+XMNUtils.h"
#import "NSObject+XMNDBModel.h"

@interface XMNDBHelper ()
{
    NSString *_encryptionKey;
}

@property (weak, nonatomic)   FMDatabase *usingdb;
@property (strong, nonatomic) FMDatabaseQueue *dbQueue;
@property (copy, nonatomic)   NSString *dbpath;
@property (strong, nonatomic) NSRecursiveLock *lock;
@property (strong, nonatomic) NSMutableSet *createdTableNames;

@property (strong, nonatomic) dispatch_queue_t asyncQueue;


@end

@implementation XMNDBHelper

#pragma mark - Life Cycle

- (instancetype)init {
    
    return [self initWithName:@"XMNDB"];
}

- (instancetype)initWithName:(NSString *)dbname {
    
    return [self initWithPath:[XMNDBHelper dbpathWithDBName:dbname]];
}

- (instancetype)initWithPath:(NSString *)dbpath {
    
    NSAssert(dbpath, @"数据库路径不能为空");
    
    if (self = [super init]) {
        
        self.lock = [[NSRecursiveLock alloc] init];
        self.createdTableNames = [NSMutableSet set];
        
        self.asyncQueue = dispatch_queue_create("XMNDB query async queue", DISPATCH_QUEUE_CONCURRENT);
        [self setDBPath:dbpath];
    }
    return self;
}

- (void)dealloc {
    
    NSLog(@"%@  dealloc",self);
    [self.dbQueue close];
    self.usingdb = nil;
    self.dbQueue = nil;
    self.dbpath = nil;
    self.lock = nil;
}

#pragma mark - Method

- (void)setDBName:(nonnull NSString *)dbname {
    
    [self setDBPath:[XMNDBHelper dbpathWithDBName:dbname]];
}

- (void)setDBPath:(nonnull NSString *)dbpath {
    
    if (self.dbQueue && [self.dbpath isEqualToString:dbpath]) {
        XMNLogInfo(@"数据库已经存在");
        return;
    }

    [self.lock lock];
    self.dbpath = dbpath;
    
    if ([NSFileManager xmn_fileExists:dbpath]) { /** 如果文件存在,修改文件的权限,防止因为权限问题导致数据库无法开启 */
        NSError *error;
        [[NSFileManager defaultManager] setAttributes:@{NSFileProtectionKey : NSFileProtectionNone} ofItemAtPath:dbpath error:&error];
        if (error) {
            XMNLogWarning([NSString stringWithFormat:@"修改文件权限失败 :%@ \n %@",dbpath, error.debugDescription]);
        }
    }
    
    /** 关闭之前打开的数据库链接 */
    [self.dbQueue close];
    [self.createdTableNames removeAllObjects];
    
    /** 重新创建数据库链接 */
    self.dbQueue = [[FMDatabaseQueue alloc] initWithPath:dbpath
                                                   flags:SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FILEPROTECTION_NONE];
    _encryptionKey = nil;
    [self.dbQueue inDatabase:^(FMDatabase *db) {
       
        db.logsErrors = [XMNDBHelper xmn_dbLogError];
    }];
    
    [self.lock unlock];
}

- (NSString *)encrptKey {
    
    NSString *key;
    [self.lock lock];
    key = [_encryptionKey copy];
    [self.lock unlock];
    return key;
}

#pragma mark - Class Method


/**
 获取数据库路径
 
 @param dbname 数据库名称
 @return 数据库存放路径
 */
+ (NSString *)dbpathWithDBName:(NSString *)dbname {

    NSString *filename = dbname;
    if (![filename hasSuffix:@".db"]) {
        filename = [dbname stringByAppendingString:@".db"];
    }
    NSString *filepath = [NSFileManager xmn_filePathForDocuments:filename inDir:@"db"];
    return filepath;
}


/**
 获取查询语句SQL

 @param querySQL 查询语句SQL
 @param where    查询条件
 @param values   查询条件对应值
 */
+ (void)extractQuerySQL:(NSString **)querySQL where:(id)where values:(NSArray **)values {
    
    if ([*querySQL xmn_isEmpty]) {
        return;
    }
    if ([where isKindOfClass:[NSString class]]) {
        *querySQL = [*querySQL stringByAppendingFormat:@" where %@",where];
    }else if ([where isKindOfClass:[NSDictionary class]]) {
     
        NSString *whereKey = [self transSQLFromDictionary:where toValues:values];
        *querySQL = [*querySQL stringByAppendingFormat:@" where %@",  whereKey];
    }
}


/**
 将dictionary 转换成查询条件

 @param dictionary 需要转换的dictionary
 @param values     转换的values
 @return 转换后的SQL
 */
+ (NSString *)transSQLFromDictionary:(NSDictionary<NSString *, id> *)dictionary
                            toValues:(NSArray **)values {
    
    if (!dictionary || !dictionary.count) {
        return @"";
    }
    NSMutableString *keys = [NSMutableString string];
    NSMutableArray *keyValues = [NSMutableArray arrayWithCapacity:dictionary.count];
    
    [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString  *key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        
        if ([obj isKindOfClass:[NSArray class]]) {
            /** 传入的object 是一个数组 */
            NSArray *vlist = obj;
            if (vlist.count == 0) {
                return;
            }
            if (keys.length > 0) {
                [keys appendString:@" and"];
            }
            [keys appendFormat:@" %@ in(%@)", key,[[vlist xmn_map:^id(id obj, NSInteger index) {
                return @"?";
            }] componentsJoinedByString:@","]];
        }else {
            /** 其他对象的object */
            if (keys.length) {
                [keys appendString:@" and"];
            }else {
                [keys appendFormat:@" %@=?",key];
            }
            [keyValues addObject:obj];
        }
    }];
    *values = [keyValues copy];
    return [keys copy];
}

@end


#pragma mark - XMNDBHelper (XMNDBCore)

@implementation XMNDBHelper (XMNDBCore)

- (void)executeDB:(void (^)(FMDatabase * _Nonnull))block {
    
    NSAssert(block, @"excuteDB block is nil!!!");
    
    [self.lock lock];
    if (self.usingdb) {
        
        block(self.usingdb);
    }else {
        
        if (!self.dbQueue) {
            /** 重新创建数据库链接 */
            self.dbQueue = [[FMDatabaseQueue alloc] initWithPath:self.dbpath
                                                           flags:SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FILEPROTECTION_NONE];
            [self.dbQueue inDatabase:^(FMDatabase *db) {
                
                db.logsErrors = [XMNDBHelper xmn_dbLogError];
                if (_encryptionKey && _encryptionKey.length) {
                    [db setKey:_encryptionKey];
                }
            }];
        }
        
        __weak typeof(*&self) wSelf = self;
        [self.dbQueue inDatabase:^(FMDatabase *db) {
           
            __strong typeof(*&wSelf) self = wSelf;
            self.usingdb = db;
            block(db);
            self.usingdb = nil;
        }];
    }
    [self.lock unlock];
}

- (void)executeTransaction:(nonnull BOOL(^)(XMNDBHelper * _Nonnull dbHelper))block {
    
    NSAssert(block, @"block is nil!!!");
    __weak typeof(*&self) wSelf = self;
    [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        __strong typeof(*&wSelf) self = wSelf;
        self.usingdb = db;
        *rollback = !block(self);
        self.usingdb = nil;
    }];
}

- (BOOL)executeUpdateSQL:(NSString *)sql withArguments:(NSArray *)arguments {
    
    __block BOOL success = NO;

    [self executeDB:^(FMDatabase * _Nonnull db) {
       
        if (arguments && arguments.count) {
            
            success = [db executeUpdate:sql withArgumentsInArray:arguments];
        }else {
            
            success = [db executeUpdate:sql];
        }
        if (db.hadError) {
            XMNLogError([NSString stringWithFormat:@"sql :%@ \n arguments : %@ \n sqlite error :%@ \n",sql,arguments, db.lastErrorMessage]);
        }
    }];
    return success;
}

- (NSString *)executeScalarSQL:(NSString *)sql withArguments:(NSArray *)arguments {
 
    __block NSString *result = nil;
    
    [self executeDB:^(FMDatabase *db) {
        
        FMResultSet *set = nil;
        if (arguments && arguments.count) {
            set = [db executeQuery:sql withArgumentsInArray:arguments];
        }else {
            set = [db executeQuery:sql];
        }
        
        if (db.hadError) {
            XMNLogError([NSString stringWithFormat:@"sql :%@ \n arguments : %@ \n sqlite error :%@ \n",sql,arguments, db.lastErrorMessage]);
        }
        
        if (([set columnCount] > 0) && [set next]) {
            result = [set stringForColumnIndex:0];
        }
        
        [set close];
    }];
    
    return result;
}

@end


#pragma mark - XMNDB数据库相关管理方法

@implementation XMNDBHelper (XMNDBManager)

/**
 判断对应class的数据表是否已经创建
 
 @param clazz 需要判断的clazz
 @return YES or NO
 */
- (BOOL)isTableCreatedWithClass:(nonnull Class)clazz {
    
    return [self isTableCreatedWithName:[clazz xmn_tableName]];
}

/**
 判断对应的表 是否已经创建
 
 @param tableName 表名
 @return YES or NO
 */
- (BOOL)isTableCreatedWithName:(nonnull NSString *)tableName {

    if ([tableName xmn_isEmpty]) {
        
        XMNLogWarning(@"table name is empty!!!!");
        return NO;
    }
    
    NSString *result = [self executeScalarSQL:@"select count(name) from sqlite_master where type='table' and name=?" withArguments:@[tableName]];
    
    if (result && [result respondsToSelector:@selector(integerValue)]) {
        return [result integerValue] >= 1;
    }
    return NO;
}

/**
 删除当前数据库内所有表
 */
- (void)dropAllTable {
    
    /** 关闭已经创建的数据库链接 */
    if (self.usingdb) {
        [self.usingdb close];
        self.usingdb = nil;
    }
    if (self.dbQueue) {
        [self.dbQueue close];
        self.dbQueue = nil;
    }
    
    /** 删除数据库文件 */
    [NSFileManager xmn_deleteFile:self.dbpath];
    [NSFileManager xmn_deleteFile:[NSFileManager xmn_directoryPathForDocuments:@"db_file"]];
    [NSFileManager xmn_deleteFile:[NSFileManager xmn_directoryPathForDocuments:@"db_image"]];
    
    /** 重新创建新的数据库 */
    [self setDBPath:[_dbpath copy]];
}

/**
 根据提供的clazz删除对应数据库表
 
 @param clazz 对应clazz
 @return 是否执行成功  YES or NO
 */
- (BOOL)dropTableWithClass:(nonnull Class)clazz {
    
    return [self dropTableWithName:[clazz xmn_tableName]];
}

/**
 根据提供的clazz删除对应数据库表
 
 @param tableName 对应表名
 @return 是否执行成功  YES or NO
 */
- (BOOL)dropTableWithName:(nonnull NSString *)tableName {
        
    NSString *dropSql = [NSString stringWithFormat:@"drop table if exists %@",tableName];
    BOOL isDroped = [self executeUpdateSQL:dropSql withArguments:nil];
    if (isDroped) {
        
        NSString *filePath = [NSFileManager xmn_directoryPathForDocuments:[NSString stringWithFormat:@"db_file/%@",tableName]];
        NSString *imagePath = [NSFileManager xmn_directoryPathForDocuments:[NSString stringWithFormat:@"db_image/%@",tableName]];
        
        [NSFileManager xmn_deleteFile:filePath];
        [NSFileManager xmn_deleteFile:imagePath];
        
        [self.lock lock];
        [self.createdTableNames removeObject:tableName];
        [self.lock unlock];
    }
    return isDroped;
}

@end


#pragma mark - XMNDB数据库查询语句

@implementation XMNDBHelper (XMNDBExecute)

- (void)fixTableOfClass:(nonnull Class)cls {
    
    if (!cls || ![cls xmn_tableName] || ![cls xmn_tableName].length) {
        
        XMNLogError(@"create cls table name is nil",cls);
        return;
    }
    
    if ([self isTableCreatedWithClass:cls]) {
        
        XMNLogInfo(@"cls table name is created : %@ \n will fix it",[cls xmn_tableName]);
        
        /** 备份之前数据 */
        NSString *backupTableName = [NSString stringWithFormat:@"%@_backup_%ld",[cls xmn_tableName],(NSInteger)[[NSDate date] timeIntervalSince1970]];
        NSString *backupTableSQL = [NSString stringWithFormat:@"alter table %@ rename to %@",[cls xmn_tableName],backupTableName];
        [self executeUpdateSQL:backupTableSQL withArguments:nil];
        
        /** 重新创建新的数据表 */
        NSArray *newColumns;
        NSString *createTableSQL = [cls xmn_createTableSQLWithName:[cls xmn_tableName] columnArray:&newColumns];
        BOOL success = [self executeUpdateSQL:createTableSQL withArguments:nil];
        if (success) {
            
            __block NSArray *oldColumns;
            [self executeDB:^(FMDatabase * _Nonnull db) {
                FMResultSet *resultSet = [db executeQuery:[NSString stringWithFormat:@"select * from %@ limit 0",backupTableName]];
                oldColumns = [resultSet.columnNameToIndexMap allKeys];
                [resultSet close];
            }];
            
            NSSet *newColumnSets = [NSSet setWithArray:newColumns];
            NSSet *oldColumnSets = [NSSet setWithArray:oldColumns];
            NSMutableSet *remainSets = [NSMutableSet setWithSet:newColumnSets];
            [remainSets intersectSet:oldColumnSets];
            
            NSString *copyDataSQL = [NSString stringWithFormat:@"replace into %@(%@) select %@ from %@",[cls xmn_tableName],[[remainSets allObjects] componentsJoinedByString:@","],[[remainSets allObjects] componentsJoinedByString:@","],backupTableName];
            BOOL copySuccess = [self executeUpdateSQL:copyDataSQL withArguments:nil];
            if (!copySuccess) {
                XMNLogError(@"copy data from %@ to %@ error",backupTableName,[cls xmn_tableName]);
            }else {
                
                XMNLogInfo(@"recreate table %@ success",[cls xmn_tableName]);
                /** 删除备份数据表 */
                [self dropTableWithName:backupTableName];
            }
            
            [self.lock lock];
            [self.createdTableNames addObject:[cls xmn_tableName]];
            [self.lock unlock];
        }else {
            XMNLogError(@"recreate table :%@ failed",[cls xmn_tableName]);
        }
        return;
    }
    
    NSString *createTableSQL = [cls xmn_createTableSQL];
    BOOL successed = [self executeUpdateSQL:createTableSQL withArguments:nil];
    if (successed) {
        XMNLogInfo(@"cls table name create success :%@",[cls xmn_tableName]);
        [self.lock lock];
        [self.createdTableNames addObject:[cls xmn_createTableSQL]];
        [self.lock unlock];
    }
    return;
}

- (NSInteger)queryCountOfClass:(nonnull Class)clazz where:(nullable id)where {
    
    return [self queryCountOfName:[clazz xmn_tableName] where:where];
}

- (NSInteger)queryCountOfName:(nonnull NSString *)tableName where:(nullable id)where {
    
    if ([tableName xmn_isEmpty]) {
        XMNLogWarning(@"query count tableName is empty!!!!");
        return 0;
    }
    
    NSString *querySQL = [NSString stringWithFormat:@"select count(rowid) from %@",tableName];
    NSArray *values;
    [XMNDBHelper extractQuerySQL:&querySQL where:where values:&values];
    return [[self executeScalarSQL:querySQL withArguments:values] integerValue];
}

- (void)queryCountOfClass:(nonnull Class)clazz where:(nullable id)where completionBlock:(nonnull void(^)(NSInteger count))completionBlock {
    
    __weak typeof(*&self) wSelf = self;
    dispatch_async(self.asyncQueue, ^{
       __strong typeof(*&wSelf) self = wSelf;
       NSInteger queryCount = [self queryCountOfClass:clazz where:where];
       dispatch_async(dispatch_get_main_queue(), ^{
           completionBlock ? completionBlock(queryCount) : nil;
       });
    });
}

/**
 判断对应的object是否存在
 
 @param model 需要判断的object
 @return YES or NO
 */
- (BOOL)isObjectExists:(nonnull NSObject *)model {
    
    if (!model) {
        XMNLogWarning(@"exists model is nil !!!");
        return NO;
    }
    NSString *where = [model xmn_primaryQueryCondition];
    
    if ([where xmn_isEmpty]) {
        return NO;
    }
    
    __block NSInteger rowid = 0;
    [self executeDB:^(FMDatabase *db) {
        
        FMResultSet *set = [db executeQuery:[NSString stringWithFormat:@"select rowid from %@ where %@",[[model class] xmn_tableName],where]];
        if ([set next]) {
            rowid = (NSInteger)[set longLongIntForColumn:@"rowid"];
        }
        [set close];
    }];
    
    if (model.rowID == 0 && rowid > 0) {
        /** 更新rowid */
        model.rowID = rowid;
    }
    return rowid > 0;
}

- (BOOL)isExistsWithClass:(nonnull Class)clazz where:(NSString *)where {
    
    return [self isExistsWithName:[clazz xmn_tableName] where:where];
}

- (BOOL)isExistsWithName:(nonnull NSString *)tableName where:(NSString *)where {
    
    if ([tableName xmn_isEmpty] || [where xmn_isEmpty]) {
        return NO;
    }
    
    NSString *count = [self executeScalarSQL:[NSString stringWithFormat:@"select rowid from %@ where %@",tableName,where] withArguments:nil];
    return count && [count respondsToSelector:@selector(integerValue)] && [count integerValue] >= 1;
}

- (nullable NSArray *)searchWithParams:(nonnull XMNDBQueryParams *)params {
    
    NSAssert(params && params.toCls, @"query params is not legal !!!");
    
    [self.lock lock];
    /** 查询表是否已经创建 */
    if (![self.createdTableNames containsObject:params.tableName]) {
        /** 需要查询的表未创建 */
        [self fixTableOfClass:params.toCls];
    }
    [self.lock unlock];
    
    __block NSArray<NSDictionary *> *rets;
    [self executeDB:^(FMDatabase * _Nonnull db) {
       
        FMResultSet *set = [db executeQuery:params.querySQL];
        NSMutableArray<NSDictionary *> *results = [NSMutableArray array];
        while ([set next] && results.count < params.count) {
            [results addObject:[set resultDictionary]];
        }
        rets = [results copy];
        [set close];
    }];

    return [[rets xmn_map:^id _Nonnull(NSDictionary * _Nonnull dbValue, NSInteger index) {
       
        return [params.toCls xmn_objectFromDBValue:dbValue] ? : [NSNull class];
    }] xmn_filter:^BOOL(id  _Nonnull obj) {
        
        return  !obj || [obj isKindOfClass:[NSNull class]];
    }];
}

- (nullable NSArray *)searchWithClass:(nonnull Class)cls
                              columns:(nullable NSArray<NSString *> *)columns
                                where:(nullable id)where
                              orderBy:(nullable NSString *)orderBy
                              groupBy:(nullable NSString *)groupBy
                               offset:(NSInteger)offset
                                count:(NSInteger)count {
    
    XMNDBQueryParams *queryParams = [[XMNDBQueryParams alloc] initWithToCls:cls];
    queryParams.columns = columns;
    if ([where isKindOfClass:[NSDictionary class]]) {
        queryParams.whereDictionary = where;
    }else if ([where isKindOfClass:[NSString class]]){
        queryParams.where = where;
    }
    
    queryParams.orderBy = orderBy;
    queryParams.groupBy = groupBy;
    queryParams.offset = offset;
    queryParams.count = count;
 
    return [self searchWithParams:queryParams];
}


- (BOOL)saveObject:(nonnull NSObject *)object {
    
    if (!object) {
        XMNLogWarning(@"save object is nil");
        return NO;
    }
    
    if ([self isObjectExists:object]) {
        return [self updateObject:object];
    }else {
        return [self insertObject:object];
    }
}

- (BOOL)saveObjects:(NSArray<NSObject *> *)objects {

    if (!objects || !objects.count) {
        XMNLogWarning(@"save object is nil");
        return NO;
    }
    
    __block BOOL success = NO;
    [self executeTransaction:^BOOL(XMNDBHelper * _Nonnull dbHelper) {

        success = ![objects xmn_any:^BOOL(NSObject * _Nonnull obj) {
            return ![dbHelper saveObject:obj];
        }];
        if (!success) {
            XMNLogWarning(@"transaction save objects failed will roll back");
        }
        return success;
    }];
    return success;
}

- (BOOL)insertObject:(nonnull NSObject *)object {

    if (!object) {
        XMNLogWarning(@"insert object is nil");
        return NO;
    }

    [self checkTableCreatedForClass:[object class]];
    
    __block BOOL success = NO;
    __block sqlite_int64 rowID = 0;
    [self executeDB:^(FMDatabase * _Nonnull db) {

        NSArray *insertValues;
        NSString *insertSQL = [object xmn_insertSQLWithValues:&insertValues];
        XMNLogInfo(@"insertSQL :%@",insertSQL);
        XMNLogInfo(@"insertValues :%@",insertValues);

        success = [db executeUpdate:insertSQL withArgumentsInArray:insertValues];
        rowID = db.lastInsertRowId;
    }];
    object.rowID = (NSInteger)rowID;
    return (success && rowID >= 0);
}

- (BOOL)insertObjects:(NSArray<NSObject *> *)objects {
    
    if (!objects || !objects.count) {
        XMNLogWarning(@"insert objects is nil");
        return NO;
    }
    
    __block BOOL success = NO;
    [self executeTransaction:^BOOL(XMNDBHelper * _Nonnull dbHelper) {
        
        success = ![objects xmn_any:^BOOL(NSObject * _Nonnull obj) {
            return ![dbHelper insertObject:obj];
        }];
        if (!success) {
            XMNLogWarning(@"transaction insert objects failed will roll back");
        }
        return success;
    }];
    return success;
}

- (BOOL)updateObject:(nonnull NSObject *)object {
    
    if (!object) {
        XMNLogWarning(@"insert object is nil");
        return NO;
    }

    [self checkTableCreatedForClass:[object class]];
    
    __block BOOL success = NO;
    __block sqlite_int64 rowID = 0;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        
        NSArray *updateValues;
        NSString *updateSQL = [object xmn_updateSQLWithValues:&updateValues];
        XMNLogInfo(@"updateSQL :%@",updateSQL);
        XMNLogInfo(@"updateValues :%@",updateValues);
        
        success = [db executeUpdate:updateSQL withArgumentsInArray:updateValues];
        
        FMResultSet *rowSet = [db executeQuery:[NSString stringWithFormat:@"select rowid from %@ where %@", [object.class xmn_tableName], object.xmn_primaryQueryCondition]];
        if ([rowSet next]) {
            rowID = [rowSet longLongIntForColumn:@"rowid"];
        }
        [rowSet close];
    }];
    if (object.rowID == 0 && rowID > 0) {
        object.rowID = (NSInteger)rowID;
    }
    return (success && rowID >= 0);
}

- (BOOL)updateObjects:(NSArray<NSObject *> *)objects {
    
    if (!objects || !objects.count) {
        XMNLogWarning(@"update objects is nil");
        return NO;
    }
    
    __block BOOL success = NO;
    [self executeTransaction:^BOOL(XMNDBHelper * _Nonnull dbHelper) {
        
        success = ![objects xmn_any:^BOOL(NSObject * _Nonnull obj) {
            return ![dbHelper updateObject:obj];
        }];
        if (!success) {
            XMNLogWarning(@"transaction update objects failed will roll back");
        }
        return success;
    }];
    return success;
}

- (BOOL)deleteObject:(NSObject *)object {
    
    if (!object) {
        XMNLogWarning(@"delete object is nil");
        return NO;
    }
    
    [self checkTableCreatedForClass:[object class]];
    
    __block BOOL success = NO;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        
        NSString *deleteSQL = [NSString stringWithFormat:@"delete from %@ where %@",[object.class xmn_tableName] , object.xmn_primaryQueryCondition];
        XMNLogInfo(@"deleteSQL :%@", deleteSQL);
        /** 执行SQL成功,并且数据库中object不存在,则代表删除成功 */
        success = [db executeUpdate:deleteSQL];
    }];
    if (success && [object respondsToSelector:@selector(setRowID:)]) {
        object.rowID = NSIntegerMax;
    }
    return success;
}

- (BOOL)deleteObjects:(NSArray<NSObject *> *)objects {
    
    if (!objects || !objects.count) {
        XMNLogWarning(@"delete objects is empty");
        return NO;
    }
    __block BOOL success = YES;
    [self executeTransaction:^BOOL(XMNDBHelper * _Nonnull dbHelper) {
       
        success = ![objects xmn_any:^BOOL(NSObject * _Nonnull obj) {
                        return ![dbHelper deleteObject:obj];
                   }];
        if (!success) {
            XMNLogWarning(@"transaction delete objects failed will roll back");
        }
        return success;
    }];
    return success;
}

/**
 检查对应的cls 表是否已经创建

 @param cls 需要检查的cls
 */
- (void)checkTableCreatedForClass:(Class)cls {

    [self.lock lock];
    if ([self.createdTableNames containsObject:[cls xmn_tableName]]) {
        return;
    }
    [self.lock unlock];
    
    [self fixTableOfClass:cls];
}

@end


#pragma mark - XMNDBHelper (XMNEncrypt)

static BOOL kXMNDBShouldLogErrorInfo = NO;
@implementation XMNDBHelper (XMNEncrypt)

- (BOOL)setEncryptionKey:(nullable NSString *)encryptionKey {
    
    [self.lock lock];
    _encryptionKey = [encryptionKey copy];
    [self.lock unlock];
    
    return YES;
}

@end

@implementation XMNDBHelper (XMNDBLog)

+ (BOOL)xmn_dbLogError {
    
    return kXMNDBShouldLogErrorInfo;
}

+ (void)xmn_setDBLogError:(BOOL)shouldLog {
    
    if (kXMNDBShouldLogErrorInfo == shouldLog) {
        return;
    }
    kXMNDBShouldLogErrorInfo = shouldLog;
}

@end
