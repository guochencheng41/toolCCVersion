//
//  ConfusionFunction.h
//  MJB_Project
//
//  Created by 郭晨成 on 2018/8/13.
//  Copyright © 2018年 wangzhi. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "ConfusionClass.h"

@interface ConfusionFunction : NSObject

@property (nonatomic, strong) NSString *sourceCodeDir;

@property (nonatomic, strong) NSMutableArray *functionWhiteList;

- (void)confusionFunction;

@end
