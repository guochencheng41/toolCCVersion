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

@end
