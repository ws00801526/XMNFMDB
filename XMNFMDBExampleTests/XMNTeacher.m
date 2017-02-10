//
//  XMNTeacher.m
//  XMNFMDBExample
//
//  Created by XMFraker on 17/1/23.
//  Copyright © 2017年 XMFraker. All rights reserved.
//

#import "XMNTeacher.h"
#import "NSObject+XMNDBModel.h"

@implementation XMNPerson


+ (XMNDBPropertyInfo *)xmn_customProperty:(XMNDBPropertyInfo *)propertyInfo {
    
    if ([propertyInfo.propertyName isEqualToString:@"age"]) {
        propertyInfo.columnName = @"myage";
        propertyInfo.checkValue = @"myage >= 0";
        propertyInfo.defaultValue = @"10";
    }
    return propertyInfo;
}
@end

@implementation XMNTeacher

+ (BOOL)xmn_containParentProperty {
    
    return YES;
}

+ (NSSet <NSString *> *)xmn_primaryKeys {
    
    return [NSSet setWithArray:@[@"name"]];
}

@end

@implementation XMNClass

+ (NSSet <NSString *> *)xmn_primaryKeys {
    
    return [NSSet setWithArray:@[@"name"]];
}

@end

@implementation XMNStudent

+ (NSSet <NSString *> *)xmn_primaryKeys {
    
    return [NSSet setWithArray:@[@"name"]];
}


@end

