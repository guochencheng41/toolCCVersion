//
//  MJB_Utils.m
//  MJB_Project
//
//  Created by wangzhi on 2018/7/29.
//  Copyright © 2018年 wangzhi. All rights reserved.
//

#import "ConfusionClass.h"
static NSString* const kNotificationPrint = @"notificationPrint";

@interface ConfusionClass()

@property (nonatomic, strong) NSMutableDictionary *confunsionClassDic;

@end
@implementation ConfusionClass

- (instancetype)init{
    self = [super init];
    if (self) {
        self.confunsionClassDic = [NSMutableDictionary dictionaryWithCapacity:0];
    }
    return self;
}

- (void)confusionClassName{
    if (self.sourceCodeDir.length == 0){
        [[NSNotificationCenter defaultCenter]  postNotificationName:kNotificationPrint object:@"请赋值项目根路径..."];
        return;
    }
    
    if (self.projectFilePath.length == 0){
        [[NSNotificationCenter defaultCenter]  postNotificationName:kNotificationPrint object:@"请工程文件根路径..."];
        return;
    }
    
    [[NSNotificationCenter defaultCenter]  postNotificationName:kNotificationPrint object:@"开始修改类名前缀..."];
    @autoreleasepool {
        //修改类文件名
        [self modifyClassFileName:self.sourceCodeDir];
        [self modifyClassInFileContent:self.sourceCodeDir];
    }
    [[NSNotificationCenter defaultCenter]  postNotificationName:kNotificationPrint object:@"修改类名前缀完成..."];
}

//修改类文件 文件名
- (void)modifyClassFileName:(NSString *)sourceCodeDir{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:sourceCodeDir error:nil];
    BOOL isDirectory;
    for (NSString *filePath in files) {
        @autoreleasepool {
            //stringByAppendingPathComponent 路径拼接
            NSString *path = [sourceCodeDir stringByAppendingPathComponent:filePath];
            NSString *oldClassName = filePath.lastPathComponent.stringByDeletingPathExtension;  //删除扩展名的文件名
            NSString *oldCompleteClassName = filePath.lastPathComponent; //完整文件名
            NSString *oldFilePath = [sourceCodeDir stringByAppendingPathComponent:oldCompleteClassName]; //完整路径名
            NSString *fileExtension = filePath.pathExtension;  //扩展名
            
            //framework Library忽略
            if ([oldClassName isEqualToString:@"framework"]
                || [oldClassName isEqualToString:@"Library"]
                || [fileExtension isEqualToString:@"framework"]
                || [oldClassName isEqualToString:@"YYModel"]) {
                continue;
            }
            
            //文件夹 进入路径
            if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
                NSLog(@"进入路径%@",path);
                [self modifyClassFileName:path];
                continue;
            }
            
            if (![fileExtension isEqualToString:@"h"]){
                continue;
            }
            
            if (isWhiteListClass(oldClassName)) {
                NSLog(@"白名单类不混淆>>>>>>%@",oldCompleteClassName);
                continue;
            }
            
            if ([oldClassName rangeOfString:@"+"].location != NSNotFound) {
                NSLog(@"分类不混淆>>>>>>%@",oldClassName);
                continue;
            }
            
            //修改文件
            NSString *newClassName = getRandomClassName();
            NSString *newCompleteClassName = [newClassName stringByAppendingPathExtension:fileExtension];
            NSString *newFilePath = [sourceCodeDir stringByAppendingPathComponent:newCompleteClassName];
            NSLog(@"开始修改 %@ 文件 新类名:%@",oldClassName,newClassName);
            renameFile(oldFilePath, newFilePath);
            //添加混淆类 dic
            [self.confunsionClassDic setObject:newClassName forKey:oldClassName];
            //遍历文件。修改文件名（.m .xib） 和 分类 （只混淆当前目录）
            modifyClassificationFiles(oldClassName, newClassName, sourceCodeDir);
            //修改工程文件的引用
            [self modifyRrojectFile:self.projectFilePath oldName:oldClassName newName:newClassName];
        }
    }
}

//遍历每个文件且打开内容 匹配要修改的类名
- (void)modifyClassInFileContent:(NSString *)sourceCodeDir{
    // 文件内容 Const > DDConst (h,m,swift,xib,storyboard)
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:sourceCodeDir error:nil];
    BOOL isDirectory;
    for (NSString *filePath in files) {
        @autoreleasepool {
            NSString *oldClassName = filePath.lastPathComponent.stringByDeletingPathExtension;  //删除扩展名的文件名
            NSString *fileExtension = filePath.pathExtension;  //扩展名
            //framework Library忽略
            if ([oldClassName isEqualToString:@"framework"]
                || [oldClassName isEqualToString:@"Library"]
                || [fileExtension isEqualToString:@"framework"]
                || [oldClassName isEqualToString:@"YYModel"]) {
                continue;
            }
            
            //stringByAppendingPathComponent 路径拼接
            NSString *path = [sourceCodeDir stringByAppendingPathComponent:filePath];
            if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
                [self modifyClassInFileContent:path];
                continue;
            }
            
            if ((isNeedConfused(filePath.pathExtension))) {
                NSError *error = nil;
                NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
                if (error) {
                    printf("打开文件 %s 失败：%s\n", path.UTF8String, error.localizedDescription.UTF8String);
                    continue;
                }
                BOOL isChanged = NO;
                for (NSString *key in self.confunsionClassDic.allKeys) {
                    @autoreleasepool {
                        NSString *value = [self.confunsionClassDic objectForKey:key];
                        if (regularReplacement(fileContent, key, value)) {
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
}

//修改同同名的其它格式文件(.m、.xib) 以及 修改分类名称
void modifyClassificationFiles(NSString *oldClassName, NSString *newClassName, NSString *sourceCodeDir){
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:sourceCodeDir error:nil];
    BOOL isDirectory;
    for (NSString *filePath in files) {
        @autoreleasepool {
            NSString *path = [sourceCodeDir stringByAppendingPathComponent:filePath];
            if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
                //文件夹忽略
                continue;
            }
            
            //同名 其它格式文件
            NSString *fileName = filePath.lastPathComponent.stringByDeletingPathExtension;  //1、最后一个组成部分。2、删除扩展名
            NSString *fileExtension = filePath.pathExtension;  //扩展名
            if ([fileName isEqualToString:oldClassName]) {
                //修改文件
                NSString *oldFilePath = [[sourceCodeDir stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:fileExtension];
                NSString *newFilePath = [[sourceCodeDir stringByAppendingPathComponent:newClassName] stringByAppendingPathExtension:fileExtension];
                renameFile(oldFilePath, newFilePath);
            }
            
            //修改分类
            if ([fileName rangeOfString:@"+"].location != NSNotFound) {
                NSString *reallyClassName = [fileName substringToIndex:[fileName rangeOfString:@"+"].location];
                if ([reallyClassName isEqualToString:oldClassName]) {
                    NSString *newClassificationName = [newClassName stringByAppendingString:[fileName substringFromIndex:[fileName rangeOfString:@"+"].location]];
                    //修改文件
                    NSString *oldFilePath = [[sourceCodeDir stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:fileExtension];
                    NSString *newFilePath = [[sourceCodeDir stringByAppendingPathComponent:newClassificationName] stringByAppendingPathExtension:fileExtension];
                    renameFile(oldFilePath, newFilePath);
                }
            }
        }
    }
}

//类文件名：旧类名替换成新的
BOOL regularReplacement(NSMutableString *originalString, NSString *regularExpression, NSString *newString) {
    __block BOOL isChanged = NO;
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regularExpression options:NSRegularExpressionAnchorsMatchLines|NSRegularExpressionUseUnixLineSeparators error:nil];
    NSArray<NSTextCheckingResult *> *matches = [expression matchesInString:originalString options:0 range:NSMakeRange(0, originalString.length)];
    [matches enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //判断是否一个单独的字段
        NSString *headStr = [originalString substringWithRange:NSMakeRange(obj.range.location - 1, 1)];
        NSString *endStr = [originalString substringWithRange:NSMakeRange(obj.range.location + obj.range.length, 1)];
        NSRegularExpression *tLetterRegularExpression = [NSRegularExpression regularExpressionWithPattern:@"[A-Za-z]" options:NSRegularExpressionCaseInsensitive error:nil];
        NSInteger headStrCount = [tLetterRegularExpression numberOfMatchesInString:headStr options:NSMatchingReportProgress range:NSMakeRange(0, 1)];
        NSInteger endStrCount = [tLetterRegularExpression numberOfMatchesInString:endStr options:NSMatchingReportProgress range:NSMakeRange(0, 1)];
        
        if (headStrCount == 0 && endStrCount == 0
            && ![headStr isEqualToString:@"_"]
            && ![headStr isEqualToString:@"+"]
            && ![headStr isEqualToString:@"/"])  //一些框架的引用会被错误的识别为类
        {
            //Format one: @class className
            NSString *classPrefix = [originalString substringWithRange:NSMakeRange(obj.range.location - 7, 6)];
            BOOL isOneFormat = [classPrefix isEqualToString:@"@class"];
            
            //Format two: @interface className
            NSString *interfacePrefix = [originalString substringWithRange:NSMakeRange(obj.range.location - 11, 10)];
            BOOL isTwoFormat = [interfacePrefix isEqualToString:@"@interface"];
            
            //Format three: className * || className*
            NSString *threeFormatEnd2 = [originalString substringWithRange:NSMakeRange(obj.range.location + obj.range.length, 2)];
            BOOL isThreeFormat = [threeFormatEnd2 isEqualToString:@" *"] || [endStr isEqualToString:@"*"];
            
            //Format four: className.h  className.m  className+
            BOOL isFourFormat = [threeFormatEnd2 isEqualToString:@".h"] || [threeFormatEnd2 isEqualToString:@".m"] || [endStr isEqualToString:@"+"];
            
            //Format five: @implementation className
            NSString *implementationPrefix = [originalString substringWithRange:NSMakeRange(obj.range.location - 16, 15)];
            BOOL isFiveFormat = [implementationPrefix isEqualToString:@"@implementation"];
            
            //Format six: [className ....
            BOOL isSixFormat = [headStr isEqualToString:@"["];
            
            //Format seven:    : className
            NSString *headStr2 = [originalString substringWithRange:NSMakeRange(obj.range.location - 2, 2)];
            BOOL isSevenFormat = [headStr2 isEqualToString:@": "];
            
            //Format eight:    "ClassName"  字符串
            BOOL isEightFormat = [headStr isEqualToString:@"\""] && [endStr isEqualToString:@"\""];
            
            if (isOneFormat || isTwoFormat || isThreeFormat || isFourFormat || isFiveFormat || isSixFormat || isSevenFormat
                || isEightFormat) {
                if (!isChanged) {
                    isChanged = YES;
                }
                [originalString replaceCharactersInRange:obj.range withString:newString];
            }
        }
    }];
    return isChanged;
}

//改文件名称
void renameFile(NSString *oldPath, NSString *newPath) {
    NSError *error;
    [[NSFileManager defaultManager] moveItemAtPath:oldPath toPath:newPath error:&error];
    if (error) {
        printf("修改文件名称失败。\n  oldPath=%s\n  newPath=%s\n  ERROR:%s\n", oldPath.UTF8String, newPath.UTF8String, error.localizedDescription.UTF8String);
    }else{
        printf("修改文件名称成功。\n  oldPath=%s\n  newPath=%s\n", oldPath.UTF8String, newPath.UTF8String);
    }
}

#pragma mark - Project File
- (void)modifyRrojectFile:(NSString *)projectFilePath
                  oldName:(NSString *)oldName
                  newName:(NSString *)newName{
    NSError *error = nil;
    NSMutableString *projectContent = [NSMutableString stringWithContentsOfFile:projectFilePath encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        [[NSNotificationCenter defaultCenter]  postNotificationName:kNotificationPrint object:[NSString stringWithFormat:@"打开工程文件 %s 失败：%s\n", projectFilePath.UTF8String, error.localizedDescription.UTF8String]];
        return;
    }
    [self projectFileReplace:projectContent regularexpression:oldName newString:newName];
    [projectContent writeToFile:projectFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

//替换工程文件内容
- (BOOL)projectFileReplace:(NSMutableString *)originalString
         regularexpression:(NSString *)regularExpression
                 newString:(NSString *)newString{
    
    __block BOOL isChanged = NO;
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regularExpression options:NSRegularExpressionAnchorsMatchLines|NSRegularExpressionUseUnixLineSeparators error:nil];
    NSArray<NSTextCheckingResult *> *matches = [expression matchesInString:originalString options:0 range:NSMakeRange(0, originalString.length)];
    [matches enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //判断是否一个单独的字段
        NSString *headStr = [originalString substringWithRange:NSMakeRange(obj.range.location - 1, 1)];
        NSString *endStr = [originalString substringWithRange:NSMakeRange(obj.range.location + obj.range.length, 1)];
        NSRegularExpression *tLetterRegularExpression = [NSRegularExpression regularExpressionWithPattern:@"[A-Za-z]" options:NSRegularExpressionCaseInsensitive error:nil];
        NSInteger headStrCount = [tLetterRegularExpression numberOfMatchesInString:headStr options:NSMatchingReportProgress range:NSMakeRange(0, 1)];
        NSInteger endStrCount = [tLetterRegularExpression numberOfMatchesInString:endStr options:NSMatchingReportProgress range:NSMakeRange(0, 1)];
        //判断是否是类
        NSString *endStr4 = [originalString substringWithRange:NSMakeRange(obj.range.location + obj.range.length, 4)];
        NSString *endStr2 = [originalString substringWithRange:NSMakeRange(obj.range.location + obj.range.length, 2)];
        
        if (headStrCount == 0
            && endStrCount == 0
            && ![headStr isEqualToString:@"_"]  // MM_ClassName  ClassName 与其它类相同 会被识别为其他类
            && ![headStr isEqualToString:@"+"])  // 分类 与 类文件名相同 会被识别为类
        {
            if ([endStr4 isEqualToString:@".xib"] ||
                [endStr2 isEqualToString:@".h"] ||
                [endStr2 isEqualToString:@".m"] ||
                [endStr isEqualToString:@"+"]) {
                if (!isChanged) isChanged = YES;
                [originalString replaceCharactersInRange:obj.range withString:newString];
            }
        }
    }];
    return isChanged;
}

BOOL isNeedConfused(NSString *fileExtension){
    return ([fileExtension isEqualToString:@"h"]
            || [fileExtension isEqualToString:@"m"]
            || [fileExtension isEqualToString:@"pch"]
            || [fileExtension isEqualToString:@"swift"]
            || [fileExtension isEqualToString:@"xib"]
            || [fileExtension isEqualToString:@"storyboard"]);
}

BOOL isWhiteListClass(NSString *className){
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"classWhiteList" ofType:@"plist"];
    NSArray *arr = [NSArray arrayWithContentsOfFile:plistPath];
    BOOL isWhiteListClass = NO;
    for (NSString *whiteClassName in arr) {
        if ([whiteClassName isEqualToString:className]) {
            isWhiteListClass = YES;
            break;
        }
    }
    return isWhiteListClass;
}

NSString* getRandomClassName(){
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"classNameList" ofType:@"plist"];
    NSArray *arr = [NSArray arrayWithContentsOfFile:plistPath];
    NSInteger classNameWordNum = arc4random() % 3 + 3;
    NSString *className = [NSString string];
    for (NSInteger index = 0; index < classNameWordNum; index++) {
        NSInteger arrayIndex = random() % arr.count;
        className = [className stringByAppendingString:arr[arrayIndex]];
    }
    return className;
}

@end
