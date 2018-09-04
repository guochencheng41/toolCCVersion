//
//  ToolClass.m
//  MJB_Project
//
//  Created by 郭晨成 on 2018/8/27.
//  Copyright © 2018年 wangzhi. All rights reserved.
//

#import "ToolClass.h"

@implementation ToolClass


+ (BOOL)isLetterWord:(NSString *)str{
    NSRegularExpression *tLetterRegularExpression = [NSRegularExpression regularExpressionWithPattern:@"[A-Za-z]" options:NSRegularExpressionAllowCommentsAndWhitespace error:nil];
    NSInteger headStrCount = [tLetterRegularExpression numberOfMatchesInString:str options:NSMatchingReportProgress range:NSMakeRange(0, 1)];
    return headStrCount;
}

+ (BOOL)isWhiteList:(NSString *)str listName:(NSString *)listName{
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:listName ofType:@"plist"];
    NSArray *arr = [NSArray arrayWithContentsOfFile:plistPath];
    BOOL isWhiteListClass = NO;
    for (NSString *whiteClassName in arr) {
        if ([whiteClassName isEqualToString:str]) {
            isWhiteListClass = YES;
            break;
        }
    }
    return isWhiteListClass;
}

+ (NSString *)getRandomStr:(NSInteger)number{
    if (number <= 0) {
        number = arc4random() % 24 + confunsionStaticMinLength;
    }
    NSString *randomStr = @"";
    while (number > 0) {
        int lowercaseLetter = (arc4random() % 26) + 97;
        int capitalLetters = (arc4random() % 26) + 65;
        char character = (arc4random() % 2) ? lowercaseLetter : capitalLetters;
        NSString *tempString = [NSString stringWithFormat:@"%c", character];
        randomStr = [randomStr stringByAppendingString:tempString];
        number --;
    }
    return randomStr;
}

+ (MJBVariableTypes)getRandomType{
    NSInteger number = arc4random() % variableTypesNumber;
    return number;
}

+ (NSString *)getTypeString:(MJBVariableTypes)type{
    NSString *typeString;
    switch (type) {
        case MJBVariableTypeNSString:
            typeString = @"NSString";
            break;
        case MJBVariableTypeNSArray:
            typeString = @"NSArray";
            break;
        case MJBVariableTypeNSDictionary:
            typeString = @"NSDictionary";
            break;
        case MJBVariableTypeUILabel:
            typeString = @"UILabel";
            break;
        case MJBVariableTypeNSInteger:
            typeString = @"NSInteger";
            break;
        case MJBVariableTypeVoid:
            typeString = @"void";
            break;
        default:
            break;
    }
    return typeString;
}

+ (NSString *)getClassNameByImplementation:(NSString *)originalString{
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:@"@implementation " options:NSRegularExpressionDotMatchesLineSeparators error:nil];
    NSArray<NSTextCheckingResult *> *matches = [expression matchesInString:originalString options:0 range:NSMakeRange(0, originalString.length)];
    __block NSString *className;
    [matches enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSInteger classNameStartLocation = obj.range.location + obj.range.length;
        NSInteger classNameEndLocation = obj.range.location + obj.range.length;
        NSString *nameHeadStr = [originalString substringWithRange:NSMakeRange(classNameEndLocation, 1)];
        while ([ToolClass isLetterWord:nameHeadStr] || [nameHeadStr isEqualToString:@"_"]) {
            classNameEndLocation ++;
            nameHeadStr = [originalString substringWithRange:NSMakeRange(classNameEndLocation, 1)];
        }
        NSRange classNameRange = NSMakeRange(classNameStartLocation, classNameEndLocation - classNameStartLocation);
        className = [originalString substringWithRange:classNameRange];
    }];
    return className;
}

@end
