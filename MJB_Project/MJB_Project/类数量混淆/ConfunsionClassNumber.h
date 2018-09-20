//
//  ConfunsionClassNumber.h
//  MJB_Project
//
//  Created by 郭晨成 on 2018/9/5.
//  Copyright © 2018年 wangzhi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ConfunsionClassNumber : NSObject
@property (nonatomic, strong) NSMutableArray *modelNameArray;

- (void)confusionClassCode:(NSString *)sourceCodeDir;

@end


@interface ClassModel : NSObject

@property (nonatomic, strong) NSArray *functionNameArray;

@property (nonatomic, strong) NSString *className;

@end
