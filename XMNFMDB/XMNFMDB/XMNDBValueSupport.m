//
//  XMNDBValueSupport.m
//  XMNFMDBExample
//
//  Created by XMFraker on 17/2/8.
//  Copyright © 2017年 XMFraker. All rights reserved.
//


#import "NSObject+XMNUtils.h"
#import "NSObject+XMNDBModel.h"
#import "NSObject+XMNDBHelper.h"

static inline NSDictionary *XMNReformDBValueFromNSValue(NSValue *value);

static inline NSDictionary *XMNReformDBValueFromSet(NSSet *set);
static inline NSDictionary *XMNReformDBValueFromArray(NSArray *array);
static inline NSDictionary *XMNReformDBValueFromDictionary(NSDictionary *dictionary);
static inline NSDictionary *XMNReformDBValueFromCustomObject(id customObject);
static inline id XMNReformDBValueFromValue(id value, BOOL shouldWrap);

static inline NSDictionary *XMNDBDictionary(XMNObjectType type, id value, BOOL mutable) {
    
    if (!value || type == XMNObjectTypeUnknown) {
        return nil;
    }
    return mutable ? @{@"type"    : @(type), @"value"   : value, @"mutable" : @(mutable)} : @{@"type"    : @(type), @"value"   : value};
}

static inline XMNObjectType  XMNObjectStructTypeForEncodingType(NSString *objCType) {
    
    static NSDictionary *kXMNObjectStructMapper;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        NSMutableDictionary *mapper = [NSMutableDictionary new];
        
        // 32 bit
        mapper[@"{CGSize=ff}"] = @(XMNObjectStructCGSize);
        mapper[@"{CGPoint=ff}"] = @(XMNObjectStructCGPoint);
        mapper[@"{CGVector=ff}"] = @(XMNObjectStructCGVector);
        mapper[@"{CGRect={CGPoint=ff}{CGSize=ff}}"] = @(XMNObjectStructCGRect);
        mapper[@"{CGAffineTransform=ffffff}"] = @(XMNObjectStructCGTransform);
        mapper[@"{CATransform3D=ffffffffffffffff}"] = @(XMNObjectStructCATransform3D);
        mapper[@"{UIEdgeInsets=ffff}"] = @(XMNObjectStructUIEdgeInsets);
        mapper[@"{UIOffset=ff}"] = @(XMNObjectStructUIOffset);
        // 64 bit
        mapper[@"{CGSize=dd}"] = @(XMNObjectStructCGSize);
        mapper[@"{CGPoint=dd}"] = @(XMNObjectStructCGPoint);
        mapper[@"{CGVector=dd}"] = @(XMNObjectStructCGVector);
        mapper[@"{CGRect={CGPoint=dd}{CGSize=dd}}"] = @(XMNObjectStructCGRect);
        mapper[@"{CGAffineTransform=dddddd}"] = @(XMNObjectStructCGTransform);
        mapper[@"{CATransform3D=dddddddddddddddd}"] = @(XMNObjectStructCATransform3D);
        mapper[@"{UIEdgeInsets=dddd}"] = @(XMNObjectStructUIEdgeInsets);
        mapper[@"{UIOffset=dd}"] = @(XMNObjectStructUIOffset);
        
        //Struct
        mapper[@"{_NSRange=QQ}"] = @(XMNObjectStructNSRange);
        kXMNObjectStructMapper = [mapper copy];
    });
    return [kXMNObjectStructMapper[objCType] integerValue];
}

static inline NSDictionary *XMNReformDBValueFromNSValue(NSValue *value) {
    
    XMNObjectType structType = XMNObjectStructTypeForEncodingType([NSString stringWithCString:[value objCType] encoding:NSUTF8StringEncoding]);
    switch (structType) {
        case XMNObjectStructCGSize:
            return XMNDBDictionary(XMNObjectStructCGSize, NSStringFromCGSize([value CGSizeValue]), NO);
        case XMNObjectStructCGPoint:
            return XMNDBDictionary(XMNObjectStructCGPoint, NSStringFromCGPoint([value CGPointValue]), NO);
        case XMNObjectStructCGRect:
            return XMNDBDictionary(XMNObjectStructCGRect, NSStringFromCGRect([value CGRectValue]), NO);
        case XMNObjectStructCGTransform:

            return XMNDBDictionary(XMNObjectStructCGTransform, NSStringFromCGAffineTransform([value CGAffineTransformValue]), NO);
        case XMNObjectStructCGVector:
            return XMNDBDictionary(XMNObjectStructCGVector, NSStringFromCGVector([value CGVectorValue]), NO);
        case XMNObjectStructUIOffset:

            return XMNDBDictionary(XMNObjectStructUIOffset, NSStringFromUIOffset([value UIOffsetValue]), NO);
        case XMNObjectStructUIEdgeInsets:

            return XMNDBDictionary(XMNObjectStructUIEdgeInsets, NSStringFromUIEdgeInsets([value UIEdgeInsetsValue]), NO);
        case XMNObjectStructNSRange:

            return XMNDBDictionary(XMNObjectStructNSRange, NSStringFromRange([value rangeValue]), NO);
        default:
            return nil;
    }
}


static NSDateFormatter *kXMNFMDBDateFormatter;
static inline id XMNReformDBValueFromValue(id value, BOOL shouldWrap) {
    
    if (!value) {
        return nil;
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kXMNFMDBDateFormatter = [[NSDateFormatter alloc] init];
        kXMNFMDBDateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    });
    
    id retValue;
    if ([value isKindOfClass:[NSString class]]) {
        
        retValue = shouldWrap ? XMNDBDictionary(XMNObjectTypeNSString, [value copy], NO) : [value copy];
    }else if ([value isKindOfClass:[NSMutableString class]]) {
        
        retValue = shouldWrap ? XMNDBDictionary(XMNObjectTypeNSMutableString, [value copy], YES) : [value copy];
    }else if ([value isKindOfClass:[NSAttributedString class]]) {
        
        retValue = shouldWrap ? XMNDBDictionary(XMNObjectTypeNSAttributedString, [(NSAttributedString *)value string], NO) : [(NSAttributedString *)value string];
    }else if ([value isKindOfClass:[NSMutableAttributedString class]]) {
        
        retValue = shouldWrap ? XMNDBDictionary(XMNObjectTypeNSMutableAttributedString, [(NSAttributedString *)value string], YES) : [(NSAttributedString *)value string];
    }else if ([value isKindOfClass:[NSNumber class]]) {
        
        retValue = shouldWrap ? XMNDBDictionary(XMNObjectTypeNSNumber, [(NSNumber *)value stringValue], NO) : [(NSNumber *)value stringValue];
    }else if ([value isKindOfClass:[NSDate class]]) {
        
        retValue = shouldWrap ? XMNDBDictionary(XMNObjectTypeNSDate, [kXMNFMDBDateFormatter stringFromDate:(NSDate *)value], YES) : [kXMNFMDBDateFormatter stringFromDate:(NSDate *)value];
    }else if ([value isKindOfClass:[NSURL class]]) {
        
        retValue = shouldWrap ? XMNDBDictionary(XMNObjectTypeNSURL, [(NSURL *)value absoluteString], YES) : [(NSURL *)value absoluteString];
    }else if ([value isKindOfClass:[UIColor class]]) {
        
        retValue = shouldWrap ? XMNDBDictionary(XMNObjectTypeUIColor, [(UIColor *)value xmn_colorRGB], YES) : [(UIColor *)value xmn_colorRGB];
    }else if ([value isKindOfClass:[NSValue class]]) {
        
        retValue = XMNReformDBValueFromNSValue((NSValue *)value);
        retValue = shouldWrap ? retValue : retValue[@"value"];
    }else {
        
        if ([value isKindOfClass:[NSArray class]]) {
            
            retValue = XMNReformDBValueFromArray(value);
        }else if ([value isKindOfClass:[NSSet class]]) {
            
            retValue = XMNReformDBValueFromSet(value);
        }else if ([value isKindOfClass:[NSDictionary class]]) {
            
            retValue = XMNReformDBValueFromDictionary(value);
        }else {
            
            retValue = XMNReformDBValueFromCustomObject(value);
        }
        
        retValue = shouldWrap ? retValue : [retValue yy_modelToJSONString];
    }
    return retValue;
}


static inline NSDictionary *XMNReformDBValueFromArray(NSArray *array) {
    
    if ([NSJSONSerialization isValidJSONObject:array]) {
        
        /** 合法的数组,直接以字符串形式存储 */
        return @{@"type": @(XMNObjectTypeNSArray),
                 @"value" : array ? : [NSNull null],
                 @"mutable" : @([array isKindOfClass:[NSMutableArray class]])};
    }
    
    NSMutableArray *retValues = [NSMutableArray array];
    for (id obj in array) {
        
        id value = XMNReformDBValueFromValue(obj, YES);
        if (value) {
            [retValues addObject:value];
        }
    }
    return @{@"type": @(XMNObjectTypeNSArrayCombo),
             @"value" : [retValues copy] ? : [NSNull null],
             @"mutable" : @([array isKindOfClass:[NSMutableArray class]])};
}

static inline NSDictionary *XMNReformDBValueFromSet(NSSet *set) {
    
    if ([NSJSONSerialization isValidJSONObject:[set allObjects]]) {
        
        /** 合法的数组,直接以字符串形式存储 */
        return XMNDBDictionary(XMNObjectTypeNSSet, [set allObjects] ? : [NSNull class], [set isKindOfClass:[NSMutableSet class]]);
    }
    
    NSMutableArray *retValues = [NSMutableArray array];
    for (id obj in [set allObjects]) {
        
        id value = XMNReformDBValueFromValue(obj, YES);
        if (value) {
            [retValues addObject:value];
        }
    }
    return @{@"type": @(XMNObjectTypeNSSetCombo),
             @"value" : [retValues copy] ? : [NSNull null],
             @"mutable" : @([set isKindOfClass:[NSMutableSet class]])};
}

static inline NSDictionary *XMNReformDBValueFromDictionary(NSDictionary *dictionary) {
 
    if ([NSJSONSerialization isValidJSONObject:dictionary]) {
        
        return XMNDBDictionary(XMNObjectTypeNSDictionary, dictionary ? : [NSNull class], [dictionary isKindOfClass:[NSMutableDictionary class]]);
    }
    NSMutableDictionary *retValues = [NSMutableDictionary dictionary];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        
        id value = XMNReformDBValueFromValue(obj, NO);
        if (value) {
            retValues[key] = value;
        }
    }];
    return XMNDBDictionary(XMNObjectTypeNSDictionary, [retValues copy], [dictionary isKindOfClass:[NSMutableDictionary class]]);
}

static inline NSDictionary *XMNReformDBValueFromCustomObject(NSObject *customObject) {
    
    if (!customObject || ![customObject isKindOfClass:[NSObject class]]) {
        
        return nil;
    }
    if ([customObject xmn_saveOrUpdate]) {
        
        return @{@"type" : @(XMNObjectTypeCustomClass),
                 @"class" : NSStringFromClass([customObject class]),
                 @"value" : @(customObject.rowID)};
    }
    return nil;
}
