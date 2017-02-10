//
//  NSObject+XMNDBModel.h
//  XMNFMDBExample
//
//  Created by XMFraker on 17/1/12.
//  Copyright © 2017年 XMFraker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <YYModel/YYModel.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, XMNObjectType) {
    XMNObjectTypeUnknown = 0,
    
    XMNObjectTypeInteger = 100,
    XMNObjectTypeFloat,
    XMNObjectTypeDouble,
    XMNObjectTypeBOOL,
    
    /** 以text直接存储的相关数据 */
    XMNObjectTypeNSString = 1000,
    XMNObjectTypeNSMutableString,
    XMNObjectTypeNSAttributedString,
    XMNObjectTypeNSMutableAttributedString,
    XMNObjectTypeNSValue,
    XMNObjectTypeNSNumber,
    XMNObjectTypeNSDecimalNumber,
    XMNObjectTypeNSDate,
    XMNObjectTypeNSURL,
    
    XMNObjectTypeNSArray = 1100,
    XMNObjectTypeNSMutableArray,
    XMNObjectTypeNSArrayCombo,
    XMNObjectTypeNSDictionary,
    XMNObjectTypeNSMutableDictionary,
    XMNObjectTypeNSDictionaryCombo,
    XMNObjectTypeNSSet,
    XMNObjectTypeNSMutableSet,
    XMNObjectTypeNSSetCombo,
    
    XMNObjectTypeUIColor = 2000,
    XMNObjectTypeUIImage,
    XMNObjectTypeNSData,
    XMNObjectTypeNSMutableData,
    
    XMNObjectStructCGRect = 5000,
    XMNObjectStructCGSize,
    XMNObjectStructCGPoint,
    XMNObjectStructCGVector,
    XMNObjectStructUIOffset,
    XMNObjectStructUIEdgeInsets,
    XMNObjectStructNSRange,
    XMNObjectStructCGTransform,
    XMNObjectStructCATransform3D,
    
    XMNObjectTypeCustomClass = 10000
};

/** sqlite对应存储类型 */
typedef NS_ENUM(NSUInteger, XMNDBColumnType) {
    
    /** 默认未知类型, 数据库会使用text作为column类型 */
    XMNDBColumnUnknown = 0,
    /** 整形 */
    XMNDBColumnInteger,
    /** 双精度 */
    XMNDBColumnDouble,
    /** 字符串 */
    XMNDBColumnText,
    /** 大文件数据流 */
    XMNDBColumnBlob,
};

#pragma mark - NSObject (XMNDBModel)

@class XMNDBPropertyInfo;
@interface NSObject (XMNDBModel)

/** sqlite内行号 */
@property (assign, nonatomic) NSInteger rowID;

/**
 获取当前Object的插入SQL

 @param values  插入SQL的数据值
 @return  插入SQL字符串
 */
- (nullable NSString *)xmn_insertSQLWithValues:(inout NSArray * _Nullable * _Nullable)values;


/**
 获取当前object更新SQL语句

 @param values      更新的值
 @return 更新的SQL语句
 */
- (nullable NSString *)xmn_updateSQLWithValues:(inout NSArray * _Nullable * _Nullable)values;


/**
 用以查找具体Object的查询条件
 如果有primaryKey  则以主键进行查询
 否则以rowid 进行查询
 @return 查询条件
 */
- (nullable NSString *)xmn_primaryQueryCondition;


/**
 获取当前Object对应的表名
 支持重写
 @return 非空字符串
 */
+ (NSString *)xmn_tableName;

/**
 是否包含父类属性,将父类属性一并写入数据库
 
 @return 默认YES
 */
+ (BOOL)xmn_containParentProperty;

/**
 //TODO : 未实现相关功能
 是否忽略UIImage,NSData 等类型数据
 NO时 会一并将对应UIImage,NSData存储  影响sqlite 效率
 
 @return YES or NO  默认YES
 */
+ (BOOL)xmn_ignoredData;

/**
 自定义propertInfo

 @param propertyInfo    需要修改的propertyInfo
 @return 修改后的propertyInfo
 */
+ (XMNDBPropertyInfo *)xmn_customProperty:(XMNDBPropertyInfo *)propertyInfo;

/**
 数据库联合主键
 count = 1  时 单个主键
 count >= 2 时 联合主键
 
 当存在主键时, 查询,删除,等语句优先使用primarkKey
 否则使用rowid进行查询

 @return nil or NSSet
 */
+ (nullable NSSet<NSString *> *)xmn_primaryKeys;

/**
 忽略的属性,不会被添加到数据库中
 不会创建对应的数据库 column
 默认返回 rowid
 @return nil or NSSet
 */
+ (nullable NSSet<NSString *> *)xmn_ignoredPropertyNames;

/**
 创建数据库的语句
 
 @return 获取创建数据库语句
 */
+ (NSString *)xmn_createTableSQL;
+ (NSString *)xmn_createTableSQLWithName:(NSString *)tableName;
+ (NSString *)xmn_createTableSQLWithName:(NSString *)tableName
                             columnArray:(inout NSArray * _Nullable * _Nullable)columnArray;

@end

#pragma mark - NSObject (XMNDBModelSupport)

@interface NSObject (XMNDBModelSupport)

/**
 获取对应propertyName用来存储到数据库中的 值

 @param property   需要存储的属性名
 @return nil or id
 */
- (nullable id)xmn_dbValueForProperty:(XMNDBPropertyInfo *)property;

/**
 将从数据库中查询出来的 配置到NSObject的属性中
 
 @param dbValue     从数据库中查询出来的dbValue
 */
- (void)xmn_configObjectWithDBValue:( NSDictionary * _Nullable )dbValue;

/**
 便捷初始化方法,初始化NSObject对象

 @param dbValue 从数据库中查询出来的dbValue
 @return NSObject 对象
 */
+ (nullable instancetype)xmn_objectFromDBValue:( NSDictionary * _Nullable )dbValue;

@end

#pragma mark - XMNDBPropertyInfo

@interface XMNDBPropertyInfo : NSObject

@property (assign, nonatomic) XMNObjectType objectType;

@property (copy, nonatomic, nullable)   NSString *customObjectClassName;
@property (assign, nonatomic) XMNDBColumnType columnType;

@property (copy, nonatomic, nonnull)   NSString *propertyName;
@property (copy, nonatomic, nonnull)   NSString *columnName;

@property (assign, nonatomic) NSInteger columnLength;

@property (assign, nonatomic, getter=isNotNull) BOOL notNull;
@property (assign, nonatomic, getter=isPrimary) BOOL primary;
@property (assign, nonatomic, getter=isIgnored) BOOL ignored;

@property (copy, nonatomic, nullable)   NSString *checkValue;
@property (copy, nonatomic, nullable)   NSString *defaultValue;

@property (copy, nonatomic, readonly, nonnull)   NSString *columnTypeString;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithClassPropertyInfo:(YYClassPropertyInfo *)propertyInfo NS_DESIGNATED_INITIALIZER;

@end

#pragma mark - XMNDBClassInfo

@interface XMNDBClassInfo : NSObject

@property (assign, nonatomic, readonly) BOOL needUpdate;
@property (assign, nonatomic, readonly) Class cls;
@property (copy, nonatomic, readonly, nullable)   NSArray<XMNDBPropertyInfo *> *propertyInfos;
@property (copy, nonatomic, readonly, nullable)   NSDictionary<NSString *, XMNDBPropertyInfo *> *columnMapper;
@property (copy, nonatomic, readonly, nullable)   NSDictionary<NSString *, XMNDBPropertyInfo *> *propertyMapper;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithClass:(Class)cls NS_DESIGNATED_INITIALIZER;

+ (nullable instancetype)classInfoWithClass:(Class)cls;

- (void)setNeedUpdate:(BOOL)needUpdate;

@end


#pragma mark - XMNDBQueryParams

@interface XMNDBQueryParams : NSObject

/** 需要查询获取的columnArray */
@property (copy, nonatomic, nullable)   NSArray<NSString *> *columns;

/** 查询条件 */
@property (copy, nonatomic, nullable)   NSString *where;
@property (copy, nonatomic, nullable)   NSDictionary<NSString *,NSString *> *whereDictionary;

/** 需要查询的表 */
@property (copy, nonatomic, nullable)   NSString *tableName;
/** 分组 */
@property (copy, nonatomic, nullable)   NSString *groupBy;
/** 排序 */
@property (copy, nonatomic, nullable)   NSString *orderBy;

/** 起始offset */
@property (assign, nonatomic) NSInteger offset;
/** 查询数量 */
@property (assign, nonatomic) NSInteger count;

/** 根据参数 生成的查询语句SQL */
@property (copy, nonatomic, readonly, nonnull)   NSString *querySQL;
/** 对应需要转换成的cls */
@property (assign, nonatomic, nonnull, readonly) Class toCls;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithToCls:(Class)cls NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
