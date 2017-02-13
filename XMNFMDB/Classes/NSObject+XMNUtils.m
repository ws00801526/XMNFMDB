//
//  NSObject+XMNUtils.m
//  XMNFMDBExample
//
//  Created by XMFraker on 17/1/11.
//  Copyright © 2017年 XMFraker. All rights reserved.
//

#import "NSObject+XMNUtils.h"
#import <asl.h>
#import <os/log.h>
#import <Availability.h>
#import <CommonCrypto/CommonCrypto.h>

#pragma mark - XMNLog 相关日志方法

#if TARGET_OS_IPHONE
    #if __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_10_0
        #define XMNLOG_USE_NEW_OS_METHODS 1
    #endif
#else
    #if __MAC_OS_X_VERSION_MIN_REQUIRED > __MAC_10_10
        #define XMNLOG_USE_NEW_OS_METHODS 1
    #endif
#endif

XMNLogLevel XMNCurrentLogLevel = XMNLogLevelInfo;

/** 设置测试环境下打印日志信息 */
XMNLogBlock XMNCurrnetLogBlock = ^(NSUInteger logLevel, NSString *fileName, NSUInteger lineNumber, NSString *methodName, NSString *format, ...) {
    
#ifdef DEBUG
    va_list args;
    va_start(args, format);
    XMNLogMessagev(logLevel, [NSString stringWithFormat:@"\n filename :%@ \n methodName :%@ \n line :%ld \n %@",fileName,methodName,lineNumber,format], args);
    va_end(args);
#else
    
#endif
};

void XMNLogSetLoggerBlock(XMNLogBlock handler)
{
    XMNCurrnetLogBlock = [handler copy];
}

void XMNLogSetLoggerLevel(XMNLogLevel logLevel)
{
    XMNCurrentLogLevel = logLevel;
}

void XMNLogMessagev(XMNLogLevel logLevel, NSString *format, va_list args)
{
    
    NSString *facility = [[NSBundle mainBundle] bundleIdentifier];
    // convert to via NSString, since printf does not know %@
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
#ifdef XMNLOG_USE_NEW_OS_METHODS
    
    /** ios10+ */
    os_log_t log = os_log_create([facility UTF8String], [facility UTF8String]);
    switch (logLevel) {
        case XMNLogLevelInfo:
            os_log_info(log, [message UTF8String], nil);
            break;
        case XMNLogLevelWarning:
        case XMNLogLevelError:
            os_log_error(log, [message UTF8String], nil);
            break;
        case XMNLogLevelCritical:
        case XMNLogLevelEmergency:
            os_log_fault(log, [message UTF8String], nil);
            break;
        case XMNLogLevelDebug:
        default:
            os_log_debug(log, [message UTF8String], nil);
            break;
    }
    os_log_with_type(log, OS_LOG_TYPE_INFO, [message UTF8String], nil);
#else

    aslclient client = asl_open(NULL, [facility UTF8String], ASL_OPT_STDERR); // also log to stderr
    aslmsg msg = asl_new(ASL_TYPE_MSG);
    asl_set(msg, ASL_KEY_READ_UID, "-1");  // without this the message cannot be found by asl_search
    asl_log(client, msg, logLevel, "%s", [message UTF8String]);
    asl_free(msg);
#endif

}

void XMNLogMessage(XMNLogLevel logLevel, NSString *format, ...)
{
    va_list args;
    va_start(args, format);
    
    XMNLogMessagev(logLevel, format, args);
    
    va_end(args);
}

NSArray *XMNLogGetMessages(void) {

    
#ifdef XMNLOG_USE_NEW_OS_METHODS
    
    /** ios10+ */
    
#else
    
    aslmsg query, message;
    int index;
    const char *key, *val;
    NSString *facility = [[NSBundle mainBundle] bundleIdentifier];
    query = asl_new(ASL_TYPE_QUERY);

    // search only for current app messages
    asl_set_query(query, ASL_KEY_FACILITY, [facility UTF8String], ASL_QUERY_OP_EQUAL);
    aslresponse response = asl_search(NULL, query);
    NSMutableArray *tmpArray = [NSMutableArray array];
    
    while ((message = asl_next(response)))
    {
        NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
        
        for (index = 0; ((key = asl_key(message, index))); index++)
        {
            NSString *keyString = [NSString stringWithUTF8String:(char *)key];
            
            val = asl_get(message, key);
            
            NSString *string = val?[NSString stringWithUTF8String:val]:@"";
            tmpDict[keyString] = string;
        }
        
        [tmpArray addObject:tmpDict];
    }
    
    asl_free(query);
    asl_release(response);
    if ([tmpArray count]) {
        return [tmpArray copy];
    }
#endif

    return nil;
}

#pragma mark - NSObject (XMNUtils)

@implementation NSObject (XMNUtils)

static NSSet<NSString *> *kXMNSystemPrefixs;
+ (BOOL)xmn_isSystemClass {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        kXMNSystemPrefixs = [NSSet setWithArray:@[@"UI",@"NS",@"_UI",@"_NS",@"__UI",@"__NS"]];
    });
    
    NSString *clsName = NSStringFromClass(self);
    return [[kXMNSystemPrefixs allObjects] xmn_any:^BOOL(NSString *obj) {
        
        return [clsName hasPrefix:obj];
    }];
}

@end

#pragma mark - NSFileManager 目录,文件相关创建方法

@implementation NSFileManager (XMNFile)

+ (NSString *)xmn_documentPath {
    
    NSString *documentPath;
    
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
    documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
#else
    documentPath = [[NSBundle mainBundle] resourcePath];
#endif
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        XMNLogInfo(@"documentPath :%@",documentPath);
    });
    return documentPath;
}

+ (NSString *)xmn_directoryPathForDocuments:(NSString *)dirname {
    
    NSString *directoryPath = [[self xmn_documentPath] stringByAppendingPathComponent:dirname];
    BOOL isDir;
    BOOL isCreated = [[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:&isDir];
    if (!isCreated || !isDir) {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:&error];
    }
    return directoryPath;
}

+ (NSString *)xmn_filePathForDocuments:(NSString *)filename {
    
    NSString *filepath = [[self xmn_documentPath] stringByAppendingPathComponent:filename];
    BOOL isDir;
    BOOL isCreated = [[NSFileManager defaultManager] fileExistsAtPath:filename isDirectory:&isDir];
    if (!isCreated || isDir) {
        [[NSFileManager defaultManager] createFileAtPath:filename contents:nil attributes:nil];
    }
    return filepath;
}

+ (NSString *)xmn_filePathForDocuments:(NSString *)filename inDir:(NSString *)dirname {
    
    if (dirname && dirname.length) {
        [self xmn_directoryPathForDocuments:dirname];
    }
    NSString *filePath = (dirname && dirname.length) ? [dirname stringByAppendingPathComponent:filename] : filename;
    return [self xmn_filePathForDocuments:filePath];
}

+ (BOOL)xmn_fileExists:(NSString *)filepath {

    return [[NSFileManager defaultManager] fileExistsAtPath:filepath];
}

+ (BOOL)xmn_deleteFile:(NSString *)filepath {
 
    NSError *error;
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:filepath error:&error];
    if (error) {
        XMNLogWarning(@"删除文件失败 : %@",error.debugDescription);
    }
    return success;
}

+ (NSArray <NSString *> *)filesOfDirectory:(NSString *)dirname {
    
    NSError *error;
    NSArray <NSString *> * files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self xmn_directoryPathForDocuments:dirname] error:&error];
    if (error) {
        XMNLogWarning(@"获取目录下所有文件失败 : %@",error.debugDescription);
    }
    return files;
}

@end

#pragma mark - NSString 字符串相关拓展方法

@implementation NSString (XMNValidate)

- (BOOL)xmn_isEmpty {
    
    if (!self) {
        /** nil */
        return YES;
    }
    
    if (![self isKindOfClass:[NSString class]]) {
        /** 不是string类型 */
        return YES;
    }
    
    if (!self.length) {
        /** 无长度 */
        return YES;
    }
    
    return NO;
}

/**
 获取MD5加密字符串
 
 @return MD5加密后 字符串 32位
 */
- (nullable NSString *)xmn_md5 {
    
    if ([self xmn_isEmpty]) {
        return nil;
    }
    NSData* inputData = [self dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char outputData[CC_MD5_DIGEST_LENGTH];
    CC_MD5([inputData bytes], (unsigned int)[inputData length], outputData);
    
    NSMutableString* hashStr = [NSMutableString string];
    int i = 0;
    for (i = 0; i < CC_MD5_DIGEST_LENGTH; ++i)
        [hashStr appendFormat:@"%02x", outputData[i]];
    
    return hashStr;
}

@end


#pragma mark - NSArray 数组相关处理方法


@implementation NSArray (XMNArray)

- (NSArray *)xmn_map:(id(^)(id obj, NSInteger index))block {
    
    if (!block) {
        
        block = ^id(id obj ,NSInteger index){
            return obj;
        };
    }
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:self.count];
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [array addObject:block(obj,idx)];
    }];
    return [NSArray arrayWithArray:array];
}

- (NSArray *)xmn_filter:(BOOL(^)(id obj))filterBlock {
    
    if (!filterBlock) {
        
        return self;
    }
    return [self filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        
        return !filterBlock(evaluatedObject);
    }]];
}

- (BOOL)xmn_any:(BOOL(^)(id obj))block {
    
    if (!block || !self || !self.count) {
        return NO;
    }
    
    __block BOOL ret = NO;
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (block(obj)) {
            ret = YES;
            *stop = YES;
        }
    }];
    return ret;
}

- (id)xmn_safeObjectAtIndex:(NSUInteger)index {
    
    if (self && index < self.count) {
        return [self objectAtIndex:index];
    }
    return nil;
}

@end


#pragma mark - UIColor (XMNColor)

@implementation UIColor (XMNColor)

- (nullable NSString *)xmn_colorRGB {
    
    CGFloat r,g,b,a;
    [self getRed:&r green:&g blue:&b alpha:&a];
    
    return [NSString stringWithFormat:@"%.3f,%.3f,%.3f,%.3f",r,g,b,a];
}

+ (nullable UIColor *)xmn_colorWithRGB:(nonnull NSString *)RGB {
    
    NSArray *RGBs = [RGB componentsSeparatedByString:@","];
    if (!RGBs || RGBs.count <= 2) {
        return [UIColor clearColor];
    }
    if (RGBs.count == 3) {
        return [self xmn_colorWithRed:[RGBs[0] floatValue] green:[RGBs[1] floatValue] blue:[RGBs[2] floatValue] alpha:1.f];
    }else if (RGBs.count >= 4) {
        return [self xmn_colorWithRed:[RGBs[0] floatValue] green:[RGBs[1] floatValue] blue:[RGBs[2] floatValue] alpha:[RGBs[3] floatValue]];
    }else {
        return [UIColor clearColor];
    }
}

/**
 获取一个随机颜色
 
 @return UIColor
 */
+ (nonnull UIColor *)xmn_randomColor {
    
    return [self xmn_colorWithRed:arc4random_uniform(256) green:arc4random_uniform(256) blue:arc4random_uniform(256)];
}

+ (UIColor *)xmn_colorWithRed:(CGFloat)red
                                 green:(CGFloat)green
                                  blue:(CGFloat)blue {
    
    return [self xmn_colorWithRed:red green:green blue:blue alpha:1.f];
}

+ (UIColor *)xmn_colorWithRed:(CGFloat)red
                                 green:(CGFloat)green
                                  blue:(CGFloat)blue
                                 alpha:(CGFloat)alpha {
    
    if ([UIColor instancesRespondToSelector:@selector(colorWithDisplayP3Red:green:blue:alpha:)]) {
        return [UIColor colorWithDisplayP3Red:red green:green blue:blue alpha:alpha];
    }
    return [UIColor colorWithRed:(red/255.f) green:(green/255.f) blue:(blue/255.f) alpha:alpha];
}

//从十六进制字符串获取颜色，
//color:支持@“#123456”、 @“0X123456”、 @“123456”三种格式
+ (UIColor *)xmn_colorWithHexString:(nonnull NSString *)hex {
    
    return [self xmn_colorWithHexString:hex alpha:1.f];
}


+ (UIColor *)xmn_colorWithHexString:(nonnull NSString *)hex
                              alpha:(CGFloat)alpha {
    
    if ([hex xmn_isEmpty]) {
        return [UIColor clearColor];
    }
    
    //删除字符串中的空格
    NSString *cString = [[hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    // String should be 6 or 8 characters
    if ([cString length] < 6) {
        return [UIColor clearColor];
    }
    // strip 0X if it appears
    //如果是0x开头的，那么截取字符串，字符串从索引为2的位置开始，一直到末尾
    if ([cString hasPrefix:@"0X"] || [cString hasPrefix:@"0x"]) {
        cString = [cString substringFromIndex:2];
    }else if ([cString hasPrefix:@"#"]) {
        cString = [cString substringFromIndex:1];
    }else if ([cString length] != 6) {
        return [UIColor clearColor];
    }
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    //r
    NSString *rString = [cString substringWithRange:range];
    //g
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    //b
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [self xmn_colorWithRed:(float)r green:(float)g blue:(float)b alpha:alpha];
}

@end

