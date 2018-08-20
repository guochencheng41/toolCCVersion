//
//  ExportWhiteFunction.m
//  MJB_Project
//
//  Created by 郭晨成 on 2018/8/16.
//  Copyright © 2018年 wangzhi. All rights reserved.
//

#import "ExportWhiteFunction.h"
@interface ExportWhiteFunction()

@property (nonatomic, strong) NSMutableArray *functionNameArray;

@end

@implementation ExportWhiteFunction

- (instancetype)init{
    self = [super init];
    if (self) {
        self.functionNameArray = [NSMutableArray arrayWithCapacity:0];
    }
    return self;
}
- (void)exportWhiteFunction:(NSString *)sourceCodeDir{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:sourceCodeDir error:nil];
    BOOL isDirectory;
    for (NSString *filePath in files) {
        //stringByAppendingPathComponent 路径拼接
        NSString *path = [sourceCodeDir stringByAppendingPathComponent:filePath];
        if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
            NSLog(@"进入路径%@",path);
            [self exportWhiteFunction:path];
            continue;
        }
        
        NSString *fileExtension = filePath.pathExtension;  //扩展名
        if (![fileExtension isEqualToString:@"h"]) continue;

        NSError *error = nil;
        NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
        if (error) {
            printf("打开文件 %s 失败：%s\n", path.UTF8String, error.localizedDescription.UTF8String);
            continue;
        }
        
        [self searchFunctionName:fileContent regularExpression:@"\\- \\(void\\)"];
        [self searchFunctionName:fileContent regularExpression:@"\\- \\(BOOL\\)"];
        [self searchFunctionName:fileContent regularExpression:@"\\- \\(instancetype\\)"];
    }
    
    //路径直接写死了
    if (self.functionNameArray.count > 0) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:0];
        [dic setObject:self.functionNameArray forKey:@"FrameworkFunction"];
        [dic writeToFile:@"/Users/guochencheng/Desktop/myProject/mjbCcTool/MJB_Project/MJB_Project/frameworkWhiteList.plist" atomically:YES];
    }
}

//类文件名：旧类名替换成新的
- (void)searchFunctionName:(NSMutableString *)originalString regularExpression:(NSString *)regularExpression{
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regularExpression options:NSRegularExpressionAnchorsMatchLines|NSRegularExpressionUseUnixLineSeparators error:nil];
    NSArray<NSTextCheckingResult *> *matches = [expression matchesInString:originalString options:0 range:NSMakeRange(0, originalString.length)];
    [matches enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {

        NSInteger location = obj.range.location + obj.range.length;
        NSString *endStr = [originalString substringWithRange:NSMakeRange(location, 1)];
        while (![endStr isEqualToString:@";"] && ![endStr isEqualToString:@":"] && ![endStr isEqualToString:@" "]) {
            location ++;
            if (originalString.length <= location) {
                break;
            }
            endStr = [originalString substringWithRange:NSMakeRange(location, 1)];
        }
        
        if (originalString.length > location) {
            NSInteger functionFirstLocation = obj.range.location + obj.range.length;
            NSString *functionName = [originalString substringWithRange:NSMakeRange(functionFirstLocation, location - functionFirstLocation)];
            BOOL isExisted = NO;
            for (NSString *str in self.functionNameArray) {
                if ([functionName isEqualToString:str]) {
                    isExisted = YES;
                    break;
                }
            }
            if (!isExisted) {
                [self.functionNameArray addObject:functionName];
                NSLog(@"%@",functionName);
            }
        }
    }];
}
@end
