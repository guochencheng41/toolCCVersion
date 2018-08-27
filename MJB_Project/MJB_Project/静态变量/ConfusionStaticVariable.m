//
//  ConfusionStaticVariable.m
//  MJB_Project
//
//  Created by 郭晨成 on 2018/8/24.
//  Copyright © 2018年 wangzhi. All rights reserved.
//

#import "ConfusionStaticVariable.h"
#import "ToolClass.h"
static NSString* const kNotificationPrint = @"notificationPrint";
@interface ConfusionStaticVariable()

@property (nonatomic, strong) NSMutableArray *randomNameArray;

@property (nonatomic, strong) NSMutableDictionary *variableNameDic;

@end

@implementation ConfusionStaticVariable

- (instancetype)init{
    self = [super init];
    if (self) {
        self.randomNameArray = [NSMutableArray arrayWithCapacity:0];
        self.variableNameDic = [NSMutableDictionary dictionaryWithCapacity:0];
    }
    return self;
}

- (void)confusionStaticVariable{
    if (self.sourceCodeDir.length == 0){
        [[NSNotificationCenter defaultCenter]  postNotificationName:kNotificationPrint object:@"请赋值项目根路径..."];
        return;
    }
    
    [[NSNotificationCenter defaultCenter]  postNotificationName:kNotificationPrint object:@"开始修改静态变量..."];
    @autoreleasepool {
        //查找变量声明
        [self confusionVariableDefine:self.sourceCodeDir];
        NSLog(@"%@",self.variableNameDic);
        //混淆变量
        [self confusionVariableCall:self.sourceCodeDir];
    }
    [[NSNotificationCenter defaultCenter]  postNotificationName:kNotificationPrint object:@"修改静态变量完成..."];
}

- (void)confusionVariableDefine:(NSString *)sourceCodeDir{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:sourceCodeDir error:nil];
    BOOL isDirectory;
    for (NSString *filePath in files) {
        //stringByAppendingPathComponent 路径拼接
        @autoreleasepool{
            NSString *className = filePath.lastPathComponent.stringByDeletingPathExtension;  //删除扩展名的文件名
            NSString *fileCompleteClassName = filePath.lastPathComponent; //完整文件名//完整路径名
            NSString *fileExtension = filePath.pathExtension;  //扩展名
            
            //framework 忽略
            if ([className isEqualToString:@"framework"] ||
                [fileExtension isEqualToString:@"framework"] ||
                [fileCompleteClassName isEqualToString:@"framework"] ||
                [className isEqualToString:@"Library"] ||
                [className isEqualToString:@"YYModel"]) {
                NSLog(@"%@ 变量define 忽略framework",filePath);
                continue;
            }
            
            //文件夹循环进去
            NSString *path = [sourceCodeDir stringByAppendingPathComponent:filePath];
            if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
                NSLog(@"进入路径%@",path);
                [self confusionVariableDefine:path];
                continue;
            }
            
            //不是h m 文件忽略
            if (!([fileExtension isEqualToString:@"h"] || [fileExtension isEqualToString:@"m"])){
                continue;
            }
            NSLog(@"变量define 打开%@",fileCompleteClassName);
            
            NSError *error = nil;
            NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
            if (error) {
                printf("打开文件 %s 失败：%s\n", path.UTF8String, error.localizedDescription.UTF8String);
                continue;
            }
            [self findVariableDefine:fileContent regularExpression:@"const"];
            [self findVariableDefine:fileContent regularExpression:@"static"];
        }
    }
}

//替换变量定义
- (void)findVariableDefine:(NSMutableString *)originalString
         regularExpression:(NSString *)regularExpression{
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regularExpression options:NSRegularExpressionDotMatchesLineSeparators error:nil];
    
    NSArray<NSTextCheckingResult *> *matches = [expression matchesInString:originalString options:0 range:NSMakeRange(0, originalString.length)];
    [matches enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        // (void) 后一位的字符是否是空格
        NSString *endStr = [originalString substringWithRange:NSMakeRange(obj.range.location + obj.range.length, 1)];
        NSString *headStr = [originalString substringWithRange:NSMakeRange(obj.range.location - 1, 1)];
        NSRegularExpression *tLetterRegularExpression = [NSRegularExpression regularExpressionWithPattern:@"[A-Za-z]" options:NSRegularExpressionAllowCommentsAndWhitespace error:nil];
        NSInteger headStrCount = [tLetterRegularExpression numberOfMatchesInString:headStr options:NSMatchingReportProgress range:NSMakeRange(0, 1)];
        NSInteger endStrCount = [tLetterRegularExpression numberOfMatchesInString:endStr options:NSMatchingReportProgress range:NSMakeRange(0, 1)];
        
        if (((headStrCount + endStrCount) == 0) && ![endStr isEqualToString:@"_"] && ![headStr isEqualToString:@"_"]) {
            NSInteger markStrEndLocation = obj.range.location + obj.range.length;
            NSString *markEndStr = [originalString substringWithRange:NSMakeRange(markStrEndLocation, 1)];
            BOOL isTheModifier = YES; //是否是修饰符（const 、 static）
            while (![markEndStr isEqualToString:@"="] && ![markEndStr isEqualToString:@";"]) {
                markStrEndLocation ++;
                markEndStr = [originalString substringWithRange:NSMakeRange(markStrEndLocation, 1)];
                if ([markEndStr isEqualToString:@")"] ||
                    [markEndStr isEqualToString:@"{"] ||
                    [markEndStr isEqualToString:@"["]) {
                    isTheModifier = NO;
                    break;
                }
            }
            if (isTheModifier) {
                NSInteger reallyEndLocation = markStrEndLocation - 1;
                NSString *reallyEndStr = [originalString substringWithRange:NSMakeRange(reallyEndLocation, 1)];
                while ([reallyEndStr isEqualToString:@" "]) {
                    reallyEndLocation --;
                    reallyEndStr = [originalString substringWithRange:NSMakeRange(reallyEndLocation, 1)];
                }
                
                NSInteger startLocation = reallyEndLocation;
                NSString *startStr = [originalString substringWithRange:NSMakeRange(startLocation, 1)];
                while ([startStr isEqualToString:@"_"] || [ToolClass isLetterWord:startStr]) {
                    startLocation --;
                    startStr = [originalString substringWithRange:NSMakeRange(startLocation, 1)];
                }
                
                NSInteger reallyStartLocation = startLocation + 1;
                NSRange staticVariableRange = NSMakeRange(reallyStartLocation, reallyEndLocation - reallyStartLocation + 1);
                NSString *variableName = [originalString substringWithRange:staticVariableRange];
                BOOL isRepeat = NO;
                for (NSString *str in self.variableNameDic.allKeys) {
                    if ([str isEqualToString:variableName]) {
                        isRepeat = YES;
                    }
                }
                
                BOOL isWhiteList = [ToolClass isWhiteList:variableName listName:@"variableWhiteList"];
                if (!isRepeat && !isWhiteList) {
                    NSString *randomName = [self getRandomVariableName];
                    NSLog(@"%@查找对照",randomName);
                    NSLog(@"%@查找对照",variableName);
                    [self.variableNameDic setObject:randomName forKey:variableName];
                }
            }
        }
    }];
}

- (void)confusionVariableCall:(NSString *)sourceCodeDir{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:sourceCodeDir error:nil];
    BOOL isDirectory;
    for (NSString *filePath in files) {
        //stringByAppendingPathComponent 路径拼接
        @autoreleasepool{
            NSString *className = filePath.lastPathComponent.stringByDeletingPathExtension;  //删除扩展名的文件名
            NSString *fileCompleteClassName = filePath.lastPathComponent; //完整文件名//完整路径名
            NSString *fileExtension = filePath.pathExtension;  //扩展名
            
            //framework 忽略
            if ([className isEqualToString:@"framework"] ||
                [fileExtension isEqualToString:@"framework"] ||
                [fileCompleteClassName isEqualToString:@"framework"] ||
                [className isEqualToString:@"Library"]) {
                NSLog(@"%@ 变量call 忽略framework",filePath);
                continue;
            }
            
            //文件夹循环进去
            NSString *path = [sourceCodeDir stringByAppendingPathComponent:filePath];
            if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
                NSLog(@"进入路径%@",path);
                [self confusionVariableCall:path];
                continue;
            }
            
            //不是h m 文件忽略
            if (!([fileExtension isEqualToString:@"h"] || [fileExtension isEqualToString:@"m"])){
                continue;
            }
            NSLog(@"变量call 打开%@",fileCompleteClassName);
            
            NSError *error = nil;
            NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
            if (error) {
                printf("打开文件 %s 失败：%s\n", path.UTF8String, error.localizedDescription.UTF8String);
                continue;
            }
            BOOL isChanged = NO;
            for (NSString *variableName in self.variableNameDic.allKeys) {
                @autoreleasepool{
                    BOOL change = [self regularReplacement:fileContent regularExpression:variableName newString:[self.variableNameDic objectForKey:variableName]];
                    if (change) {
                        isChanged = YES;
                    }
                }
            }
            if (!isChanged) continue;
            error = nil;
            [fileContent writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
            if (error) {
                printf("保存文件 %s 失败：%s\n", path.UTF8String, error.localizedDescription.UTF8String);
            }
        }
    }
}

//变量名称替换
- (BOOL)regularReplacement:(NSMutableString *)originalString regularExpression:(NSString *)regularExpression newString:(NSString *)newString {
    __block BOOL isChanged = NO;
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regularExpression options:NSRegularExpressionDotMatchesLineSeparators error:nil];
    NSArray<NSTextCheckingResult *> *matches = [expression matchesInString:originalString options:0 range:NSMakeRange(0, originalString.length)];
    [matches enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //判断是否一个单独的字段
        NSString *headStr = [originalString substringWithRange:NSMakeRange(obj.range.location - 1, 1)];
        NSString *endStr = [originalString substringWithRange:NSMakeRange(obj.range.location + obj.range.length, 1)];
        NSRegularExpression *tLetterRegularExpression = [NSRegularExpression regularExpressionWithPattern:@"[A-Za-z]" options:NSRegularExpressionCaseInsensitive error:nil];
        NSInteger headStrCount = [tLetterRegularExpression numberOfMatchesInString:headStr options:NSMatchingReportProgress range:NSMakeRange(0, 1)];
        NSInteger endStrCount = [tLetterRegularExpression numberOfMatchesInString:endStr options:NSMatchingReportProgress range:NSMakeRange(0, 1)];
        
        if (((headStrCount + endStrCount) == 0) && ![endStr isEqualToString:@"_"] && ![headStr isEqualToString:@"_"]) {
            isChanged = YES;
            [originalString replaceCharactersInRange:obj.range withString:newString];
            NSLog(@"将%@ 替换为%@",regularExpression,newString);
        }
    }];
    return isChanged;
}

- (NSString *)getRandomVariableName{
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"staticVariableNameLsit" ofType:@"plist"];
    NSArray *arr = [NSArray arrayWithContentsOfFile:plistPath];
    NSInteger classNameWordNum = arc4random() % 3 + 3;
    NSString *className = [NSString string];
    BOOL isNoRepeat = NO;
    while (!isNoRepeat) {
        isNoRepeat = YES;
        for (NSInteger index = 0; index < classNameWordNum; index++) {
            NSInteger arrayIndex = random() % arr.count;
            className = [className stringByAppendingString:arr[arrayIndex]];
        }
        
        //去重
        for (NSString *str in self.randomNameArray) {
            if ([str isEqualToString:className]) {
                isNoRepeat = NO;
                break;
            }
        }
    }
    [self.randomNameArray addObject:className];
    return className;
}

- (BOOL)isHaveBlankSpace:(NSString *)str{
    NSRange range = [str rangeOfString:@" "];
    if (range.location != NSNotFound) {
        return YES; //yes代表包含空格
    }else {
        return NO; //反之
    }
}
@end
