//
//  MJB_Utils.h
//  MJB_Project
//
//  Created by wangzhi on 2018/7/29.
//  Copyright © 2018年 wangzhi. All rights reserved.
//

#import <Foundation/Foundation.h> 
@interface ConfusionClass : NSObject

//项目根路径
@property (nonatomic, strong) NSString *sourceCodeDir;

//工程文件路径
@property (nonatomic, strong) NSString *projectFilePath;

- (void)confusionClassName;
 
@end
