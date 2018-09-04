//
//  ConfusionCode.m
//  MJB_Project
//
//  Created by 郭晨成 on 2018/9/1.
//  Copyright © 2018年 wangzhi. All rights reserved.
//

#import "ConfusionCode.h"

@interface ConfusionCode()
@property (nonatomic, strong) NSMutableArray *attributeArray;

@property (nonatomic, strong) NSMutableArray *sourceFunctionArray;

@property (nonatomic, strong) NSMutableArray *callFunctionArray;

@property (nonatomic, strong) NSMutableArray *insetFunctionTextArray;

@property (nonatomic, assign) NSInteger numberTypeNumber;


@property (nonatomic, assign) NSInteger stringTypeNumberMax;
@property (nonatomic, strong) NSMutableArray *stringTypeArray;

@property (nonatomic, assign) NSInteger arrayTypeNumberMax;
@property (nonatomic, strong) NSMutableArray *arrayTypeArray;

@property (nonatomic, assign) NSInteger dicTypeNumberMax;
@property (nonatomic, strong) NSMutableArray *dicTypeArray;

@property (nonatomic, assign) NSInteger interTypeNumberMax;
@property (nonatomic, strong) NSMutableArray *interTypeArray;

@property (nonatomic, assign) NSInteger labelTypeNumberMax;
@property (nonatomic, strong) NSMutableArray *labelTypeArray;

@property (nonatomic, assign) BOOL isClassification;

@property (nonatomic, strong) NSArray *whiteClassList;

@end

@implementation ConfusionCode

- (instancetype)init{
    self = [super init];
    if (self) {
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"ConfusionCodeWhiteList" ofType:@"plist"];
        self.whiteClassList = [NSArray arrayWithContentsOfFile:plistPath];
    }
    return self;
}

- (void)confusionClassCode:(NSString *)sourceCodeDir{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:sourceCodeDir error:nil];
    BOOL isDirectory;
    for (NSString *filePath in files) {
        @autoreleasepool{
            NSString *className = filePath.lastPathComponent.stringByDeletingPathExtension;  //删除扩展名的文件名
            NSString *fileCompleteClassName = filePath.lastPathComponent; //完整文件名//完整路径名
            NSString *fileExtension = filePath.pathExtension;  //扩展名
            
            //framework 忽略
            if ([className isEqualToString:@"framework"] ||
                [fileExtension isEqualToString:@"framework"] ||
                [className isEqualToString:@"Library"] ||
                [className isEqualToString:@"Hybrid"]) {
                NSLog(@"%@ 代码块混淆 忽略",filePath);
                continue;
            }
            
            //文件夹循环进去
            NSString *path = [sourceCodeDir stringByAppendingPathComponent:filePath];
            if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
                NSLog(@"进入路径%@",path);
                [self confusionClassCode:path];
                continue;
            }
            
            //不是 m 文件忽略
            if (![fileExtension isEqualToString:@"m"]) continue;
            //白名单类忽略
            BOOL isWhiteListClass = NO;
            for (NSString *str in self.whiteClassList) {
                if ([str isEqualToString:className]) {
                    isWhiteListClass = YES;
                    break;
                }
            }
            if (isWhiteListClass) continue;
            NSLog(@"代码块混淆 打开%@",fileCompleteClassName);
            
            
            NSError *error = nil;
            NSString *fileContent = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
            if (error) {
                printf("打开文件 %s 失败：%s\n", path.UTF8String, error.localizedDescription.UTF8String);
                continue;
            }
            self.isClassification = [className containsString:@"+"];
            //将源代码根据类分割 成数组
            NSArray *separatedStrArray = [fileContent componentsSeparatedByString:@"@end"];
            NSMutableArray *newSeparatedStrArray = [NSMutableArray arrayWithCapacity:0];
            for (NSString *str in separatedStrArray) {
                @autoreleasepool{
                    NSString *removeLineFeedStr = [NSString stringWithString:str];
                    removeLineFeedStr = [str stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                    if (!strIsEmpty(removeLineFeedStr) && removeLineFeedStr.length != 1) {
                        NSMutableString *newStr = [NSMutableString stringWithString:[str stringByAppendingString:@"@end"]];
                        [newSeparatedStrArray addObject:newStr];
                    }
                }
            }
            
            
            for (NSInteger index = 0; index < newSeparatedStrArray.count; index++) {
                @autoreleasepool{
                    NSMutableString *partStr = newSeparatedStrArray[index];
                    if ([partStr containsString:@"@implementation"]) {
                        //对类的实现进行混淆
                        [self insertConfusionCode:partStr];
                        
                        //将属性加上前缀
                        for (ConfusionAttributeModel *model in self.attributeArray) {
                            if (!model.isStaticVariable) {
                                [self replaceCodeInSourceCode:partStr regularExpression:model.name newString:[@"self." stringByAppendingString:model.name]];
                            }
                        }
                        //将混淆产生的属性和静态变量注入到interface中
                        if (index == 0) {
                            //新建interface 插入
                            NSMutableString *interfaceCode = [self buildInterfaceCodeWithClassName:[ToolClass getClassNameByImplementation:partStr]];
                            [self insertPropertyAndStaticAttribute:interfaceCode attributeArray:self.attributeArray];
                            //partStr
                            [self replaceCodeInSourceCode:partStr regularExpression:@"@implementation" newString:[interfaceCode stringByAppendingString:@"\n@implementation"]];
                            break;
                        }
                        //前一部分字符串
                        NSMutableString *headPartStr = newSeparatedStrArray[index - 1];
                        NSMutableString *newHeadPartStr = [NSMutableString stringWithString:headPartStr];
                        newSeparatedStrArray[index - 1] = newHeadPartStr;
                        if ([newHeadPartStr containsString:@"@interface"] && ![newHeadPartStr containsString:@"@implementation"]) {
                            //前一部分插入
                            [self insertPropertyAndStaticAttribute:newHeadPartStr attributeArray:self.attributeArray];
                        }else{
                            //新建interface 插入
                            NSMutableString *interfaceCode = [self buildInterfaceCodeWithClassName:[ToolClass getClassNameByImplementation:partStr]];
                            [self insertPropertyAndStaticAttribute:interfaceCode attributeArray:self.attributeArray];
                            newSeparatedStrArray[index] = [interfaceCode stringByAppendingString:partStr];
                        }
                        
                    }
                }
            }
            
            fileContent = [NSString string];
            for (NSMutableString *partStr in newSeparatedStrArray) {
                fileContent = [fileContent stringByAppendingString:partStr];
            }

            error = nil;
            [fileContent writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
            if (error) {
                printf("保存文件 %s 失败：%s\n", path.UTF8String, error.localizedDescription.UTF8String);
            }
        }
    }
}

- (NSString *)insertConfusionCode:(NSMutableString *)originalString{
    [self clearData];
    [self buildFunctionCodeArray];
    //插入函数调用
    [self insertFunctionCall:originalString];
    [self insertIfCode:originalString];
    [self insetFunctionCodeFromArray:originalString];
    
    return originalString;
}

- (void)clearData{
    _attributeArray = nil;
    _sourceFunctionArray = [NSMutableArray arrayWithCapacity:0];
    _callFunctionArray = [NSMutableArray arrayWithCapacity:0];
    _insetFunctionTextArray = [NSMutableArray arrayWithCapacity:0];
    
    _labelTypeNumberMax = arc4random() % 6 + 2;
    self.labelTypeArray = [NSMutableArray arrayWithCapacity:0];
    _arrayTypeNumberMax = arc4random() % 6 + 2;
    self.arrayTypeArray = [NSMutableArray arrayWithCapacity:0];
    _stringTypeNumberMax = arc4random() % 6 + 2;
    self.stringTypeArray = [NSMutableArray arrayWithCapacity:0];
    _interTypeNumberMax = arc4random() % 8 + 4;
    self.interTypeArray = [NSMutableArray arrayWithCapacity:0];
    _dicTypeNumberMax = arc4random() % 6 + 2;
    self.dicTypeArray = [NSMutableArray arrayWithCapacity:0];
}

#pragma mark - 插入 混淆需要的静态变量和属性
- (NSMutableString *)buildInterfaceCodeWithClassName:(NSString *)className{
    NSMutableString *interfaceCode = [NSMutableString stringWithFormat:@"@interface %@ () @end",className];
    return interfaceCode;
}

- (void)insertPropertyAndStaticAttribute:(NSMutableString *)originalString
                          attributeArray:(NSMutableArray *)attributeArray{
    for (ConfusionAttributeModel *model in attributeArray) {
        @autoreleasepool{
            NSString *staticExpression = model.isStaticVariable ? @"@interface" : @"@end";
            NSString *staticStr = [self buildAttributeCodeByModel:model];
            NSString *newStr = [NSString stringWithFormat:@"\n%@%@",staticStr,staticExpression];
            [self replaceCodeInSourceCode:originalString regularExpression:staticExpression newString:newStr];
        }
    }
}

- (NSString *)buildAttributeCodeByModel:(ConfusionAttributeModel *)model{
    NSString *typeStr = [ToolClass getTypeString:model.variableType];
    if (model.variableType != MJBVariableTypeNSInteger) {
        typeStr = [typeStr stringByAppendingString:@"*"];
    }
    
    if (model.isStaticVariable) {
        NSMutableString *staticStr = [NSMutableString stringWithFormat:@"static %@ %@;", typeStr, model.name];
        //字符串直接初始化随机值
        NSString *strInit = [NSString stringWithFormat:@"= @\"%@\";",[ToolClass getRandomStr:0]];
        if (model.variableType == MJBVariableTypeNSString) {
            [staticStr replaceCharactersInRange:NSMakeRange(staticStr.length - 1, 1) withString:strInit];
        }
        return staticStr;
    }
    
    NSString *strongAssignStr = model.variableType == MJBVariableTypeNSInteger ? @"assign" : @"strong";
    NSString *propertyStr = [NSString stringWithFormat:@"@property (nonatomic, %@) %@ %@;",strongAssignStr ,typeStr ,model.name];
    return propertyStr;
}

#pragma mark - 混淆源码中if语句（）
- (void)insertIfCode:(NSMutableString *)originalString{
    [self replaceIfCodeInSourceCode:originalString regularExpression:@"if \\("];
    [self replaceIfCodeInSourceCode:originalString regularExpression:@"if\\("];
}

- (void)replaceIfCodeInSourceCode:(NSMutableString *)originalString
                regularExpression:(NSString *)regularExpression{
    
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regularExpression options:NSRegularExpressionDotMatchesLineSeparators error:nil];
    NSArray<NSTextCheckingResult *> *matches = [expression matchesInString:originalString options:0 range:NSMakeRange(0, originalString.length)];
    [matches enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([self determineIsExampleFunction:originalString targetRange:obj.range]) {
            NSString *ifConfusionCode = [self buildRandomIfCode:YES isRandomFalse:YES isBuildFunction:YES];
            [originalString replaceCharactersInRange:obj.range withString:[NSString stringWithFormat:@"%@%@",ifConfusionCode,@"if("]];
        }
    }];
}

#pragma mark - 源码中插入函数调用,混淆代码
- (void)insertFunctionCall:(NSMutableString *)originalString{
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:@"];" options:NSRegularExpressionAnchorsMatchLines|NSRegularExpressionUseUnixLineSeparators error:nil];
    NSArray<NSTextCheckingResult *> *matches = [expression matchesInString:originalString options:0 range:NSMakeRange(0, originalString.length)];
    [matches enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([self determineIsExampleFunction:originalString targetRange:obj.range]) {
            NSString *callFunctionCode = [self buildCallFunction:NO];
            [originalString replaceCharactersInRange:obj.range withString:[NSString stringWithFormat:@"];%@",callFunctionCode]];
        }
    }];
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
    while (!isClassFunction && !isExampleFunction) {
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
                isExampleFunction = YES;
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

#pragma mark - 源码中插入函数体
- (void)buildFunctionCodeArray{
    NSInteger sourcefunctionNumber = arc4random() % 5 + 10;
    while (sourcefunctionNumber > 0) {
        [self.insetFunctionTextArray addObject:[self buildSourceFunctionCode]];
        sourcefunctionNumber --;
    }
    
    NSInteger callFunctionNumber = arc4random() % 5 + 10;
    while (callFunctionNumber > 0) {
        [self.insetFunctionTextArray addObject:[self buildCallFunctionCode]];
        callFunctionNumber --;
    }
}

- (void)insetFunctionCodeFromArray:(NSMutableString *)originalString{
    for (NSString *functionCode in self.insetFunctionTextArray) {
        [self replaceCodeInSourceCode:originalString regularExpression:@"@end" newString:[functionCode stringByAppendingString:@"@end"]];
    }
}
#pragma mark - 基本功能函数
//调用函数的代码
- (NSString *)buildCallFunction:(BOOL)isSourceFunction{
    NSMutableArray *functionArray = isSourceFunction ? self.sourceFunctionArray : self.callFunctionArray;
    NSInteger index = arc4random() % functionArray.count;
    ConfusionAttributeModel *functionModel = functionArray[index];
    
    if (functionModel.variableType != MJBVariableTypeVoid) {
        ConfusionAttributeModel *attributeModel = [self getRandomModelByType:functionModel.variableType];
        NSString *functionCall = [NSString stringWithFormat:@"\n %@ = [self %@];",attributeModel.name ,functionModel.name];
        return functionCall;
    }
    NSString *functionCall = [NSString stringWithFormat:@"\n[self %@];",functionModel.name];
    return functionCall;
}

//call函数构建（函数体本身）
- (NSString *)buildCallFunctionCode{
    NSString *functionName = [ToolClass getRandomStr:0];
    MJBVariableTypes functionReturnType = arc4random() % variableTypesAllNumber;
    NSString *typeString = [ToolClass getTypeString:functionReturnType];
    NSString *asteriskCode = functionReturnType == MJBVariableTypeNSInteger ? @"" : @"*";
    //随机生成1 - 5条调用
    NSString *callFunctionGather = @"";
    NSInteger callFuntionNumber = arc4random() % 5 + 1;
    while (callFuntionNumber > 0) {
        callFunctionGather = [callFunctionGather stringByAppendingString:[self buildCallFunction:YES]];
        callFuntionNumber --;
    }
    
    NSString *functionCode;
    if (functionReturnType == MJBVariableTypeVoid) {
        functionCode = [NSString stringWithFormat:@"- (%@)%@{\n%@\n}\n",typeString, functionName, callFunctionGather];
    }else{
        functionCode = [NSString stringWithFormat:@"- (%@ %@)%@{\n%@ \n%@\n}\n",typeString, asteriskCode, functionName, callFunctionGather, [self buildReturnCode:functionReturnType]];
    }
    
    ConfusionAttributeModel *functionModel = [[ConfusionAttributeModel alloc] init];
    functionModel.name = functionName;
    functionModel.variableType = functionReturnType;
    [self.callFunctionArray addObject:functionModel];
    return functionCode;
}

//源函数的构建 （函数体本身）
- (NSString *)buildSourceFunctionCode{
    NSString *functionName = [ToolClass getRandomStr:0];
    MJBVariableTypes functionReturnType = arc4random() % variableTypesAllNumber;
    NSString *typeString = [ToolClass getTypeString:functionReturnType];
    NSString *confunsionCode = [self buildRandomIfCode:NO isRandomFalse:NO isBuildFunction:NO];
    NSString *asteriskCode = functionReturnType == MJBVariableTypeNSInteger ? @"" : @"*";
    NSString *functionCode;
    if (functionReturnType == MJBVariableTypeVoid) {
        functionCode = [NSString stringWithFormat:@"- (%@)%@{\n%@ \n}\n", typeString, functionName ,confunsionCode];
    }else{
        functionCode = [NSString stringWithFormat:@"- (%@ %@)%@{\n%@ \n%@\n}\n",typeString ,asteriskCode, functionName ,confunsionCode ,[self buildReturnCode:functionReturnType]];
    }
    
    ConfusionAttributeModel *functionModel = [[ConfusionAttributeModel alloc] init];
    functionModel.name = functionName;
    functionModel.variableType = functionReturnType;
    [self.sourceFunctionArray addObject:functionModel];
    return functionCode;
}

//函数返回值的构建
- (NSString *)buildReturnCode:(MJBVariableTypes)type{
    NSString *returnCode;
    switch (type) {
        case MJBVariableTypeNSString:
            returnCode = [NSString stringWithFormat:@"\n return @\"%@\";",[ToolClass getRandomStr:0]];
            break;
        case MJBVariableTypeNSArray:
            returnCode = [NSString stringWithFormat:@"\n return [NSArray arrayWithObjects:@\"%@\",@\"%@\",@\"%@\", nil];", [ToolClass getRandomStr:0], [ToolClass getRandomStr:0], [ToolClass getRandomStr:0]];
            break;
        case MJBVariableTypeNSDictionary:
            returnCode = [NSString stringWithFormat:@"\n return [NSDictionary dictionaryWithObjectsAndKeys:@\"%@\",@\"%@\",nil];", [ToolClass getRandomStr:0], [ToolClass getRandomStr:0]];
            break;
        case MJBVariableTypeUILabel:
            returnCode = @"\n return [[UILabel alloc] init];";
            break;
        case MJBVariableTypeNSInteger:
            returnCode = [NSString stringWithFormat:@"\n return %d;", arc4random() % 700];
            break;
        default:
            break;
    }
    return returnCode;
}

//多重if嵌套的代码
//if 代码块混淆
//isHeadIfCode : 是否是加在原有if 上的 if code
//randomFlase :  是否必然不会进入的if code
//isBuildFuntion : if code 内部是否调用混淆函数
- (NSString *)buildRandomIfCode:(BOOL)isHeadIfCode isRandomFalse:(BOOL)isRandomFalse isBuildFunction:(BOOL)isBuildFunction{
    NSString *randomIfCode = [self buildRubbishIfCode:isBuildFunction isRandomFalse:isRandomFalse];
    NSInteger number = arc4random() % 10;
    while (number > 0) {
        randomIfCode = [randomIfCode stringByAppendingString:@"else "];
        randomIfCode = [randomIfCode stringByAppendingString:[self buildRubbishIfCode:isBuildFunction isRandomFalse:isRandomFalse]];
        number --;
    }
    return isHeadIfCode ? [randomIfCode stringByAppendingString:@"else "] : randomIfCode;
}

//单个IF代码块
- (NSString *)buildRubbishIfCode:(BOOL)isBuildFunction isRandomFalse:(BOOL)isRandomFalse{
    NSString *rubbishCode = [NSString string];
    NSInteger index = arc4random() % 8;
    while (index > 0) {
        if (isBuildFunction) {
            rubbishCode = [rubbishCode stringByAppendingString:arc4random() % 2 ? [self buildCallFunction:NO]: [self buildNumberOperationCode]];
        }else{
            rubbishCode = [rubbishCode stringByAppendingString:[self buildNumberOperationCode]];
        }
        index --;
    }
    
    NSString *contrastCode = [self buildContrastCode:isRandomFalse];
    NSString *rubbishIfCode = [NSString stringWithFormat:@"if (%@) {\n%@\n}",contrastCode,rubbishCode];
    return rubbishIfCode;
}

//条件判断的代码
- (NSString *)buildContrastCode:(BOOL)isRandomFalse{
    ConfusionAttributeModel *model = [self getRandomModelByType:[ToolClass getRandomType]];
    NSString *contrastCode;
    switch (model.variableType) {
        case MJBVariableTypeNSString:{
            if (isRandomFalse) {
                if (arc4random() % 2) {
                    contrastCode = [NSString stringWithFormat:@"[%@ isKindOfClass:[%@ class]]", model.name, [self getRandomTypeString:MJBVariableTypeNSString haveRuleOut:YES]];
                }else{
                    contrastCode = [NSString stringWithFormat:@"%@.length > %d", model.name, (arc4random() % 50 + 80)];
                }
                break;
            }
            NSInteger randomNumber = arc4random() % 3;
            switch (randomNumber) {
                case 0:{
                    NSString *randomStr = [ToolClass getRandomStr:0];
                    if (arc4random() % 2) {
                        randomStr = model.name;
                    }
                    contrastCode = [NSString stringWithFormat:@"[%@ isEqualToString:@\"%@\"]", model.name, randomStr];
                    break;
                }
                case 1:
                    contrastCode = [NSString stringWithFormat:@"[%@ isKindOfClass:[%@ class]]", model.name, [self getRandomTypeString:0 haveRuleOut:NO]];
                    break;
                case 2:
                    contrastCode = [NSString stringWithFormat:@"%@.length %@ %d", model.name, [self getRandomDecide], arc4random() % 20];
                    break;
                default:
                    break;
            }
        }
            break;
        case MJBVariableTypeNSArray:{
            if (isRandomFalse) {
                if (arc4random() % 2) {
                    contrastCode = [NSString stringWithFormat:@"[%@ isKindOfClass:[%@ class]]", model.name, [self getRandomTypeString:MJBVariableTypeNSArray haveRuleOut:YES]];
                }else{
                    contrastCode = [NSString stringWithFormat:@"%@.count > %d", model.name, arc4random() % 100 + 5];
                }
                break;
            }
            
            NSInteger randomNumber = arc4random() % 2;
            switch (randomNumber) {
                case 0:{
                    if (arc4random() % 3) {
                        contrastCode = [NSString stringWithFormat:@"[%@ isKindOfClass:[%@ class]]", model.name, @"NSArray"];
                    }else{
                        contrastCode = [NSString stringWithFormat:@"[%@ isKindOfClass:[%@ class]]", model.name, [self getRandomTypeString:0 haveRuleOut:NO]];
                    }
                    break;
                }
                case 1:
                    contrastCode = [NSString stringWithFormat:@"%@.count %@ %d", model.name, [self getRandomDecide], arc4random() % 20];
                    break;
                default:
                    break;
            }
        }
            break;
        case MJBVariableTypeNSDictionary:{
            if (isRandomFalse) {
                switch (arc4random() % 3) {
                    case 0:
                        contrastCode = [NSString stringWithFormat:@"[%@ isKindOfClass:[%@ class]]", model.name, [self getRandomTypeString:MJBVariableTypeNSDictionary haveRuleOut:YES]];
                        break;
                    case 1:
                        contrastCode = [NSString stringWithFormat:@"%@.allKeys.count > %d", model.name, arc4random() % 100 + 5];
                        break;
                    case 2:
                        contrastCode = [NSString stringWithFormat:@"%@.allValues.count > %d", model.name, arc4random() % 100 + 5];
                        break;
                    default:
                        break;
                }
                break;
            }
            
            NSInteger randomNumber = arc4random() % 3;
            switch (randomNumber) {
                case 0:{
                    if (arc4random() % 3) {
                        contrastCode = [NSString stringWithFormat:@"[%@ isKindOfClass:[%@ class]]", model.name, @"NSDictionary"];
                    }else{
                        contrastCode = [NSString stringWithFormat:@"[%@ isKindOfClass:[%@ class]]", model.name, [self getRandomTypeString:0 haveRuleOut:NO]];
                    }
                    break;
                }
                case 1:
                    contrastCode = [NSString stringWithFormat:@"%@.allKeys.count %@ %d", model.name, [self getRandomDecide], arc4random() % 50];
                    break;
                case 2:
                    contrastCode = [NSString stringWithFormat:@"%@.allValues.count %@ %d", model.name, [self getRandomDecide], arc4random() % 50];
                    break;
                default:
                    break;
            }
        }
            break;
        case MJBVariableTypeUILabel:{
            if (isRandomFalse) {
                switch (arc4random() % 3) {
                    case 0:
                        contrastCode = [NSString stringWithFormat:@"[%@ isKindOfClass:[%@ class]]", model.name, [self getRandomTypeString:MJBVariableTypeUILabel haveRuleOut:YES]];
                        break;
                    case 1:{
                        contrastCode = [NSString stringWithFormat:@"[%@.text isEqualToString:@\"%@\"]", model.name, [ToolClass getRandomStr:0]];
                    }
                        break;
                    case 2:
                        contrastCode = [NSString stringWithFormat:@"%@.tag > %d", model.name, arc4random() % 100 + 5];
                        break;
                    default:
                        break;
                }
                break;
            }
            
            NSInteger randomNumber = arc4random() % 2;
            if (randomNumber) {
                contrastCode = [NSString stringWithFormat:@"[%@.text isEqualToString:@\"%@\"]", model.name, @""];
            }else{
                contrastCode = [NSString stringWithFormat:@"%@.textAlignment %@ %d", model.name, [self getRandomDecide], arc4random() % 3];
            }
        }
            break;
        default:
            break;
    }
    
    return contrastCode;
}

//调用垃圾运算后赋值给静态变量的代码
- (NSString *)buildNumberOperationCode{
    ConfusionAttributeModel *model = [self getRandomModelByType:MJBVariableTypeNSInteger];
    NSInteger circleNumber = arc4random() % 5 + 3;
    NSString *operationCode = [NSString stringWithFormat:@"%@ = %d ", model.name, arc4random() % 20];
    while (circleNumber > 0) {
        operationCode = [operationCode stringByAppendingString:[NSString stringWithFormat:@"%@ %d ",[self getRandomOperationDecide], arc4random() % 20]];
        if (circleNumber == 1) {
            operationCode = [operationCode stringByAppendingString:@";\n"];
        }
        circleNumber --;
    }
    return operationCode;
}

//比较符号
- (NSString *)getRandomDecide{
    NSInteger number = arc4random() % 3;
    NSString *decideSymbol;
    if (number == 0) {
        decideSymbol = @"<";
    }else if (number == 1){
        decideSymbol = @"==";
    }else{
        decideSymbol = @">";
    }
    return decideSymbol;
}

//运算符号
- (NSString *)getRandomOperationDecide{
    NSInteger number = arc4random() % 3;
    NSString *decideSymbol;
    if (number == 0) {
        decideSymbol = @"+";
    }else if (number == 1){
        decideSymbol = @"-";
    }else if (number == 2){
        decideSymbol = @"*";
    }else{
        decideSymbol = @"/";
    }
    return decideSymbol;
}

//随机获得一个 类型名称的字符串
- (NSString *)getRandomTypeString:(MJBVariableTypes)ruleOutType haveRuleOut:(BOOL)haveRuleOut{
    NSString *typeString;
    NSInteger number = arc4random() % variableTypesNumber;
    while (number == ruleOutType && haveRuleOut) {
        number = arc4random() % variableTypesNumber;
    }
    typeString = [ToolClass getTypeString:number];
    return typeString;
}

//替换指定字符
- (void)replaceCodeInSourceCode:(NSMutableString *)originalString
              regularExpression:(NSString *)regularExpression
                      newString:(NSString *)newString{
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regularExpression options:NSRegularExpressionDotMatchesLineSeparators error:nil];
    NSArray<NSTextCheckingResult *> *matches = [expression matchesInString:originalString options:0 range:NSMakeRange(0, originalString.length)];
    [matches enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [originalString replaceCharactersInRange:obj.range withString:newString];
    }];
}


- (ConfusionAttributeModel *)getRandomModelByType:(MJBVariableTypes)variableTypes{
    NSMutableArray *array;
    NSInteger numberMax = 0;
    switch (variableTypes) {
        case MJBVariableTypeNSString:{
            array = self.stringTypeArray;
            numberMax = self.stringTypeNumberMax;
        }
            break;
        case MJBVariableTypeNSArray:{
            array = self.arrayTypeArray;
            numberMax = self.arrayTypeNumberMax;
        }
            break;
        case MJBVariableTypeNSDictionary:{
            array = self.dicTypeArray;
            numberMax = self.dicTypeNumberMax;
        }
            break;
        case MJBVariableTypeUILabel:{
            array = self.labelTypeArray;
            numberMax = self.labelTypeNumberMax;
        }
            break;
        case MJBVariableTypeNSInteger:{
            array = self.interTypeArray;
            numberMax = self.interTypeNumberMax;
        }
            break;
        default:
            break;
    }
    ConfusionAttributeModel *model;
    if (array.count < numberMax) {
        model = [[ConfusionAttributeModel alloc] init];
        model.isStaticVariable = arc4random() % 2;
        model.variableType = variableTypes;
        model.isClassification = self.isClassification;
        model.name = [ToolClass getRandomStr:0];
        [array addObject:model];
    }else{
        NSInteger index = arc4random() % array.count;
        model = array[index];
    }
    return model;
}

#pragma mark - Getter
- (NSMutableArray *)attributeArray{
    if (!_attributeArray) {
        _attributeArray = [NSMutableArray arrayWithCapacity:0];
        [_attributeArray addObjectsFromArray:self.arrayTypeArray];
        [_attributeArray addObjectsFromArray:self.stringTypeArray];
        [_attributeArray addObjectsFromArray:self.interTypeArray];
        [_attributeArray addObjectsFromArray:self.dicTypeArray];
        [_attributeArray addObjectsFromArray:self.labelTypeArray];
    }
    return _attributeArray;
}

@end

@implementation ConfusionAttributeModel

- (BOOL)isStaticVariable{
    if (self.isClassification) {
        return YES;
    }
    return _isStaticVariable;
}


@end
