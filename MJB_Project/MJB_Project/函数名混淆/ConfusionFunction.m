//
//  ConfusionFunction.m
//  MJB_Project
//
//  Created by 郭晨成 on 2018/8/13.
//  Copyright © 2018年 wangzhi. All rights reserved.
//

#import "ConfusionFunction.h"
#import "ToolClass.h"
#define strIsEmpty(str) ([str isKindOfClass:[NSNull class]]||str==nil||[str length]<1?YES:NO)
static NSString* const kNotificationPrint = @"notificationPrint";
@interface ConfusionFunction()

@property (nonatomic, strong) NSMutableArray *confusionNameArray;

@property (nonatomic, strong) NSString *randomString;
@end

@implementation ConfusionFunction

- (instancetype)init{
    self = [super init];
    if (self) {
        self.confusionNameArray = [NSMutableArray arrayWithCapacity:0];
        self.functionWhiteList = [NSMutableArray arrayWithCapacity:0];
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"functionWhiteList" ofType:@"plist"];
        NSDictionary *dic = [NSDictionary dictionaryWithContentsOfFile:plistPath];
        for (NSArray *arr in dic.allValues) {
            [self.functionWhiteList addObjectsFromArray:arr];
        }
        
        plistPath = [[NSBundle mainBundle] pathForResource:@"frameworkWhiteList" ofType:@"plist"];
        dic = [NSDictionary dictionaryWithContentsOfFile:plistPath];
        for (NSArray *arr in dic.allValues) {
            [self.functionWhiteList addObjectsFromArray:arr];
        }
        
        self.randomString = [ToolClass getRandomStr:5];
    }
    return self;
}

- (void)confusionFunction{
    if (self.sourceCodeDir.length == 0){
        [[NSNotificationCenter defaultCenter]  postNotificationName:kNotificationPrint object:@"请赋值项目根路径..."];
        return;
    }

    [[NSNotificationCenter defaultCenter]  postNotificationName:kNotificationPrint object:@"开始修改类名前缀..."];
    @autoreleasepool {
        //混淆函数声明
        [self confusionFunctionDefine:self.sourceCodeDir];
        //混淆函数调用
        [self confusionFunctionCall:self.sourceCodeDir];
    }
    [[NSNotificationCenter defaultCenter]  postNotificationName:kNotificationPrint object:@"修改类名前缀完成..."];
}

- (void)confusionFunctionDefine:(NSString *)sourceCodeDir{
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
                [className isEqualToString:@"YYModel"]) {
                NSLog(@"%@ 函数define 忽略framework",filePath);
                continue;
            }
            
            //文件夹循环进去
            NSString *path = [sourceCodeDir stringByAppendingPathComponent:filePath];
            if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
                NSLog(@"进入路径%@",path);
                [self confusionFunctionDefine:path];
                continue;
            }
            
            //不是h m 文件忽略
            if (!([fileExtension isEqualToString:@"h"] || [fileExtension isEqualToString:@"m"])){
                continue;
            }
            NSLog(@"混淆函数define 打开%@",fileCompleteClassName);
            
            NSError *error = nil;
            NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
            if (error) {
                printf("打开文件 %s 失败：%s\n", path.UTF8String, error.localizedDescription.UTF8String);
                continue;
            }
            BOOL noBlankSpaceChanged = [self functionDefineReplacement:fileContent regularExpression:@"\\-\\(void\\)" newString:[@"-(void)" stringByAppendingString:self.randomString]];
            BOOL blankSpaceChanged = [self functionDefineReplacement:fileContent regularExpression:@"\\- \\(void\\)" newString:[@"-(void)" stringByAppendingString:self.randomString]];
            if (!noBlankSpaceChanged && !blankSpaceChanged) continue;
            error = nil;
            [fileContent writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
            if (error) {
                printf("保存文件 %s 失败：%s\n", path.UTF8String, error.localizedDescription.UTF8String);
            }
        }
    }
}

- (void)confusionFunctionCall:(NSString *)sourceCodeDir{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:sourceCodeDir error:nil];
    BOOL isDirectory;
    for (NSString *filePath in files) {
        @autoreleasepool{
            NSString *fileExtension = filePath.pathExtension;  //扩展名
            NSString *fileCompleteClassName = filePath.lastPathComponent; //完整文件名
            NSString *className = filePath.lastPathComponent.stringByDeletingPathExtension;  //删除扩展名的文件名
            //framework 忽略
            if ([className isEqualToString:@"framework"] ||
                [fileExtension isEqualToString:@"framework"] ||
                [fileCompleteClassName isEqualToString:@"framework"]) {
                NSLog(@"%@ 函数call 忽略framework",filePath);
                continue;
            }
            
            NSString *path = [sourceCodeDir stringByAppendingPathComponent:filePath];
            if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
                NSLog(@"进入路径%@",path);
                [self confusionFunctionCall:path];
                continue;
            }
            
            if (!([fileExtension isEqualToString:@"h"] || [fileExtension isEqualToString:@"m"])){
                continue;
            }
            NSError *error = nil;
            NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
            if (error) {
                printf("打开文件 %s 失败：%s\n", path.UTF8String, error.localizedDescription.UTF8String);
                continue;
            }
            NSLog(@"混淆函数call >>>打开%@",fileCompleteClassName);
            
            BOOL isChanged = NO;
            for (NSString *functionName in self.confusionNameArray) {
                @autoreleasepool{
                    if ([self functionCallReplacement:fileContent regularExpression:functionName newString:[self.randomString stringByAppendingString:functionName]]) {
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

//替换函数定义
- (BOOL)functionDefineReplacement:(NSMutableString *)originalString
                regularExpression:(NSString *)regularExpression
                        newString:(NSString *)newString{
    __block BOOL isChanged = NO;
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regularExpression options:NSRegularExpressionDotMatchesLineSeparators error:nil];

    NSArray<NSTextCheckingResult *> *matches = [expression matchesInString:originalString options:0 range:NSMakeRange(0, originalString.length)];
    NSLog(@"有%ld处函数定义需混淆",matches.count);
    [matches enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL isWhiteList = NO;
        // (void) 后一位的字符是否是空格
        NSString *endStr = [originalString substringWithRange:NSMakeRange(obj.range.location + obj.range.length, 1)];
        BOOL isHaveBlankSpace = [self isHaveBlankSpace:endStr];
        for (NSString *str in self.functionWhiteList) {
            @autoreleasepool{
                //匹配函数为空、略过
                if (strIsEmpty(str)) continue;
                if (isHaveBlankSpace) {
                    //方法名前有空格
                    if ((obj.range.location + obj.range.length + str.length + 1) > originalString.length) continue;
                    NSString *haveSpaceEndStr = [originalString substringWithRange:NSMakeRange(obj.range.location + obj.range.length + 1, str.length)];
                    if ([haveSpaceEndStr isEqualToString:str]) {
                        isWhiteList = YES;
                        break;
                    }
                }else{
                    //方法名无空格
                    if ((obj.range.location + obj.range.length + str.length) > originalString.length) continue;
                    NSString *noSpaceEndStr = [originalString substringWithRange:NSMakeRange(obj.range.location + obj.range.length, str.length)];
                    if ([noSpaceEndStr isEqualToString:str]) {
                        isWhiteList = YES;
                        break;
                    }
                }
            }
        }
        
        if (!isWhiteList) {
            isChanged = YES;
            NSRange range = obj.range;
            if (isHaveBlankSpace) {
                range = NSMakeRange(range.location, range.length + 1);
            }
            //写入已混淆函数的列表
            NSUInteger startLocation = range.location + range.length;
            NSUInteger endlocation = startLocation - 1; //用于遍历
            NSString *character = @"";
            while (!([character isEqualToString:@":"] ||
                     [character isEqualToString:@"{"] ||
                     [character isEqualToString:@";"] ||
                     [character isEqualToString:@" "] ||
                     [character isEqualToString:@"\n"] ||
                     [character isEqualToString:@"\r"])) {
                endlocation ++;
                character = [originalString substringWithRange:NSMakeRange(endlocation, 1)];
            }
            NSRange functionNameRange = NSMakeRange(startLocation, endlocation - startLocation);
            NSString *functionName = [originalString substringWithRange:functionNameRange];
            //去重
            BOOL isRepeat = NO;
            for (NSString *str in self.confusionNameArray) {
                if ([str isEqualToString:functionName]) {
                    isRepeat = YES;
                }
            }
            if (!isRepeat) {
                [self.confusionNameArray addObject:functionName];
            }
            //混淆
            [originalString replaceCharactersInRange:range withString:newString];
        }
    }];
    return isChanged;
}

//混淆函数调用
- (BOOL)functionCallReplacement:(NSMutableString *)originalString
                regularExpression:(NSString *)regularExpression
                        newString:(NSString *)newString{
    __block BOOL isChanged = NO;
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regularExpression options:NSRegularExpressionDotMatchesLineSeparators error:nil];
    
    NSArray<NSTextCheckingResult *> *matches = [expression matchesInString:originalString options:0 range:NSMakeRange(0, originalString.length)];
    [matches enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //判断是否一个单独的字段
        NSString *headStr = [originalString substringWithRange:NSMakeRange(obj.range.location - 1, 1)];
        NSString *endStr = [originalString substringWithRange:NSMakeRange(obj.range.location + obj.range.length, 1)];
        NSRegularExpression *tLetterRegularExpression = [NSRegularExpression regularExpressionWithPattern:@"[A-Za-z]" options:NSRegularExpressionAllowCommentsAndWhitespace error:nil];
        NSInteger headStrCount = [tLetterRegularExpression numberOfMatchesInString:headStr options:NSMatchingReportProgress range:NSMakeRange(0, 1)];
        NSInteger endStrCount = [tLetterRegularExpression numberOfMatchesInString:endStr options:NSMatchingReportProgress range:NSMakeRange(0, 1)];
        
        //前面是_的需要排除
        if (headStrCount == 0 && endStrCount == 0 && ![headStr isEqualToString:@"_"]) {
            //判断是否是函数调用格式
            BOOL endStrIsOk = [endStr isEqualToString:@"]"] || [endStr isEqualToString:@":"];
            BOOL headStrIsOk = [headStr isEqualToString:@" "] || [headStr isEqualToString:@"("];
            //@selector()  方法的函数调用
            if ([endStr isEqualToString:@")"]) {
                endStrIsOk = YES;
                headStrIsOk = NO;
                NSString *selectorStr = [originalString substringWithRange:NSMakeRange(obj.range.location - 9, 8)];
                if ([selectorStr isEqualToString:@"selector"]) {
                    headStrIsOk = YES;
                }
            }
            if (endStrIsOk && headStrIsOk) {
                if (!isChanged) {
                    isChanged = YES;
                }
                [originalString replaceCharactersInRange:obj.range withString:newString];
            }
        }
    }];
    return isChanged;
}

- (BOOL)isHaveBlankSpace:(NSString *)str{
    NSRange range = [str rangeOfString:@" "];
    if (range.location != NSNotFound) {
        return YES; //yes代表包含空格
    }else {
        return NO; //反之
    }
}

- (NSString *)getRandomStr:(NSInteger)number{
    if (number <= 0) {
        return nil;
    }
    NSString *randomStr = @"";
    while (number > 0) {
        int figure = (arc4random() % 26) + 97;
        char character = figure;
        NSString *tempString = [NSString stringWithFormat:@"%c", character];
        randomStr = [randomStr stringByAppendingString:tempString];
        number --;
    }
    return randomStr;
}




@end
