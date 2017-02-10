//
//  NSObject+XMNUtils.h
//  XMNFMDBExample
//
//  Created by XMFraker on 17/1/11.
//  Copyright © 2017年 XMFraker. All rights reserved.
//

#import <UIKit/UIKit.h>

#pragma mark - XMNLog

/** 打印日志的级别 */
typedef NS_ENUM(NSUInteger, XMNLogLevel) {
    
    /**
     Log level for *emergency* messages
     */
    XMNLogLevelEmergency = 0,
    
    /**
     Log level for *alert* messages
     */
    XMNLogLevelAlert     = 1,
    
    /**
     Log level for *critical* messages
     */
    XMNLogLevelCritical  = 2,
    
    /**
     Log level for *error* messages
     */
    XMNLogLevelError     = 3,
    
    /**
     Log level for *warning* messages
     */
    XMNLogLevelWarning   = 4,
    
    /**
     Log level for *notice* messages
     */
    XMNLogLevelNotice    = 5,
    
    /**
     Log level for *info* messages. This is the default log level for XMNLog.
     */
    XMNLogLevelInfo      = 6,
    
    /**
     Log level for *debug* messages
     */
    XMNLogLevelDebug     = 7
};

typedef void (^XMNLogBlock)(NSUInteger logLevel, NSString * _Nonnull fileName, NSUInteger lineNumber, NSString * _Nonnull methodName, NSString * _Nullable format, ...);

// internal variables needed by macros
FOUNDATION_EXPORT XMNLogBlock _Nullable XMNCurrnetLogBlock;
FOUNDATION_EXPORT XMNLogLevel XMNCurrentLogLevel;

void XMNLogSetLoggerLevel(XMNLogLevel logLevel);
void XMNLogSetLoggerBlock(XMNLogBlock _Nonnull block);

void XMNLogMessagev(XMNLogLevel logLevel,  NSString * _Nonnull format, va_list args);

void XMNLogMessage(XMNLogLevel logLevel, NSString * _Nonnull format, ...);

/**
 Retrieves the log messages currently available for the running app
 @returns an `NSArray` of `NSDictionary` entries
 */
NSArray * _Nullable XMNLogGetMessages(void);

/**
 @name Macros
 */

// log macro for error level (0)
#define XMNLogEmergency(format, ...) XMNLogCallHandlerIfLevel(XMNLogLevelEmergency, format, ##__VA_ARGS__)

// log macro for error level (1)
#define XMNLogAlert(format, ...) XMNLogCallHandlerIfLevel(XMNLogLevelAlert, format, ##__VA_ARGS__)

// log macro for error level (2)
#define XMNLogCritical(format, ...) XMNLogCallHandlerIfLevel(XMNLogLevelCritical, format, ##__VA_ARGS__)

// log macro for error level (3)
#define XMNLogError(format, ...) XMNLogCallHandlerIfLevel(XMNLogLevelError, format, ##__VA_ARGS__)

// log macro for error level (4)
#define XMNLogWarning(format, ...) XMNLogCallHandlerIfLevel(XMNLogLevelWarning, format, ##__VA_ARGS__)

// log macro for error level (5)
#define XMNLogNotice(format, ...) XMNLogCallHandlerIfLevel(XMNLogLevelNotice, format, ##__VA_ARGS__)

// log macro for info level (6)
#define XMNLogInfo(format, ...) XMNLogCallHandlerIfLevel(XMNLogLevelInfo, format, ##__VA_ARGS__)

// log macro for debug level (7)
#define XMNLogDebug(format, ...) XMNLogCallHandlerIfLevel(XMNLogLevelDebug, format, ##__VA_ARGS__)

// macro that gets called by individual level macros
#define XMNLogCallHandlerIfLevel(logLevel, format, ...) \
if (XMNCurrnetLogBlock && XMNCurrentLogLevel>=logLevel) XMNCurrnetLogBlock(logLevel, XMNLogSourceFileName, XMNLogSourceLineNumber, XMNLogSourceMethodName, format, ##__VA_ARGS__)

// helper to get the current source file name as NSString
#define XMNLogSourceFileName [[NSString stringWithUTF8String:__FILE__] lastPathComponent]

// helper to get current method name
#define XMNLogSourceMethodName [NSString stringWithUTF8String:__PRETTY_FUNCTION__]

// helper to get current line number
#define XMNLogSourceLineNumber __LINE__


#ifndef XMNTick
    #if DEBUG
        #define XMNTick  NSDate *_tickDate = [NSDate date];
        #define XMNTock  NSLog(@"Time Cost: %fs", ABS([_tickDate timeIntervalSinceNow])); _tickDate = nil;
    #else
        #define XMNTick  
        #define XMNTock
    #endif
#endif

#pragma mark - NSObject (XMNUtils)

@interface NSObject (XMNUtils)


/**
 判断当前类 是否是系统类
 NS UI开头会被认为是系统类别

 @return YES or NO
 */
+ (BOOL)xmn_isSystemClass;

@end

#pragma mark - NSFileManager 目录,文件相关创建方法

@interface NSFileManager (XMNFile)

/**
 获取document文件目录

 @return 目录
 */
+ (nullable NSString *)xmn_documentPath;

/**
 获取document目录下 某个文件夹路径地址
 如果不存在,则创建文件夹
 @param dirname 文件夹名称
 @return 文件夹路径
 */
+ (nullable NSString *)xmn_directoryPathForDocuments:(nonnull NSString *)dirname;

/**
 获取document目录下 文件路径
 如果文件不存在,则会创建
 @param filename 文件名
 @return 文件路径
 */
+ (nullable NSString *)xmn_filePathForDocuments:(nonnull NSString *)filename;


/**
 获取document目录下某个文件目录下的文件路径
 如果文件不存在,则会创建
 @param filename 文件名
 @param dirname  文件夹名
 @return 文件路径
 */
+ (nullable NSString *)xmn_filePathForDocuments:(nonnull NSString *)filename inDir:(nullable NSString *)dirname;


/**
 文件是否存在

 @param filepath 文件路径
 @return YES or NO
 */
+ (BOOL)xmn_fileExists:(nonnull NSString *)filepath;


/**
 删除文件

 @param filepath 文件路径
 @return YES or NO
 */
+ (BOOL)xmn_deleteFile:(nonnull NSString *)filepath;


/**
 获取文件夹下所有文件名列表
 
 @param dirname 文件夹名称
 @return 文件夹名称
 */
+ (nullable NSArray <NSString *> *)filesOfDirectory:(nonnull NSString *)dirname;

@end


#pragma mark - NSString 字符串相关拓展方法

@interface NSString (XMNValidate)

/**
 判断字符串是否为空字符串
 
 @return YES or NO
 */
- (BOOL)xmn_isEmpty;

/**
 获取MD5加密字符串

 @return MD5加密后 字符串 32位
 */
- (nullable NSString *)xmn_md5;

@end

@interface NSArray<ObjectType> (XMNArray)

/**
 执行map方法,将已有数组内数据 过滤成一个新的数组
 
 @param block 执行过滤的block
 @return 返回结果
 */
- (nonnull NSArray *)xmn_map:(nullable _Nonnull id(^)(ObjectType _Nonnull obj, NSInteger index))block;

/**
 过滤数组中不符合的元素

 @param filterBlock 过滤bock YES obj will be filter
 @return 过滤后的数组元素
 */
- (nonnull NSArray<ObjectType> *)xmn_filter:(nullable BOOL(^)(ObjectType _Nonnull obj))filterBlock;

/**
 执行查询方法,判断数组内是否有符合条件的元素
 
 @param block 执行判断的block方法
 @return YES or NO
 */
- (BOOL)xmn_any:(nullable BOOL(^)(ObjectType _Nonnull obj))block;

/**
 获取对应index的object
 防止数组越界获取
 @param index  index
 @return 获取的object
 */
- (nullable ObjectType)xmn_safeObjectAtIndex:(NSUInteger)index;

@end

#pragma mark - UIColor (XMNColor)

#ifndef RGBA
    /** 生成随机颜色 */
    #define RGBRandom        [UIColor xmn_randomColor]
    /** RGB */
    #define RGBA(r,g,b,a)    [UIColor xmn_colorWithRed:r green:g blue:b alpha:a]
    #define RGB(r,g,b)       RGBA(r,g,b,1.f)
    /** HEX */
    #define HEXAColor(hex,a) [UIColor xmn_colorWithHexString:hex alpha:a]
    #define HEXColor(hex)    HEXAColor(hex,1.f)
#endif


@interface UIColor (XMNColor)

- (nullable NSString *)xmn_colorRGB;

+ (nullable UIColor *)xmn_colorWithRGB:(nonnull NSString *)RGB;

/**
 获取一个随机颜色

 @return UIColor
 */
+ (nonnull UIColor *)xmn_randomColor;

/**
 获取RGB色值对应的UIColor

 @param red   红色色值  0~255
 @param green 绿色色值  0~255
 @param blue  蓝色色值  0~255
 @return UIColor
 */
+ (nonnull UIColor *)xmn_colorWithRed:(CGFloat)red
                                green:(CGFloat)green
                                 blue:(CGFloat)blue;

/**
 获取RGB色值对应的UIColor
 
 @param red   红色色值      0~255
 @param green 绿色色值      0~255
 @param blue  蓝色色值      0~255
 @param alpha 色值透明度     0~1
 @return UIColor
 */
+ (nonnull UIColor *)xmn_colorWithRed:(CGFloat)red
                                green:(CGFloat)green
                                 blue:(CGFloat)blue
                                alpha:(CGFloat)alpha;

/**
 通过16进制字符串 获取对应的UIColor
 支持@“#123456”、 @“0X123456”、 @“123456”三种格式
 @param hex 16进制字符串
 @return UIColor or [UIColor clearColor]
 */
+ (nonnull UIColor *)xmn_colorWithHexString:(nonnull NSString *)hex;

/**
 通过16进制字符串 获取对应的UIColor
 支持@“#123456”、 @“0X123456”、 @“123456”三种格式
 @param hex    16进制字符串
 @param alpha  色值透明度
 @return UIColor or [UIColor clearColor]
 */
+ (nonnull UIColor *)xmn_colorWithHexString:(nonnull NSString *)hex
                                      alpha:(CGFloat)alpha;

@end
