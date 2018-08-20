//
//  ViewController.m
//  MJB_Project
//
//  Created by wangzhi on 2018/7/29.
//  Copyright © 2018年 wangzhi. All rights reserved.
//

#import "ViewController.h"
#import "ConfusionClass.h"
#import "ConfusionFunction.h"
#import "ExportWhiteFunction.h"
@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.mjb_rootProjectTextField.editable = NO;
	self.mjb_pbTextField.editable = NO;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(printMessage:) name:kNotificationPrint object:nil];
	// Do any additional setup after loading the view.
}

-(void)printMessage:(NSNotification*)not{
	NSString *str = not.object;
	if (str.length > 0){
		[self printRecord:str];
	}
}


- (void)setRepresentedObject:(id)representedObject {
	[super setRepresentedObject:representedObject];

	// Update the view, if already loaded.
}

- (IBAction)selctrootProjectAction:(id)sender {
	__weak typeof(self)weakSelf = self;
	[self selectfoldPath:^(NSString *p) {
		weakSelf.mjb_rootProjectTextField.stringValue = p;
		gSourceCodeDir = p;
	}];
}

- (IBAction)selectPBAction:(id)sender {
	__weak typeof(self)weakSelf = self;
	[self selectfoldPath:^(NSString *p) {
		weakSelf.mjb_pbTextField.stringValue = p;
	}];
}



///开始执行
- (IBAction)startAction:(id)sender {
	self.mjb_recordTextView.string=@"";

//    if (gSourceCodeDir.length == 0) {
//        [self printRecord:[NSString stringWithFormat:@"工程目录的路径不能为空"]];
//        return;
//    }
	
	NSString *string = self.mjb_pbTextField.stringValue;
//    if (string.length == 0){
//        [self printRecord:[NSString stringWithFormat:@"工程xcodeproj文件的路径不能为空"]];
//        return;
//    }
	
	
	NSString* projectFilePath = [string stringByAppendingPathComponent:@"project.pbxproj"];
    
    kProjectFilePath = projectFilePath;
	
    //混淆类名
    executeModifyClassNamePrefix();
    
    //混淆函数名
//    ConfusionFunction *confusionFunction = [[ConfusionFunction alloc] init];
//    confusionFunction.sourceCodeDir = gSourceCodeDir;
//    [confusionFunction confusionFunction];
    
    //导出函数白名单
//    ExportWhiteFunction *exportWhiteFunction = [[ExportWhiteFunction alloc] init];
//    [exportWhiteFunction exportWhiteFunction:@"/Users/guochencheng/Desktop/白名单函数"];
}


-(void)printRecord:(NSString*)message{
	dispatch_async(dispatch_get_main_queue(), ^{
		NSString *m = [NSString stringWithFormat:@"%@%@\n",self.mjb_recordTextView.string,message];
		self.mjb_recordTextView.string = m;
	});
}

-(void)selectfoldPath:(void (^)(NSString* p))block{
	
	NSOpenPanel* panel = [NSOpenPanel openPanel];
	//是否可以创建文件夹
	panel.canCreateDirectories = YES;
	//是否可以选择文件夹
	panel.canChooseDirectories = YES;
	//是否可以选择文件
	panel.canChooseFiles = YES;
	
	//是否可以多选
	[panel setAllowsMultipleSelection:NO];
	
	//显示
	[panel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
		
		//是否点击open 按钮
		if (result == NSModalResponseOK) {
			//NSURL *pathUrl = [panel URL];
			NSString *pathString = [panel.URLs.firstObject path];
			if (block){
				block(pathString);
			}
		}
	}];
}


@end
