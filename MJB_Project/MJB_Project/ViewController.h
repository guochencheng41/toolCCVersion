//
//  ViewController.h
//  MJB_Project
//
//  Created by wangzhi on 2018/7/29.
//  Copyright © 2018年 wangzhi. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController
@property (weak) IBOutlet NSTextField *mjb_rootProjectTextField; //配置工程路径  根目录用来遍历属性用
@property (weak) IBOutlet NSTextField *mjb_pbTextField;    //工程文件路径
@property (weak) IBOutlet NSTextView *mjb_recordTextView; //输出日志

@end

