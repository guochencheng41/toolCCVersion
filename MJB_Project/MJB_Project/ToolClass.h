//
//  ToolClass.h
//  MJB_Project
//
//  Created by 郭晨成 on 2018/8/27.
//  Copyright © 2018年 wangzhi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ToolClass : NSObject
+ (BOOL)isLetterWord:(NSString *)str;

+ (BOOL)isWhiteList:(NSString *)str listName:(NSString *)listName;

+ (BOOL)haveNumberWord:(NSString *)str;
//number 为0 ： 随机生成10 - 25位
+ (NSString *)getRandomStr:(NSInteger)number;

+ (MJBVariableTypes)getRandomType;

+ (NSString *)getTypeString:(MJBVariableTypes)type;

//通过@implementation 获取类名
+ (NSString *)getClassNameByImplementation:(NSString *)originalString;

+ (BOOL)isContainClassify:(NSString *)originalString;

@end
