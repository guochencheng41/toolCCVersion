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

@end
