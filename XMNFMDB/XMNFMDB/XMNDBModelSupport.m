//
//  XMNDBModelSupport.m
//  XMNFMDBExample
//
//  Created by XMFraker on 17/1/25.
//  Copyright © 2017年 XMFraker. All rights reserved.
//


#import "NSObject+XMNUtils.h"
#import "NSObject+XMNDBModel.h"
#import "NSObject+XMNDBHelper.h"

static inline NSSet          *XMNReformSetFromDBValue(id dbValue);
static inline NSArray        *XMNReformArrayFromDBValue(id dbValue);
static inline NSDictionary   *XMNReformDictionaryFromDBValue(id dbValue);
static inline id             XMNReformCustomObjectFromDBValue(id dbValue);
static inline id             XMNReformValueFromDBValue(id dbValue, XMNObjectType valueType);

static inline id XMNReformCustomObjectFromDBValue(id dbValue) {
    
    id json = dbValue;
    if ([json isKindOfClass:[NSString class]]) {
        json = [NSJSONSerialization JSONObjectWithData:[dbValue dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
    }
    if (json) {
        NSString *clsName = json[@"class"];
        NSNumber *rowid = json[@"value"];
        
        if ([clsName xmn_isEmpty]) {
            return nil;
        }
        
        Class cls = NSClassFromString(clsName);
        if (!cls) {
            XMNLogWarning(@"cls :%@ not exists",clsName);
            return nil;
        }
        
        return [cls xmn_objectForRowID:[rowid integerValue]];
    }
    return nil;
}

static inline NSArray *XMNReformArrayFromDBValue(id dbValue) {

    id json = dbValue;
    if ([dbValue isKindOfClass:[NSString class]]) {
        json = [NSJSONSerialization JSONObjectWithData:[dbValue dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
    }
    BOOL isMutable = json[@"mutable"] ? [json[@"mutable"] boolValue] : NO;
    
    if ([json[@"type"] integerValue] == XMNObjectTypeNSArray) {
        return isMutable ? [NSMutableArray arrayWithArray:json[@"value"]] : json[@"value"];
    }
    
    NSMutableArray *retValues = [NSMutableArray array];
    NSArray *valueArray = json[@"value"];
    
    for (id jsonObject in valueArray) {
        XMNObjectType type = [jsonObject[@"type"] integerValue];
        id retValue;
        if (type == XMNObjectTypeCustomClass) {
            retValue = XMNReformValueFromDBValue(jsonObject, type);
        }else {
            retValue = XMNReformValueFromDBValue(jsonObject[@"value"], type);
        }
        if (retValue) {
            [retValues addObject:retValue];
        }
    }
    return isMutable ? retValues : [retValues copy];
}

static inline NSSet *XMNReformSetFromDBValue(id dbValue) {
    
    id json = dbValue;
    if ([dbValue isKindOfClass:[NSString class]]) {
        json = [NSJSONSerialization JSONObjectWithData:[dbValue dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
    }
    BOOL isMutable = json[@"mutable"] ? [json[@"mutable"] boolValue] : NO;
    
    if ([json[@"type"] integerValue] == XMNObjectTypeNSArray) {
        return isMutable ? [NSMutableSet setWithArray:json[@"value"]] : json[@"value"];
    }
    
    NSMutableSet *retValues = [NSMutableSet set];
    NSArray *valueArray = json[@"value"];
    
    for (id jsonObject in valueArray) {
        id retValue = XMNReformValueFromDBValue(jsonObject[@"value"], [jsonObject[@"type"] integerValue]);
        if (retValue) {
            [retValues addObject:retValue];
        }
    }
    return isMutable ? retValues : [retValues copy];
}

static inline NSDictionary *XMNReformDictionaryFromDBValue(id dbValue) {
    
    id json = dbValue;
    if ([dbValue isKindOfClass:[NSString class]]) {
        json = [NSJSONSerialization JSONObjectWithData:[dbValue dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
    }
    BOOL isMutable = json[@"mutable"] ? [json[@"mutable"] boolValue] : NO;
    
    if ([json[@"type"] integerValue] == XMNObjectTypeNSArray) {
        return isMutable ? [NSMutableDictionary dictionaryWithDictionary:json[@"value"]] : json[@"value"];
    }
    
    NSMutableDictionary *retValues = [NSMutableDictionary dictionary];
    NSDictionary *valueDictionary = json[@"value"];
    
    [valueDictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        id retValue = XMNReformValueFromDBValue(obj[@"value"], [obj[@"type"] integerValue]);
        if (retValue) {
            retValues[key] = retValue;
        }
    }];
    return isMutable ? retValues : [retValues copy];
}

static NSDateFormatter *kXMNFMDBDateFormatter;
static inline id XMNReformValueFromDBValue(id dbValue, XMNObjectType valueType) {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kXMNFMDBDateFormatter = [[NSDateFormatter alloc] init];
        kXMNFMDBDateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    });
    
    switch (valueType) {
            
            //基础数据类型
        case XMNObjectTypeNSNumber:
        {
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            [formatter setNumberStyle:NSNumberFormatterNoStyle];
            return [formatter numberFromString:dbValue];
        }
        case XMNObjectTypeBOOL:
            return @([dbValue boolValue]);
        case XMNObjectTypeInteger:
            return @([dbValue integerValue]);
        case XMNObjectTypeFloat:
            return @([dbValue floatValue]);
        case XMNObjectTypeDouble:
            return @([dbValue doubleValue]);
            
            //字符串相关类型
        case XMNObjectTypeNSString:
            return dbValue;
        case XMNObjectTypeNSMutableString:
            return [NSMutableString stringWithString:dbValue];
        case XMNObjectTypeNSURL:
            return [NSURL URLWithString:dbValue];
        case XMNObjectTypeNSAttributedString:
            return [[NSAttributedString alloc] initWithString:dbValue];
        case XMNObjectTypeNSMutableAttributedString:
            return [[NSMutableAttributedString alloc] initWithString:dbValue];
        case XMNObjectTypeNSDate:
            
            return [kXMNFMDBDateFormatter dateFromString:dbValue];
            //数据结构相关
            
        case XMNObjectStructCGRect:
            return [NSValue valueWithCGRect:CGRectFromString(dbValue)];
        case XMNObjectStructCGSize:
            return [NSValue valueWithCGSize:CGSizeFromString(dbValue)];
        case XMNObjectStructCGPoint:
            return [NSValue valueWithCGPoint:CGPointFromString(dbValue)];
        case XMNObjectStructCGVector:
            return [NSValue valueWithCGVector:CGVectorFromString(dbValue)];
        case XMNObjectStructUIOffset:
            return [NSValue valueWithUIOffset:UIOffsetFromString(dbValue)];
        case XMNObjectStructUIEdgeInsets:
            return [NSValue valueWithUIEdgeInsets:UIEdgeInsetsFromString(dbValue)];
        case XMNObjectStructNSRange:
            return [NSValue valueWithRange:NSRangeFromString(dbValue)];
        case XMNObjectStructCGTransform:
            return [NSValue valueWithCGAffineTransform:CGAffineTransformFromString(dbValue)];
            
            //颜色相关
        case XMNObjectTypeUIColor:

            return [UIColor xmn_colorWithRGB:dbValue];
            
            //文件存储相关
        case XMNObjectTypeUIImage:
            
            return nil;
        case XMNObjectTypeNSData:
        case XMNObjectTypeNSMutableData:

            return nil;
            
            //集合类型相关
        case XMNObjectTypeNSSet:
        case XMNObjectTypeNSMutableSet:
            
            return XMNReformSetFromDBValue(dbValue);
        case XMNObjectTypeNSArray:
        case XMNObjectTypeNSMutableArray:
            
            return XMNReformArrayFromDBValue(dbValue);
        case XMNObjectTypeNSDictionary:
        case XMNObjectTypeNSMutableDictionary:
            
            return XMNReformDictionaryFromDBValue(dbValue);
            
            //自定义数据相关
        case XMNObjectTypeCustomClass:
            
            return XMNReformCustomObjectFromDBValue(dbValue);
        default:
            return nil;
    }
}
