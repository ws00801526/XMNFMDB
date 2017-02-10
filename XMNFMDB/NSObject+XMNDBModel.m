//
//  NSObject+XMNDBModel.m
//  XMNFMDBExample
//
//  Created by XMFraker on 17/1/12.
//  Copyright © 2017年 XMFraker. All rights reserved.
//

#import "NSObject+XMNDBModel.h"
#import "NSObject+XMNUtils.h"
#import "NSObject+XMNDBHelper.h"

#import "XMNDBValueSupport.m"
#import "XMNDBModelSupport.m"

#import <objc/runtime.h>

static inline NSString *XMNColumnTypeString(XMNDBColumnType type) {
    
    switch (type) {
        case XMNDBColumnInteger:
            return @"integer";
        case XMNDBColumnDouble:
            return @"double";
        case XMNDBColumnBlob:
            return @"blob";
        default:
            return @"text";
            break;
    }
}

static inline XMNDBColumnType XMNColumnTypeForObjectType(XMNObjectType objectType) {

    switch (objectType) {
        case XMNObjectTypeBOOL:
        case XMNObjectTypeInteger:
        case XMNObjectTypeNSNumber:
            return XMNDBColumnInteger;
        case XMNObjectTypeFloat:
        case XMNObjectTypeDouble:
            return XMNDBColumnDouble;
        default:
            return XMNDBColumnText;
            break;
    }
}

static inline XMNObjectType XMNObjectNumberTypeForEncodingType(YYEncodingType encodingType) {
    
    switch (encodingType) {
        case YYEncodingTypeBool:
            return XMNObjectTypeBOOL;
        case YYEncodingTypeFloat:
            return XMNObjectTypeFloat;
        case YYEncodingTypeDouble:
        case YYEncodingTypeLongDouble:
            return XMNObjectTypeDouble;
        case YYEncodingTypeInt8:
        case YYEncodingTypeUInt8:
        case YYEncodingTypeInt16:
        case YYEncodingTypeUInt16:
        case YYEncodingTypeInt32:
        case YYEncodingTypeUInt32:
        case YYEncodingTypeInt64:
        case YYEncodingTypeUInt64:
        default:
            return XMNObjectTypeInteger;
    }
}

static NSDictionary *kXMNObjectClassMapper;
static inline XMNObjectType  XMNObjectClassTypeForCls(Class cls) {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        NSMutableDictionary *mapper = [NSMutableDictionary new];
        
        mapper[@"NSString"] = @(XMNObjectTypeNSString);
        mapper[@"NSMutableString"] = @(XMNObjectTypeNSMutableString);
        
        mapper[@"NSNumber"] = @(XMNObjectTypeNSNumber);
        mapper[@"NSAttributedString"] = @(XMNObjectTypeNSAttributedString);
        mapper[@"NSMutableAttributedString"] = @(XMNObjectTypeNSMutableAttributedString);
        
        mapper[@"NSValue"] = @(XMNObjectTypeNSValue);
        mapper[@"NSDecimalNumber"] = @(XMNObjectTypeNSDecimalNumber);
        mapper[@"NSDate"] = @(XMNObjectTypeNSDate);
        mapper[@"NSURL"] = @(XMNObjectTypeNSURL);
        
        mapper[@"NSArray"] = @(XMNObjectTypeNSArray);
        mapper[@"NSMutableArray"] = @(XMNObjectTypeNSMutableArray);
        mapper[@"NSSet"] = @(XMNObjectTypeNSSet);
        mapper[@"NSMutableSet"] = @(XMNObjectTypeNSMutableSet);
        mapper[@"NSDictionary"] = @(XMNObjectTypeNSDictionary);
        mapper[@"NSMutableDictionary"] = @(XMNObjectTypeNSMutableDictionary);

        mapper[@"NSData"] = @(XMNObjectTypeNSData);
        mapper[@"NSMutableData"] = @(XMNObjectTypeNSMutableData);
        
        mapper[@"UIImage"] = @(XMNObjectTypeUIImage);
        mapper[@"UIColor"] = @(XMNObjectTypeUIColor);
        
        kXMNObjectClassMapper = [mapper copy];
    });
    
    NSString *clsName = NSStringFromClass(cls);
    if ([clsName xmn_isEmpty]) {
        return XMNObjectTypeUnknown;
    }
    if (kXMNObjectClassMapper[clsName]) {
        return [kXMNObjectClassMapper[clsName] integerValue];
    }
    return XMNObjectTypeCustomClass;
}

@implementation NSObject (XMNDBModel)

#pragma mark - Setter

- (void)setRowID:(NSInteger)rowID {
    
    objc_setAssociatedObject(self, (__bridge const void *)(NSStringFromSelector(@selector(rowID))), @(rowID), OBJC_ASSOCIATION_RETAIN);
}

#pragma mark - Getter

- (NSInteger)rowID {
    
    id object = objc_getAssociatedObject(self, (__bridge const void *)(NSStringFromSelector(@selector(rowID))));
    if (object && [object respondsToSelector:@selector(integerValue)]) {
        return [object integerValue];
    }
    return NSIntegerMax;
}

- (nullable NSString *)xmn_insertSQLWithValues:(NSArray **)values {
    
    NSMutableString *sql = [NSMutableString stringWithFormat:@"replace into %@",[[self class] xmn_tableName]];
    
    XMNDBClassInfo *classInfo = [XMNDBClassInfo classInfoWithClass:[self class]];

    NSMutableArray *insertNames = [NSMutableArray array];
    NSMutableArray *insertValues = [NSMutableArray array];

    for (XMNDBPropertyInfo *propertyInfo in classInfo.propertyInfos) {
        
        id value = [self xmn_dbValueForProperty:propertyInfo];
        if (value) {
            
            [insertNames addObject:propertyInfo.columnName ? : @""];
            [insertValues addObject:value];
        }
    }
    
    [sql appendFormat:@"(%@) values(%@)",[insertNames componentsJoinedByString:@","], [[insertNames xmn_map:^id(id obj, NSInteger index) {
        
        return @"?";
    }] componentsJoinedByString:@","]];

    *values = [insertValues copy];
    return sql;
}

- (nullable NSString *)xmn_updateSQLWithValues:(inout NSArray * _Nullable * _Nullable)values {
    
    NSString *updateCondition = [self xmn_primaryQueryCondition];
    if ([updateCondition xmn_isEmpty]) {
        return nil;
    }
    
    XMNDBClassInfo *classInfo = [XMNDBClassInfo classInfoWithClass:[self class]];
    NSMutableString *sql = [NSMutableString stringWithFormat:@"update %@ set ",[[self class] xmn_tableName]];

    NSMutableArray *updateNames = [NSMutableArray array];
    NSMutableArray *updateValues = [NSMutableArray array];
    
    for (XMNDBPropertyInfo *propertyInfo in classInfo.propertyInfos) {
        
        id value = [self xmn_dbValueForProperty:propertyInfo];
        if (value) {
            
            [updateNames addObject:propertyInfo.columnName ? : @""];
            [updateValues addObject:value];
        }
    }
    
    [sql appendString:[[updateNames xmn_map:^id _Nonnull(id  _Nonnull obj, NSInteger index) {
        return [NSString stringWithFormat:@"%@=?",obj];
    }] componentsJoinedByString:@","]];
    
    [sql appendString:[NSString stringWithFormat:@" where %@",updateCondition]];
    
    *values = [updateValues copy];
    return sql;
}

- (NSString *)xmn_primaryQueryCondition {
    
    NSString *where;
    if (self.rowID && self.rowID != NSIntegerMax){
        
        where = [NSString stringWithFormat:@"rowid = %ld", (long)self.rowID];
    }else if ([self.class xmn_primaryKeys] && [self.class xmn_primaryKeys].count) {
        
        NSArray *primaryKeys = [[self.class xmn_primaryKeys] allObjects];
        
        if (!primaryKeys || !primaryKeys.count) {
            /** 不存在主键 */
            return nil;
        }
        
        /** 获取主键对应的propertyInfos */
        XMNDBClassInfo *classInfo = [XMNDBClassInfo classInfoWithClass:[self class]];
        NSArray<XMNDBPropertyInfo *> *infos =  [[primaryKeys xmn_map:^id _Nonnull(NSString *obj, NSInteger index) {
            
            XMNDBPropertyInfo *info = classInfo.propertyMapper[obj] ? : classInfo.columnMapper[obj];
            return info ? : obj;
        }] xmn_filter:^BOOL(id  _Nonnull obj) {
            
            return ![obj isKindOfClass:[XMNDBPropertyInfo class]];
        }];
        
        if (!infos || !infos.count) {
            return nil;
        }
        
        NSMutableArray *conditions = [NSMutableArray array];
        [infos enumerateObjectsUsingBlock:^(XMNDBPropertyInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            id value = [self xmn_dbValueForProperty:obj];
            [conditions addObject:[NSString stringWithFormat:@"%@ = '%@'",obj.columnName,value]];
        }];
        
        if (!conditions.count) {
            return nil;
        }
        where = [conditions componentsJoinedByString:@" and "];
    }
    return where;
}

#pragma mark - Class Method

+ (NSString *)xmn_tableName { return NSStringFromClass(self); }
+ (NSSet<NSString *> *)xmn_primaryKeys { return nil; }
+ (NSSet<NSString *> *)xmn_ignoredPropertyNames { return [NSSet setWithObject:@"rowid"]; }
+ (XMNDBPropertyInfo *)xmn_customProperty:(XMNDBPropertyInfo *)propertyInfo { return propertyInfo; };
+ (BOOL)xmn_containParentProperty { return YES; }
+ (BOOL)xmn_ignoredData { return YES; };

+ (NSString *)xmn_createTableSQL {
    
    return [self xmn_createTableSQLWithName:[self xmn_tableName]];
}

+ (NSString *)xmn_createTableSQLWithName:(NSString *)tableName {
    
    return [self xmn_createTableSQLWithName:tableName columnArray:nil];
}

+ (NSString *)xmn_createTableSQLWithName:(NSString *)tableName columnArray:(inout NSArray * _Nullable * _Nullable)columnArray {
    
    NSAssert(tableName, @"tablename is nil!!!");
    
    NSSet *primaryKeys = [self xmn_primaryKeys];
    BOOL singlePrimaryKey = primaryKeys && primaryKeys.count == 1;
    
    NSMutableString *sql = [NSMutableString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (",tableName];

    XMNDBClassInfo *classInfo = [XMNDBClassInfo classInfoWithClass:self];
    
    NSMutableArray *propertySQLs = [NSMutableArray array];
    NSMutableSet *columns = [NSMutableSet set];
    
    for (XMNDBPropertyInfo *info in classInfo.propertyInfos) {
        
        NSString *columnName = info.columnName ? : @"";
        if ([columnName xmn_isEmpty]) {
            continue;
        }
        NSMutableString *propertySQL = [NSMutableString string];
        [propertySQL appendFormat:@"%@ %@",columnName, info.columnTypeString];
        if (info.columnType ==  XMNDBColumnText && info.columnLength) {
            [propertySQL appendFormat:@"(%ld)", (long)info.columnLength];
        }
        
        if (info.isNotNull) {
            [propertySQL appendFormat:@" NOT NULL"];
        }
        
        if (info.checkValue && ![info.checkValue xmn_isEmpty]) {
            [propertySQL appendFormat:@" check(%@)", info.checkValue];
        }
        
        if (info.defaultValue && ![info.defaultValue xmn_isEmpty]) {
            [propertySQL appendFormat:@" default %@",info.defaultValue];
        }

        if (singlePrimaryKey && info.isPrimary) {
            [propertySQL appendFormat:@" primary key"];
        }
        
        [columns addObject:info.columnName];
        [propertySQLs addObject:[propertySQL copy]];
    }
    
    if (propertySQLs) {
        [sql appendFormat:@" %@",[propertySQLs componentsJoinedByString:@","]];
        if (columnArray != NULL) {
            *columnArray = [[columns allObjects] copy];
        }
    }
    
    /** 配置联合主键 */
    if (!singlePrimaryKey && primaryKeys.count >= 2) {
        /** 多个主键,联合主键 */
        [sql appendFormat:@" primary key (%@)", [[[classInfo.propertyInfos xmn_filter:^BOOL(XMNDBPropertyInfo * _Nonnull obj) {
            return !obj.isPrimary || !obj.columnName || !obj.columnName.length;
        }] xmn_map:^id _Nonnull(XMNDBPropertyInfo * _Nonnull obj, NSInteger index) {
            return obj.columnName;
        }] componentsJoinedByString:@","]];
    }
    if ([sql hasSuffix:@","]) {
        [sql deleteCharactersInRange:NSMakeRange(sql.length - 1, 1)];
    }
    [sql appendString:@")"];
    return [sql copy];
}

@end

#pragma mark - NSObject (XMNDBModelSupport)

@implementation NSObject (XMNDBSaveModelSupport)

static dispatch_queue_t kXMNFileOperationQueue;
static dispatch_queue_t kXMNAsyncOperationQueue;

- (id)xmn_reformValueToSave:(id)value {
    
    if (!value) {
        return nil;
    }
    
//    if ([value isKindOfClass:[UIImage class]]) {
//        
//        if (![self.class xmn_ignoredData]) {
//            NSString *key = [[NSString stringWithFormat:@"%ld",[value yy_modelHash]] xmn_md5];
//            NSString *fileName = [NSString stringWithFormat:@"image_%@",[key xmn_md5]];
//            NSString *filepath = [NSFileManager xmn_filePathForDocuments:fileName inDir:[NSString stringWithFormat:@"db_image/%@",[[self.class xmn_tableName] lowercaseString]]];
//            if ([NSFileManager xmn_fileExists:filepath]) {
//                XMNLogInfo(@"image is already exists :%@",fileName);
//            }else {
//                dispatch_async(kXMNFileOperationQueue, ^{
//                    [UIImageJPEGRepresentation(value, 1.f) writeToFile:filepath atomically:YES];
//                });
//            }
//
//            return XMNDBDictionary(XMNObjectTypeUIImage, fileName, NO);
//        }
//    }else if ([value isKindOfClass:[NSData class]]) {
//        
//        if (![self.class xmn_ignoredData]) {
//        
//            NSString *key = [[NSString stringWithFormat:@"%ld",[value yy_modelHash]] xmn_md5];
//            NSString *fileName = [NSString stringWithFormat:@"file_%@",[key xmn_md5]];
//            NSString *filepath = [NSFileManager xmn_filePathForDocuments:fileName inDir:[NSString stringWithFormat:@"db_file/%@",[[self.class xmn_tableName] lowercaseString]]];
//            if ([NSFileManager xmn_fileExists:filepath]) {
//                XMNLogInfo(@"file is already exists :%@",fileName);
//            }else {
//                dispatch_async(kXMNFileOperationQueue, ^{
//                    [(NSData *)value writeToFile:filepath atomically:YES];
//                });
//            }
//            return XMNDBDictionary(XMNObjectTypeNSData, fileName, [value isKindOfClass:[NSMutableData class]]);
//        }
//    }
    return XMNReformDBValueFromValue(value, NO);
}

@end

@implementation NSObject (XMNDBSetModelSupport)

- (void)xmn_setDBValue:(id)dbValue
           forProperty:(XMNDBPropertyInfo *)property {
    
    if (!dbValue || [dbValue isKindOfClass:[NSNull class]]) {
        /** 忽略dbValue不存在,或者为NSNull的情况 */
        return;
    }
    id retValue = XMNReformValueFromDBValue(dbValue, property.objectType);
    [self setValue:retValue forKey:property.propertyName];
}

@end

@implementation NSObject (XMNDBModelSupport)

- (id)xmn_dbValueForProperty:(XMNDBPropertyInfo *)property {
    
    if (!property) {
        XMNLogWarning(@"dbvalue for property is nil");
        return nil;
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kXMNFileOperationQueue = dispatch_queue_create("XMNFMDB file operationQueue", DISPATCH_QUEUE_CONCURRENT);
    });
    
    id value = [self valueForKey:property.propertyName];
    id retValue = [self xmn_reformValueToSave:value];
    return retValue;
}

- (void)xmn_configObjectWithDBValue:(NSDictionary *)dbValue {
    
    XMNDBClassInfo *classInfo = [XMNDBClassInfo classInfoWithClass:[self class]];
    __weak typeof(*&self) wSelf = self;
    [classInfo.propertyInfos enumerateObjectsUsingBlock:^(XMNDBPropertyInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        __strong typeof(*&wSelf) self = wSelf;
        [self xmn_setDBValue:dbValue[obj.columnName]
                 forProperty:obj];
    }];
}

+ (instancetype)xmn_objectFromDBValue:(NSDictionary *)dbValue {
    
    if (!dbValue || !dbValue.count) {
        return nil;
    }
    
    id object = [[[self class] alloc] init];
    [object xmn_configObjectWithDBValue:dbValue];
    if (dbValue[@"rowid"] && [dbValue[@"rowid"] respondsToSelector:@selector(integerValue)] && [object respondsToSelector:@selector(setRowID:)]) {
        [object setRowID:[dbValue[@"rowid"] integerValue]];
    }
    return object;
}

@end

#pragma mark - XMNDBPropertyInfo

@implementation XMNDBPropertyInfo : NSObject

- (instancetype)initWithClassPropertyInfo:(YYClassPropertyInfo *)propertyInfo {
    
    if (self = [super init]) {
        
        self.propertyName = propertyInfo.name;
        self.columnName = [propertyInfo.name lowercaseString];
        self.defaultValue = self.checkValue = nil;
        
        if (propertyInfo.cls) {
            self.objectType = XMNObjectClassTypeForCls(propertyInfo.cls);
            if (self.objectType == XMNObjectTypeCustomClass) {
                self.customObjectClassName = NSStringFromClass(propertyInfo.cls);
            }
        }else if ((propertyInfo.type & YYEncodingTypeMask) == YYEncodingTypeStruct) {
            self.objectType = XMNObjectStructTypeForEncodingType(propertyInfo.typeEncoding);
        }else if ((propertyInfo.type & YYEncodingTypeMask) <= YYEncodingTypeLongDouble && (propertyInfo.type & YYEncodingTypeMask) >= YYEncodingTypeBool) {
            self.objectType = XMNObjectNumberTypeForEncodingType(propertyInfo.type);
        }else {
            self.objectType = XMNObjectTypeUnknown;
        }
        self.columnType = XMNColumnTypeForObjectType(self.objectType);
    }
    return self;
}

- (NSString *)columnTypeString {
    
    return XMNColumnTypeString(self.columnType);
}

@end

#pragma mark - XMNDBClassInfo

@implementation XMNDBClassInfo {
    
    BOOL _needUpdate;
}

@synthesize cls = _cls;
@synthesize columnMapper = _columnMapper;
@synthesize propertyInfos = _propertyInfos;
@synthesize propertyMapper = _propertyMapper;

- (instancetype)initWithClass:(Class)cls {
    
    if (self = [super init]) {
     
        _cls = cls;
        [self _update];
    }
    return self;
}

+ (instancetype)classInfoWithClass:(Class)cls {
    
    if (!cls || [cls xmn_isSystemClass]) {
        return nil;
    }
    
    static CFMutableDictionaryRef classCache;
    static dispatch_once_t onceToken;
    static dispatch_semaphore_t lock;
    dispatch_once(&onceToken, ^{
        classCache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        lock = dispatch_semaphore_create(1);
    });
    
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    XMNDBClassInfo *info = CFDictionaryGetValue(classCache, (__bridge const void *)(cls));
    if (info && info->_needUpdate) {
        [info _update];
    }
    dispatch_semaphore_signal(lock);
    
    if (!info) {
        info = [[XMNDBClassInfo alloc] initWithClass:cls];
        if (info) {
            dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
            CFDictionarySetValue(classCache, (__bridge const void *)(cls), (__bridge const void *)(info));
            dispatch_semaphore_signal(lock);
        }
    }
    return info;
}

- (void)_update {
    
    NSMutableArray<XMNDBPropertyInfo *> *propertyInfos = [NSMutableArray array];

    /** 获取对应Object的所有属性 */
    __weak typeof(*&self) wSelf = self;
    YYClassInfo *classInfo = [YYClassInfo classInfoWithClass:self.cls];
    while (classInfo && ![classInfo.cls xmn_isSystemClass]) {
        
        /** 过滤掉只读属性 */
        /** 过滤被忽略的属性 */
        /** 过滤已经添加的属性 - 防止父类与子类有同名属性 */
        [propertyInfos addObjectsFromArray:[[[[classInfo.propertyInfos allValues] xmn_filter:^BOOL(YYClassPropertyInfo *obj) {

            /** 过滤掉只读属性 */
            return ((obj.type & YYEncodingTypePropertyMask) == YYEncodingTypePropertyReadonly);
        }] xmn_map:^id _Nonnull(YYClassPropertyInfo * _Nonnull obj, NSInteger index) {
            
            __strong typeof(*&wSelf) self = wSelf;
            XMNDBPropertyInfo *info = [[XMNDBPropertyInfo alloc] initWithClassPropertyInfo:obj];
            /** 自定义属性 */
            info = [classInfo.cls xmn_customProperty:info];
            /** 设置info 是否是主键属性 */
            info.primary = ([[self.cls xmn_primaryKeys] containsObject:info.propertyName]) || ([[self.cls xmn_primaryKeys] containsObject:info.columnName]);
            return info;
        }] xmn_filter:^BOOL(XMNDBPropertyInfo *obj) {
            
            /** 过滤掉被忽略的column 或者 属性 */
            return [[classInfo.cls xmn_ignoredPropertyNames] containsObject:obj.propertyName] || [[classInfo.cls xmn_ignoredPropertyNames] containsObject:obj.columnName];
        }]];
        
        /** 是否包含父级属性 */
        if ([classInfo.cls xmn_containParentProperty]) {
            classInfo = classInfo.superClassInfo;
        }else {
            classInfo = nil;
        }
    }
    
    NSMutableDictionary *columnMapper = [NSMutableDictionary dictionary];
    NSMutableDictionary *propertyMapper = [NSMutableDictionary dictionary];
    
    for (XMNDBPropertyInfo *info in propertyInfos) {
        
        columnMapper[info.columnName] = info;
        propertyMapper[info.columnName] = info;
    }
    
    _columnMapper = [columnMapper copy];
    _propertyMapper = [propertyMapper copy];
    _propertyInfos = [propertyInfos copy];
}

- (void)setNeedUpdate:(BOOL)needUpdate {
    
    _needUpdate = needUpdate;
}

- (BOOL)needUpdate {
    
    return _needUpdate;
}

@end

#pragma mark - XMNDBQueryParams

@implementation XMNDBQueryParams
@synthesize toCls = _toCls;

- (instancetype)initWithToCls:(Class)cls {
    
    if (self = [super init]) {
        
        _toCls = cls;
        _count = NSIntegerMax;
    }
    return self;
}

- (NSString *)tableName {
    
    if (_tableName && _tableName.length) {
        return _tableName;
    }
    return [self.toCls xmn_tableName];
}

- (NSString *)querySQL {
    
    NSMutableString *sql = [NSMutableString stringWithString:@"select @c from @t"];
    
    if (self.columns && self.columns.count) {
        /** 拼接需要查询的行 */
        [sql replaceCharactersInRange:[sql rangeOfString:@"@c"] withString:[NSString stringWithFormat:@"%@,rowid",[self.columns componentsJoinedByString:@","]]];
    }else {
        [sql replaceCharactersInRange:[sql rangeOfString:@"@c"] withString:@"*,rowid"];
    }
    
    /** 拼接需要查询的表名 */
    [sql replaceCharactersInRange:[sql rangeOfString:@"@t"] withString:self.tableName];
    
    if (self.where && self.where.length) {
        [sql appendFormat:@" where %@",self.where];
    }
    
    if (self.groupBy && self.groupBy.length) {

        [sql appendFormat:@" group by %@",self.groupBy];
    }
    
    if (self.orderBy && self.orderBy.length) {
        [sql appendFormat:@" order by %@",self.orderBy];
    }
    
    if (self.count && self.count != NSIntegerMax) {
        [sql appendFormat:@" limit %ld offset %ld",(long)self.count, (long)self.offset];
    }else if (self.offset) {
        [sql appendFormat:@" offset %ld", (long)self.offset];
    }
    return [sql copy];
}

- (void)setWhereDictionary:(NSDictionary *)whereDictionary {
    
    _whereDictionary = [whereDictionary copy];
    NSMutableString *where = [NSMutableString string];
    [whereDictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
       
        if ([obj isKindOfClass:[NSString class]] && ([obj hasPrefix:@">"] || [obj hasPrefix:@"<"] || [obj hasPrefix:@"="])) {
            [where appendFormat:@"%@ %@ and", key, obj];
        }else {
            [where appendFormat:@"%@ = '%@' and",key,obj];
        }
    }];
    if ([where hasSuffix:@"and"]) {
        [where replaceCharactersInRange:NSMakeRange(where.length - 3, 3) withString:@""];
    }
    _where = [where copy];
}

@end
