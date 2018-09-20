//
//  ConfusionImageName.m
//  MJB_Project
//
//  Created by 郭晨成 on 2018/9/6.
//  Copyright © 2018年 wangzhi. All rights reserved.
//

#import "ConfusionImageName.h"
@interface ConfusionImageName()

@property (nonatomic, strong) NSMutableDictionary *imageNameDic;

@end

@implementation ConfusionImageName

- (instancetype)init{
    self = [super init];
    if (self) {
        self.imageNameDic = [NSMutableDictionary dictionaryWithCapacity:0];
    }
    return self;
}

- (void)confusionImage:(NSString *)sourceCodeDir projectFile:(NSString *)projectFile{
    [self searchImageSourcePath:sourceCodeDir];
    
    [self confunsionImageInProjectFile:projectFile];
    
    [self openClassChangeImageName:sourceCodeDir];
}

- (void)searchImageSourcePath:(NSString *)sourceCodeDir{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:sourceCodeDir error:nil];
    BOOL isDirectory;
    for (NSString *filePath in files) {
        @autoreleasepool {
            //stringByAppendingPathComponent 路径拼接
            NSString *path = [sourceCodeDir stringByAppendingPathComponent:filePath];
            NSString *oldClassName = filePath.lastPathComponent.stringByDeletingPathExtension;  //删除扩展名的文件名
            //图片资源文件夹 进入路径
            if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory && [oldClassName isEqualToString:@"Resource"]) {
                NSLog(@"进入路径%@",path);
                [self confusionImageName:path];
                continue;
            }
            
        }
    }
}

- (void)confusionImageName:(NSString *)sourceCodeDir{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:sourceCodeDir error:nil];
    BOOL isDirectory;
    for (NSString *filePath in files) {
        @autoreleasepool {
            //stringByAppendingPathComponent 路径拼接
            NSString *fileName = filePath.lastPathComponent.stringByDeletingPathExtension;  //删除扩展名的文件名
            NSString *path = [sourceCodeDir stringByAppendingPathComponent:filePath];
            NSString *fileExtension = filePath.pathExtension;  //扩展名
            NSString *oldFullName = filePath.lastPathComponent;
            
            //图片资源文件夹 进入路径
            if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
                NSLog(@"进入路径%@",path);
                [self confusionImageName:path];
                continue;
            }
            
            if ([fileExtension isEqualToString:@"png"]) {
                BOOL isLength = [fileName containsString:@"@2x"] || [fileName containsString:@"@3x"];
                NSInteger length = isLength ? 13 : 10;
                if ([fileName containsString:@"_"] && fileName.length > length) {
                    NSString *suffixStr;
                    if ([fileName containsString:@"@2x"]) {
                        suffixStr = @"@2x";
                        fileName = [fileName stringByReplacingOccurrencesOfString:suffixStr withString:@""];
                    }
                    
                    if ([fileName containsString:@"@3x"]) {
                        suffixStr = @"@3x";
                        fileName = [fileName stringByReplacingOccurrencesOfString:suffixStr withString:@""];
                    }
                    
                    if ([ToolClass haveNumberWord:fileName]) {
                        continue;
                    }
                    
                    BOOL isNeedAddToArray = YES;
                    NSString *newFileName;
                    for (NSString *changedName in self.imageNameDic.allKeys) {
                        if ([changedName isEqualToString:fileName]) {
                            isNeedAddToArray = NO;
                            newFileName = [self.imageNameDic objectForKey:changedName];
                        }
                    }
                    
                    if (isNeedAddToArray) {
                        newFileName = [ToolClass getRandomStr:0];
                        [self.imageNameDic setObject:newFileName forKey:fileName];
                    }
                    
                    if (!strIsEmpty(suffixStr)) {
                        newFileName = [newFileName stringByAppendingString:suffixStr];
                    }
                    NSString *newCompleteClassName = [newFileName stringByAppendingPathExtension:fileExtension];
                    
                    NSString *newFilePath = [sourceCodeDir stringByAppendingPathComponent:newCompleteClassName];
                    NSError *error;
                    [[NSFileManager defaultManager] moveItemAtPath:path toPath:newFilePath error:&error];
                    if (error) {
                        printf("修改文件名称失败。\n  oldPath=%s\n  newPath=%s\n  ERROR:%s\n", path.UTF8String, newFilePath.UTF8String, error.localizedDescription.UTF8String);
                    }else{
                        printf("修改文件名称成功。\n  oldPath=%s\n  newPath=%s\n", path.UTF8String, newFilePath.UTF8String);
                    }
                }
            }
        }
    }
}

- (void)confunsionImageInProjectFile:(NSString *)projectFilePath{
    NSError *error = nil;
    NSMutableString *projectContent = [NSMutableString stringWithContentsOfFile:projectFilePath encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        return;
    }
    
    for (NSString *key in self.imageNameDic.allKeys) {
        @autoreleasepool {
            NSString *imageName = [self.imageNameDic objectForKey:key];
            [self projectFileReplace:projectContent regularexpression:key newString:imageName];
        }
    }
    
    [projectContent writeToFile:projectFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

//替换工程文件内容
- (void)projectFileReplace:(NSMutableString *)originalString
         regularexpression:(NSString *)regularExpression
                 newString:(NSString *)newString{
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
        NSString *endStr7 = [originalString substringWithRange:NSMakeRange(obj.range.location + obj.range.length + 3, 4)];
        
        if (headStrCount == 0
            && endStrCount == 0
            && ![headStr isEqualToString:@"_"]
            && ![headStr isEqualToString:@"+"]){
            if ([endStr4 isEqualToString:@".png"]|| [endStr7 isEqualToString:@".png"]) {
                [originalString replaceCharactersInRange:obj.range withString:newString];
            }
        }
    }];
}

- (void)openClassChangeImageName:(NSString *)sourceCodeDir{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:sourceCodeDir error:nil];
    BOOL isDirectory;
    for (NSString *filePath in files) {
        @autoreleasepool {
            NSString *path = [sourceCodeDir stringByAppendingPathComponent:filePath];
            if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
                //文件夹循环进去
                [self openClassChangeImageName:path];
                continue;
            }
            //同名 其它格式文件
            NSString *fileExtension = filePath.pathExtension;  //扩展名
            
            if ([fileExtension isEqualToString:@"h"]
                 || [fileExtension isEqualToString:@"m"]
                 || [fileExtension isEqualToString:@"pch"]
                 || [fileExtension isEqualToString:@"swift"]
                 || [fileExtension isEqualToString:@"xib"]
                 || [fileExtension isEqualToString:@"storyboard"]) {
                NSError *error = nil;
                NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
                if (error) {
                    printf("打开文件 %s 失败：%s\n", path.UTF8String, error.localizedDescription.UTF8String);
                    continue;
                }
                
                for (NSString *imageName in self.imageNameDic.allKeys) {
                    @autoreleasepool {
                        NSString *newName = [self.imageNameDic objectForKey:imageName];
                        NSString *formatOne = [NSString stringWithFormat:@"@\"%@\"",imageName];
                        NSString *formatTwo = [NSString stringWithFormat:@"%@\\.",imageName];
                        NSString *formatThree = [NSString stringWithFormat:@"%@@2x",imageName];
                        [self replaceImageNameInSourceCode:fileContent regularExpression:formatOne isVerifyHeadStr:NO newName:[NSString stringWithFormat:@"@\"%@\"",newName]];
                        [self replaceImageNameInSourceCode:fileContent regularExpression:formatTwo isVerifyHeadStr:YES newName:[NSString stringWithFormat:@"%@.",newName]];
                        [self replaceImageNameInSourceCode:fileContent regularExpression:formatThree isVerifyHeadStr:YES newName:[NSString stringWithFormat:@"%@@2x",newName]];
                    }
                }
                
                error = nil;
                [fileContent writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
                if (error) {
                    printf("保存文件 %s 失败：%s\n", path.UTF8String, error.localizedDescription.UTF8String);
                }
            }
            
        }
    }
}

- (void)replaceImageNameInSourceCode:(NSMutableString *)originalString
                   regularExpression:(NSString *)regularExpression
                     isVerifyHeadStr:(BOOL)isVerifyHeadStr
                             newName:(NSString *)newName{
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regularExpression options:NSRegularExpressionDotMatchesLineSeparators error:nil];
    NSArray<NSTextCheckingResult *> *matches = [expression matchesInString:originalString options:0 range:NSMakeRange(0, originalString.length)];
    [matches enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSRange range = NSMakeRange(obj.range.location - 1, 1);
        NSString *headStr = [originalString substringWithRange:range];
        if (isVerifyHeadStr && ![ToolClass isLetterWord:headStr]) {
            [originalString replaceCharactersInRange:obj.range withString:newName];
        }else{
            [originalString replaceCharactersInRange:obj.range withString:newName];
        }
    }];
}

@end
