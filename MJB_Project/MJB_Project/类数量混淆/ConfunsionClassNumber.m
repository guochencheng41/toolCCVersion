//
//  ConfunsionClassNumber.m
//  MJB_Project
//
//  Created by 郭晨成 on 2018/9/5.
//  Copyright © 2018年 wangzhi. All rights reserved.
//

#import "ConfunsionClassNumber.h"
#import "ToolClass.h"
#import "ConfusionCode.h"
static NSString *sourceClassName = @"confunsionClassNumberSourceFile";

@interface ConfunsionClassNumber()
    
@property (nonatomic, strong) NSString *hFileSourcePath;

@property (nonatomic, strong) NSString *mFileSourcePath;

@property (nonatomic, strong) NSString *sourceCodeDir;

@property (nonatomic, strong) NSMutableArray *classFunctionArray; //公开的类方法的数组

@property (nonatomic, assign) NSInteger allClassNumber;

@property (nonatomic, strong) NSMutableArray *classModelArray; //类model数组

@property (nonatomic, assign) BOOL isClassFuntion; //是否创建类方法
@end

@implementation ConfunsionClassNumber

- (instancetype)init{
    self = [super init];
    if (self) {
        self.classModelArray = [NSMutableArray arrayWithCapacity:0];
        self.allClassNumber = arc4random() % 1000 + 500;
        self.isClassFuntion = YES;
    }
    return self;
}

- (void)confusionClassCode:(NSString *)sourceCodeDir{
    [self addRubbishClass:sourceCodeDir];
    
    NSString *fullSourceCodeDir = [sourceCodeDir stringByAppendingString:@"/"];
    [self buildNewFileCirculation:[fullSourceCodeDir stringByAppendingString:@"Controller"]];
    
    [self insertFunctionCallCirculation:sourceCodeDir];
}
- (void)addRubbishClass:(NSString *)sourceCodeDir{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:sourceCodeDir error:nil];
    BOOL isDirectory;
    BOOL isCopy = NO;
    BOOL isError = NO;
    for (NSString *filePath in files) {
        @autoreleasepool{
            NSString *className = filePath.lastPathComponent.stringByDeletingPathExtension;  //删除扩展名的文件名
            NSString *fileExtension = filePath.pathExtension;  //扩展名
            NSString *allPathPrefix = [sourceCodeDir stringByAppendingString:@"/"]; //完成路径名前缀
            NSString *chooseFileAllPath = [allPathPrefix stringByAppendingString:filePath];
            //文件夹忽略
            NSString *path = [sourceCodeDir stringByAppendingPathComponent:filePath];
            if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
                continue;
            }
            
            if ([className isEqualToString:@"AppDelegate"]){
                if ([fileExtension isEqualToString:@"h"]) {
                    self.hFileSourcePath = [allPathPrefix stringByAppendingString:[NSString stringWithFormat:@"%@.h",sourceClassName]];
                    isCopy = [fm copyItemAtPath:chooseFileAllPath toPath:self.hFileSourcePath error:nil];
                    if (!isCopy) {
                        NSLog(@"复制源.h文件失败,终止运行");
                        isError = YES;
                        break;
                    }else{
                        NSError *error = nil;
                        NSString *fileContent = [NSString stringWithContentsOfFile:self.hFileSourcePath encoding:NSUTF8StringEncoding error:&error];
                        if (error) {
                            printf("打开源.h文件失败,终止运行：%s\n", error.localizedDescription.UTF8String);
                            isError = YES;
                            break;
                        }
                        fileContent = @" ";
                        error = nil;
                        [fileContent writeToFile:self.hFileSourcePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
                        if (error) {
                            printf("保存源.h文件失败：%s\n", error.localizedDescription.UTF8String);
                            isError = YES;
                        }
                    }
                }

                if ([fileExtension isEqualToString:@"m"]) {
                    self.mFileSourcePath = [allPathPrefix stringByAppendingString:[NSString stringWithFormat:@"%@.m",sourceClassName]];
                    isCopy = [fm copyItemAtPath:chooseFileAllPath toPath:self.mFileSourcePath error:nil];
                    if (!isCopy) {
                        NSLog(@"复制源.m文件失败,终止运行");
                        isError = YES;
                        break;
                    }else{
                        NSError *error = nil;
                        NSString *fileContent = [NSString stringWithContentsOfFile:self.mFileSourcePath encoding:NSUTF8StringEncoding error:&error];
                        if (error) {
                            printf("打开源.h文件失败,终止运行：%s\n", error.localizedDescription.UTF8String);
                            isError = YES;
                            break;
                        }
                        fileContent = @" ";
                        error = nil;
                        [fileContent writeToFile:self.mFileSourcePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
                        if (error) {
                            printf("保存源.h文件失败：%s\n", error.localizedDescription.UTF8String);
                            isError = YES;
                        }
                    }
                }
            }
        }
    }
}

- (void)buildNewFileCirculation:(NSString *)sourceCodeDir{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:sourceCodeDir error:nil];
    BOOL isDirectory;
    for (NSString *filePath in files) {
        @autoreleasepool{
            NSString *path = [sourceCodeDir stringByAppendingPathComponent:filePath];
            if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
                [self buildNewFileByPath:path];
                [self buildNewFileCirculation:path];
                continue;
            }
        }
    }
}

- (void)buildNewFileByPath:(NSString *)path{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSInteger randomNumber = arc4random() % 7 + 5;
    //&& self.allClassNumber > 0
    while (randomNumber > 0) {
        @autoreleasepool{
            NSString *fileName = [ToolClass getRandomStr:0];
            NSString *buildFilePath = [[path stringByAppendingString:@"/"] stringByAppendingString:fileName];
            NSString *fFilePath = [buildFilePath stringByAppendingString:@".h"];
            NSString *mFilePath = [buildFilePath stringByAppendingString:@".m"];
            BOOL hFileCopy = [fileManager copyItemAtPath:self.hFileSourcePath toPath:fFilePath error:nil];
            BOOL mFileCopy = [fileManager copyItemAtPath:self.mFileSourcePath toPath:mFilePath error:nil];
            if (hFileCopy && mFileCopy) {
                NSError *error = nil;
                NSString *hFileContent = [NSString stringWithContentsOfFile:fFilePath encoding:NSUTF8StringEncoding error:&error];
                NSString *mFileContent = [NSString stringWithContentsOfFile:mFilePath encoding:NSUTF8StringEncoding error:&error];
                if (error) {
                    NSLog(@"打开%@文件失败：%s\n",fFilePath ,error.localizedDescription.UTF8String);
                    break;
                }
                
                mFileContent = [self buildMFileContent:fileName];
                hFileContent = [self buildHFileContent:fileName];
                
                
                error = nil;
                [mFileContent writeToFile:mFilePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
                [hFileContent writeToFile:fFilePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
                if (error) {
                    NSLog(@"保存%@文件失败 ：%s\n",fFilePath ,error.localizedDescription.UTF8String);
                }
            }else{
                NSLog(@"复制%@ 时出错",buildFilePath);
            }
           
            randomNumber --;
        }
    }
}

- (NSString *)buildMFileContent:(NSString *)className{
    NSMutableString *mFileContent = [NSMutableString stringWithFormat:@"#import \"%@.h\"\n@interface %@ ()\n@end //\n@implementation %@\n@end",className, className, className];
    ConfusionCode *confusionCode = [[ConfusionCode alloc] init];
    self.classFunctionArray = [confusionCode confunsionSpecifiedString:mFileContent className:className];
    
    ClassModel *classModel = [[ClassModel alloc] init];
    classModel.className = className;
    classModel.functionNameArray = self.classFunctionArray;
    [self.classModelArray addObject:classModel];
    return mFileContent;
}

- (NSString *)buildHFileContent:(NSString *)className{
    NSString *hFileContent = [NSString stringWithFormat:@"#import <Foundation/Foundation.h>\n@interface %@ : NSObject\n",className];
    NSString *functionOpenStr = @" ";
    for (ConfusionAttributeModel *functionModel in self.classFunctionArray) {
        @autoreleasepool{
            NSString *startCode = functionModel.variableType > MJBVariableTypeUILabel ? @"" : @"*";
            NSString *classType = self.isClassFuntion ? @"+" : @"-";
            NSString *functionOpen = [NSString stringWithFormat:@"%@ (%@ %@)%@;\n",classType,[ToolClass getTypeString:functionModel.variableType], startCode, functionModel.name];
            functionOpenStr = [functionOpenStr stringByAppendingString:functionOpen];
        }
    }
    hFileContent = [hFileContent stringByAppendingString:functionOpenStr];
    hFileContent = [hFileContent stringByAppendingString:@"@end"];
    return hFileContent;
}

#pragma mark - 源码中插入函数调用,混淆代码
- (void)insertFunctionCallCirculation:(NSString *)sourceCodeDir{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:sourceCodeDir error:nil];
    BOOL isDirectory;
    for (NSString *filePath in files) {
        @autoreleasepool{
            NSString *fileExtension = filePath.pathExtension;  //扩展名
            NSString *className = filePath.lastPathComponent.stringByDeletingPathExtension;  //删除扩展名的文件名
            //framework 忽略
            if ([className isEqualToString:@"framework"] ||
                [fileExtension isEqualToString:@"framework"] ||
                [className isEqualToString:@"Library"] ||
                [className isEqualToString:@"Hybrid"] ||
                [className isEqualToString:@"YYModel"]) {
                NSLog(@"%@ 插入新增类的类函数 忽略",filePath);
                continue;
            }
            
            NSString *path = [sourceCodeDir stringByAppendingPathComponent:filePath];
            if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
                NSLog(@"插入新增类的类函数 进入路径%@",path);
                [self insertFunctionCallCirculation:path];
                continue;
            }
            
            if (![fileExtension isEqualToString:@"m"]){
                continue;
            }

            BOOL isBreak = NO;
            for (NSString *str in self.modelNameArray) {
                if ([className isEqualToString:str]) {
                    isBreak = YES;
                    break;
                }
            }
            if (isBreak) {
                break;
            }
            
            NSError *error = nil;
            NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
            if (error) {
                printf("打开文件 %s 失败：%s\n", path.UTF8String, error.localizedDescription.UTF8String);
                continue;
            }
            
            NSLog(@"插入新增类的类函数 >>>打开%@",path);
            [self insertFunctionCall:fileContent];
            
            error = nil;
            [fileContent writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
            if (error) {
                printf("保存文件 %s 失败：%s\n", path.UTF8String, error.localizedDescription.UTF8String);
            }
        }
    }
}


- (void)insertFunctionCall:(NSMutableString *)originalString{
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:@"];" options:NSRegularExpressionAnchorsMatchLines|NSRegularExpressionUseUnixLineSeparators error:nil];
    NSArray<NSTextCheckingResult *> *matches = [expression matchesInString:originalString options:0 range:NSMakeRange(0, originalString.length)];
    NSMutableArray *classNameArray = [NSMutableArray arrayWithCapacity:0];
    [matches enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (arc4random() % matches.count < 3) {//每个类插入大约3次
            if ([self determineIsExampleFunction:originalString targetRange:obj.range]) {
                NSMutableArray *functionArray = self.classModelArray;
                NSInteger index = arc4random() % functionArray.count;
                ClassModel *classModel = functionArray[index];
                
                index = arc4random() % classModel.functionNameArray.count;
                ConfusionAttributeModel *functionModel = classModel.functionNameArray[index];
                NSString *functionCall = [NSString stringWithFormat:@"\n[%@ %@];",classModel.className ,functionModel.name];
                [originalString replaceCharactersInRange:obj.range withString:[NSString stringWithFormat:@"];%@",functionCall]];
                
                [classNameArray addObject:classModel.className];
            }
        }
    }];
    for (NSString *className in classNameArray) {
        @autoreleasepool{
            NSString *importCode = [NSString stringWithFormat:@"#import \"%@.h\"\n",className];
            [originalString insertString:importCode atIndex:0];
        }
    }
}

//判断是否在实例方法内部 、 是否是for循环的条件判断、 是否是注释
- (BOOL)determineIsExampleFunction:(NSMutableString *)originalString targetRange:(NSRange)targetRange{
    BOOL isExampleFunction = NO;  //是否实例方法
    BOOL isClassFunction = NO;    //是否类方法
    BOOL isPositioningNewLine = NO;  //是否新的一行
    BOOL isForCirculation = NO;   //是否是for循环的条件判断
    BOOL isAnnotation = NO;       //判断是否是注释
    BOOL isStaticLineFunction = NO;   //判断是否是 内联函数
    BOOL isReturnCode = NO;     //判断是否是 return xxxxx; （这种没必要加）
    NSInteger rangeLocation = targetRange.location - 1;
    NSString *targetStr;
    while (!isExampleFunction && !isClassFunction) {
        targetStr = [originalString substringWithRange:NSMakeRange(rangeLocation, 1)];
        //代码所在行
        if ([targetStr isEqualToString:@"\n"] && !isPositioningNewLine) {
            NSString *allStr = [originalString substringWithRange:NSMakeRange(rangeLocation, targetRange.location - rangeLocation + 1)];
            //判断是否是for循环
            isPositioningNewLine = YES;
            if ([allStr containsString:@"for ("] || [allStr containsString:@"for("]) {
                isForCirculation = YES;
                break;
            }
            
            //判断是否是注释
            if ([allStr containsString:@"//"]) {
                isAnnotation = YES;
                break;
            }
            
            //判断是否是 return xxxxx; （这种没必要加）
            if ([allStr containsString:@"return"]) {
                isReturnCode = YES;
                break;
            }
        }
        
        //这样写是为了效率高
        if ([targetStr isEqualToString:@"\n"]) {
            NSString *allStr = [originalString substringWithRange:NSMakeRange(rangeLocation, targetRange.location - rangeLocation + 1)];
            if ([allStr containsString:@"static inline"]) {
                isStaticLineFunction = YES;
                break;
            }
        }
        
        if ([targetStr isEqualToString:@"-"]) {
            NSString *targetStrEnd1 = [originalString substringWithRange:NSMakeRange(rangeLocation + 1, 1)];
            NSString *targetStrEnd2 = [originalString substringWithRange:NSMakeRange(rangeLocation + 2, 1)];
            if ([targetStrEnd1 isEqualToString:@"("] || [targetStrEnd2 isEqualToString:@"("]) {
                NSString *allStr = [originalString substringWithRange:NSMakeRange(rangeLocation, targetRange.location - rangeLocation + 1)];
                isExampleFunction = YES;
                if ([allStr containsString:@"for ("] || [allStr containsString:@"for("]) {
                    isExampleFunction = NO;
                }
                break;
            }
        }
        
        if ([targetStr isEqualToString:@"+"]) {
            NSString *targetStrEnd1 = [originalString substringWithRange:NSMakeRange(rangeLocation + 1, 1)];
            NSString *targetStrEnd2 = [originalString substringWithRange:NSMakeRange(rangeLocation + 2, 1)];
            if ([targetStrEnd1 isEqualToString:@"("] || [targetStrEnd2 isEqualToString:@"("]) {
                isClassFunction = YES;
                break;
            }
        }
        
        rangeLocation --;
        if (rangeLocation < 0) break;
    }
    if (isForCirculation) return NO;
    if (isAnnotation) return NO;
    if (isStaticLineFunction) return NO;
    if (isReturnCode) return NO;
    if (isClassFunction) return NO;
    return isExampleFunction;
}

//调用函数的代码
- (NSString *)buildCallFunction{
    NSMutableArray *functionArray = self.classModelArray;
    NSInteger index = arc4random() % functionArray.count;
    ClassModel *classModel = functionArray[index];
    
    index = arc4random() % classModel.functionNameArray.count;
    ConfusionAttributeModel *functionModel = classModel.functionNameArray[index];
    NSString *functionCall = [NSString stringWithFormat:@"\n[%@ %@];",classModel.className ,functionModel.name];
    return functionCall;
}
    
@end

@implementation ClassModel

@end
