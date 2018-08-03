//
//  MJB_Utils.m
//  MJB_Project
//
//  Created by wangzhi on 2018/7/29.
//  Copyright © 2018年 wangzhi. All rights reserved.
//

#import "MJB_Utils.h"
extern NSString *gSourceCodeDir = @"";  //项目根路径
extern NSString *kNotificationPrint = @"notificationPrint";
@implementation MJB_Utils

//白名单最后加
void executeModifyClassNamePrefix(NSString *oldClassNamePrefix,
										 NSString *newClassNamePrefix,
										 NSArray<NSString *> *ignoreDirNames,
										 NSString *projectFilePath){

	if (gSourceCodeDir.length == 0){
		[[NSNotificationCenter defaultCenter]  postNotificationName:kNotificationPrint object:@"请赋值项目根路径..."];
		return;
	}
	
	if (oldClassNamePrefix && newClassNamePrefix) {
		[[NSNotificationCenter defaultCenter]  postNotificationName:kNotificationPrint object:@"开始修改类名前缀..."];
		@autoreleasepool {
            //修改类文件名
            newModifyFilesClassName(gSourceCodeDir, oldClassNamePrefix, newClassNamePrefix, ignoreDirNames);
            
            //打开文件 修改所有mm_
            modifyFilesClassName(gSourceCodeDir, newClassNamePrefix);
            
			//修改工程文件的引用
			NSError *error = nil;
			NSMutableString *projectContent = [NSMutableString stringWithContentsOfFile:projectFilePath encoding:NSUTF8StringEncoding error:&error];
			if (error) {
				[[NSNotificationCenter defaultCenter]  postNotificationName:kNotificationPrint object:[NSString stringWithFormat:@"打开工程文件 %s 失败：%s\n", projectFilePath.UTF8String, error.localizedDescription.UTF8String]];
				return;
			}
            regularReplacement(projectContent, @"^MM_$", newClassNamePrefix);
			[projectContent writeToFile:projectFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
		}
		[[NSNotificationCenter defaultCenter]  postNotificationName:kNotificationPrint object:@"修改类名前缀完成..."];
	}
}


void newModifyFilesClassName(NSString *sourceCodeDir, NSString *oldClassNamePrefix, NSString *newClassNamePrefix, NSArray<NSString *> *ignoreDirNames){
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:sourceCodeDir error:nil];
    BOOL isDirectory;
    for (NSString *filePath in files) {
        //stringByAppendingPathComponent 路径拼接
        NSString *path = [sourceCodeDir stringByAppendingPathComponent:filePath];
        if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
            newModifyFilesClassName(path, oldClassNamePrefix, newClassNamePrefix, ignoreDirNames);
            continue;
        }
        
        NSString *fileName = filePath.lastPathComponent.stringByDeletingPathExtension;  //1、最后一个组成部分。2、删除扩展名
        NSString *fileExtension = filePath.pathExtension;  //扩展名
        if ([fileName hasPrefix:@"MM_"] || [fileName hasPrefix:@"mm_"]) {
            NSString *oldFilePath = [[sourceCodeDir stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:fileExtension];
            NSMutableString *newClassName = [NSMutableString stringWithString:fileName];
            [newClassName replaceCharactersInRange:NSMakeRange(0, 3) withString:newClassNamePrefix];
            NSString *newFilePath = [[sourceCodeDir stringByAppendingPathComponent:newClassName] stringByAppendingPathExtension:fileExtension];
            renameFile(oldFilePath, newFilePath);
        }
    }
}

#pragma mark - 修改类名前缀
//遍历每个文件且打开内容 匹配要修改的类名
void modifyFilesClassName(NSString *sourceCodeDir, NSString *newClassNamePrefix) {
	// 文件内容 Const > DDConst (h,m,swift,xib,storyboard)
	NSFileManager *fm = [NSFileManager defaultManager];
	NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:sourceCodeDir error:nil];
	BOOL isDirectory;
	for (NSString *filePath in files) {
        //stringByAppendingPathComponent 路径拼接
		NSString *path = [sourceCodeDir stringByAppendingPathComponent:filePath];
		if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
			modifyFilesClassName(path, newClassNamePrefix);
			continue;
		}
        
        NSString *fileName = filePath.lastPathComponent;
		if ([fileName hasSuffix:@".h"] || [fileName hasSuffix:@".m"] || [fileName hasSuffix:@".pch"] || [fileName hasSuffix:@".swift"] || [fileName hasSuffix:@".xib"] || [fileName hasSuffix:@".storyboard"]) {
            NSError *error = nil;
            NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
            if (error) {
                printf("打开文件 %s 失败：%s\n", path.UTF8String, error.localizedDescription.UTF8String);
                continue;
            }
            
            BOOL isChanged = regularReplacement(fileContent, @"MM_", newClassNamePrefix);
            if (!isChanged) continue;
            error = nil;
            [fileContent writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
            if (error) {
                printf("保存文件 %s 失败：%s\n", path.UTF8String, error.localizedDescription.UTF8String);
            }
        }
    }
}


//将旧类名替换成新的
BOOL regularReplacement(NSMutableString *originalString, NSString *regularExpression, NSString *newString) {
	__block BOOL isChanged = NO;
	NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regularExpression options:NSRegularExpressionAnchorsMatchLines|NSRegularExpressionUseUnixLineSeparators|NSRegularExpressionCaseInsensitive error:nil];
	NSArray<NSTextCheckingResult *> *matches = [expression matchesInString:originalString options:0 range:NSMakeRange(0, originalString.length)];
	[matches enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if (!isChanged) {
			isChanged = YES;
		}
        [originalString replaceCharactersInRange:obj.range withString:newString];
	}];
	return isChanged;
}

//改文件名称
void renameFile(NSString *oldPath, NSString *newPath) {
	NSError *error;
	[[NSFileManager defaultManager] moveItemAtPath:oldPath toPath:newPath error:&error];
	if (error) {
		printf("修改文件名称失败。\n  oldPath=%s\n  newPath=%s\n  ERROR:%s\n", oldPath.UTF8String, newPath.UTF8String, error.localizedDescription.UTF8String);
	}
}


@end
