//
//  PublicHeader.h
//  MJB_Project
//
//  Created by 郭晨成 on 2018/8/30.
//  Copyright © 2018年 wangzhi. All rights reserved.
//

#ifndef PublicHeader_h
#define PublicHeader_h
#import <Foundation/Foundation.h>

static NSInteger variableTypesNumber = 4;  //对象类型
static NSInteger variableTypesAllNumber = 6;  //对象类型
static NSInteger confunsionStaticMinLength = 10;
typedef NS_ENUM(NSInteger, MJBVariableTypes){
    MJBVariableTypeNSString = 0,
    MJBVariableTypeNSArray,
    MJBVariableTypeNSDictionary,
    MJBVariableTypeUILabel,
    MJBVariableTypeNSInteger,
    MJBVariableTypeVoid
};

//判断字符串是否为空
#define strIsEmpty(str) ([str isKindOfClass:[NSNull class]]||str==nil||[str length]<1?YES:NO)

//代码运行时间
#define MMSTART NSDate *startTime = [NSDate date]
#define MMEND NSLog(@"Time: %f", -[startTime timeIntervalSinceNow])
#endif
