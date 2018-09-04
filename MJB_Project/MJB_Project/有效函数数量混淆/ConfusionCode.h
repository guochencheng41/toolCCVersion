//
//  ConfusionCode.h
//  MJB_Project
//
//  Created by 郭晨成 on 2018/9/1.
//  Copyright © 2018年 wangzhi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ConfusionCode : NSObject
//混淆类
- (void)confusionClassCode:(NSString *)sourceCodeDir;

@end

@interface ConfusionAttributeModel : NSObject

@property (nonatomic, strong) NSString *name;

@property (nonatomic, assign) MJBVariableTypes variableType;

@property (nonatomic, assign) BOOL isStaticVariable;

@property (nonatomic, assign) BOOL isClassification;

@end
