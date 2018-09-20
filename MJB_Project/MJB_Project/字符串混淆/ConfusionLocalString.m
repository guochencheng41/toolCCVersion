//
//  ConfusionLocalString.m
//  MJB_Project
//
//  Created by 郭晨成 on 2018/8/27.
//  Copyright © 2018年 wangzhi. All rights reserved.
//
//10743 字符串

#import "ConfusionLocalString.h"
static NSString *keyString = @"LocalSrrayncontentsceCodeOfFilryAtPathgWhiteListDieExistsAtP";
@interface ConfusionLocalString()

@property (nonatomic, strong) NSArray *localStringList;

@property (nonatomic, assign) NSInteger number;

@end

@implementation ConfusionLocalString

- (instancetype)init{
    self = [super init];
    if (self) {
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"LocalStringWhiteList" ofType:@"plist"];
        self.localStringList = [NSArray arrayWithContentsOfFile:plistPath];
    }
    return self;
}

- (void)confusionLocalString:(NSString *)sourceCodeDir{
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
                [className isEqualToString:@"Library"] ||
                [className isEqualToString:@"GTMNSString+HTML"] ||
                [className isEqualToString:@"JSReactKit"] ||
                [className isEqualToString:@"YYModel"]) {
                NSLog(@"%@ 字符串混淆 忽略",filePath);
                continue;
            }
            
            //文件夹循环进去
            NSString *path = [sourceCodeDir stringByAppendingPathComponent:filePath];
            if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
                NSLog(@"进入路径%@",path);
                [self confusionLocalString:path];
                continue;
            }
            
            //不是h m 文件忽略
            if (!([fileExtension isEqualToString:@"h"] || [fileExtension isEqualToString:@"m"])){
                continue;
            }
            NSLog(@"字符串混淆 打开%@",fileCompleteClassName);
            
            NSError *error = nil;
            NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
            if (error) {
                printf("打开文件 %s 失败：%s\n", path.UTF8String, error.localizedDescription.UTF8String);
                continue;
            }
            BOOL isChanged = NO;
            BOOL change = [self regularReplacement:fileContent];
            if (change) {
                isChanged = YES;
            }
            if (!isChanged) continue;
            error = nil;
            [fileContent writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
            if (error) {
                printf("保存文件 %s 失败：%s\n", path.UTF8String, error.localizedDescription.UTF8String);
            }
            NSLog(@"%ld",self.number);
        }
    }
}

//替换本地字符串
- (BOOL)regularReplacement:(NSMutableString *)originalString{
    __block BOOL isChanged = NO;
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:@"@\"" options:NSRegularExpressionDotMatchesLineSeparators error:nil];
    NSArray<NSTextCheckingResult *> *matches = [expression matchesInString:originalString options:0 range:NSMakeRange(0, originalString.length)];
    NSLog(@"匹配%ld个字符串",matches.count);
    [matches enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSInteger endLocation = obj.range.location + obj.range.length;
        NSInteger expressionEndLocation = endLocation;
        BOOL isStrEnd = NO;
        NSString *character;
        NSString *headStr = [originalString substringWithRange:NSMakeRange(obj.range.location - 1, 1)];
        BOOL isFormatSymbol = [headStr isEqualToString:@"%"];
        while (!isStrEnd
               && (endLocation - expressionEndLocation) < 150
               && endLocation < originalString.length
               && !isFormatSymbol) {
            character = [originalString substringWithRange:NSMakeRange(endLocation, 1)];
            if ([character isEqualToString:@"\""]) {
                NSString *headStr = [originalString substringWithRange:NSMakeRange(endLocation - 1, 1)];
                if (![headStr isEqualToString:@"\\"]) {
                    isStrEnd = YES;
                    break;
                }
            }
            endLocation ++;
        }
        
        BOOL isCurrentFormat = NO;
        if (isStrEnd && obj.range.location > 80) {
            //白名单格式
            isCurrentFormat = YES;
            NSRange headRange = NSMakeRange(obj.range.location - 80, 80);
            NSString *headStr80 = [originalString substringWithRange:headRange];
            for (NSString *str in self.localStringList) {
                if ([headStr80 containsString:str]) {
                    isCurrentFormat = NO;
                    break;
                }
            }
        }
        
        NSInteger targetStrLength = endLocation - obj.range.location + 1;
        if (isStrEnd && isCurrentFormat && targetStrLength > 3) {
            NSRange targetStrRange = NSMakeRange(obj.range.location, targetStrLength);
            NSString *targetStr = [originalString substringWithRange:targetStrRange];
            NSMutableString *targetMutStr = [NSMutableString stringWithString:targetStr];
            NSInteger random = arc4random() % (targetStrLength - 3);
            //有转义字符的情况  不能乱插
            if ([targetMutStr containsString:@"\\"]) {
                [targetMutStr insertString:keyString atIndex:2];
            }else{
                 [targetMutStr insertString:keyString atIndex:random + 2];
            }
            
            NSString *finallyStr = [NSString stringWithString:targetMutStr];
            finallyStr = [@"mm_getReallyStr(" stringByAppendingString:finallyStr];
            finallyStr = [finallyStr stringByAppendingString:@")"];
            [originalString replaceCharactersInRange:targetStrRange withString:finallyStr];
            isChanged = YES;
            self.number ++;
        }
    }];
    return isChanged;
}

@end
