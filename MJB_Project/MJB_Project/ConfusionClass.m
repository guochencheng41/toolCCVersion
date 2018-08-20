//
//  MJB_Utils.m
//  MJB_Project
//
//  Created by wangzhi on 2018/7/29.
//  Copyright © 2018年 wangzhi. All rights reserved.
//

#import "ConfusionClass.h"
extern NSString *gSourceCodeDir = @"";  //项目根路径
extern NSString *kProjectFilePath = @"";  //工程文件路径
extern NSString *kNotificationPrint = @"notificationPrint";
@implementation ConfusionClass

void executeModifyClassNamePrefix(void){

	if (gSourceCodeDir.length == 0){
		[[NSNotificationCenter defaultCenter]  postNotificationName:kNotificationPrint object:@"请赋值项目根路径..."];
		return;
	}
    
    if (kProjectFilePath.length == 0){
        [[NSNotificationCenter defaultCenter]  postNotificationName:kNotificationPrint object:@"请工程文件根路径..."];
        return;
    }
	
    [[NSNotificationCenter defaultCenter]  postNotificationName:kNotificationPrint object:@"开始修改类名前缀..."];
    @autoreleasepool {
        //修改类文件名
        newModifyFilesClassName(gSourceCodeDir);
    }
    [[NSNotificationCenter defaultCenter]  postNotificationName:kNotificationPrint object:@"修改类名前缀完成..."];
}


void newModifyFilesClassName(NSString *sourceCodeDir){
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:sourceCodeDir error:nil];
    BOOL isDirectory;
    for (NSString *filePath in files) {
        @autoreleasepool {
            //stringByAppendingPathComponent 路径拼接
            NSString *path = [sourceCodeDir stringByAppendingPathComponent:filePath];
            if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
                NSLog(@"进入路径%@",path);
                newModifyFilesClassName(path);
                continue;
            }
            
            NSString *oldClassName = filePath.lastPathComponent.stringByDeletingPathExtension;  //删除扩展名的文件名
            NSString *oldCompleteClassName = filePath.lastPathComponent; //完整文件名
            NSString *oldFilePath = [sourceCodeDir stringByAppendingPathComponent:oldCompleteClassName]; //完整路径名
            NSString *fileExtension = filePath.pathExtension;  //扩展名
            
            if (!([fileExtension isEqualToString:@"h"]
                  || [fileExtension isEqualToString:@"m"]
                  || [fileExtension isEqualToString:@"pch"]
                  || [fileExtension isEqualToString:@"swift"]
                  || [fileExtension isEqualToString:@"xib"]
                  || [fileExtension isEqualToString:@"storyboard"]
                  || [fileExtension isEqualToString:@"json"]
                  || [fileExtension isEqualToString:@"html"]
                  || [fileExtension isEqualToString:@"plist"])){
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
            NSLog(@"开始修改 %@ 文件 新类名:%@",oldCompleteClassName,newCompleteClassName);
            renameFile(oldFilePath, newFilePath);
            //遍历文件。修改文件名（.m .xib） 和 分类
            modifyClassificationFiles(oldClassName, newClassName, sourceCodeDir);
            //混淆每个类中的代码
            modifyFilesClassName(gSourceCodeDir, newClassName, oldClassName);
            //修改工程文件的引用
            modifyReferenceFile(kProjectFilePath, oldClassName, newClassName);
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

//遍历每个文件且打开内容 匹配要修改的类名
void modifyFilesClassName(NSString *sourceCodeDir, NSString *newClassName, NSString *oldClassName) {
	// 文件内容 Const > DDConst (h,m,swift,xib,storyboard)
	NSFileManager *fm = [NSFileManager defaultManager];
	NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:sourceCodeDir error:nil];
	BOOL isDirectory;
	for (NSString *filePath in files) {
        @autoreleasepool {
            //stringByAppendingPathComponent 路径拼接
            NSString *path = [sourceCodeDir stringByAppendingPathComponent:filePath];
            if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
                modifyFilesClassName(path, newClassName, oldClassName);
                continue;
            }
            
            if ((isNeedConfused(filePath.pathExtension))) {
                NSError *error = nil;
                NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
                if (error) {
                    printf("打开文件 %s 失败：%s\n", path.UTF8String, error.localizedDescription.UTF8String);
                    continue;
                }
                
                BOOL isChanged = regularReplacement(fileContent, oldClassName, newClassName);
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

void modifyReferenceFile(NSString *projectFilePath, NSString *oldName, NSString *newName){
    NSError *error = nil;
    NSMutableString *projectContent = [NSMutableString stringWithContentsOfFile:projectFilePath encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        [[NSNotificationCenter defaultCenter]  postNotificationName:kNotificationPrint object:[NSString stringWithFormat:@"打开工程文件 %s 失败：%s\n", projectFilePath.UTF8String, error.localizedDescription.UTF8String]];
        return;
    }
    regularReplacement(projectContent, oldName, newName);
    [projectContent writeToFile:projectFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
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
        if (headStrCount == 0 && endStrCount == 0) {
            if (!isChanged) {
                isChanged = YES;
            }
            [originalString replaceCharactersInRange:obj.range withString:newString];
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
    NSInteger classNameWordNum = random() % 2 + 2;
    NSString *className = [NSString string];
    for (NSInteger index = 0; index < classNameWordNum; index++) {
        NSInteger arrayIndex = random() % arr.count;
        className = [className stringByAppendingString:arr[arrayIndex]];
    }
    return className;
}

@end
