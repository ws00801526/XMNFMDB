//
//  XMNTeacher.h
//  XMNFMDBExample
//
//  Created by XMFraker on 17/1/23.
//  Copyright © 2017年 XMFraker. All rights reserved.
//

#import <UIKit/UIKit.h>



@class XMNClass;

@interface XMNPerson : NSObject

@property (strong, nonatomic)   NSMutableString *mutableName;
@property (copy, nonatomic)   NSString *name;
@property (assign, nonatomic) NSInteger age;
@property (assign, nonatomic) NSInteger sex;

@property (strong, nonatomic) UIImage *avatar;

@property (strong, nonatomic) UIColor *faceColor;
@property (assign, nonatomic) CGRect rect;

@end

@interface XMNTeacher : XMNPerson

@property (strong, nonatomic) XMNClass *teacClass;

@end


@interface XMNStudent : XMNPerson

@property (copy, nonatomic)   NSString *hobby;

@end

@class XMNStudent;
@interface XMNClass : NSObject

@property (copy, nonatomic)   NSString *name;

@property (copy, nonatomic)   NSString *time;
@property (copy, nonatomic)   NSArray<XMNStudent *> *students;

@end
