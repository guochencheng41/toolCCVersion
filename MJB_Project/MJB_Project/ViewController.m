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
#import "ConfusionStaticVariable.h"
#import "ConfusionLocalString.h"
#import "ConfusionCode.h"
#import "ConfunsionClassNumber.h"
#import "ConfusionImageName.h"
@interface ViewController()

@property (nonatomic, strong) NSString *sourceCodeDir;

@property (nonatomic, strong) NSString *projectFilePath;

@end
@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.mjb_rootProjectTextField.editable = NO;
	self.mjb_pbTextField.editable = NO;
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
		self.sourceCodeDir = p;
	}];
}

- (IBAction)selectPBAction:(id)sender {
	__weak typeof(self)weakSelf = self;
	[self selectfoldPath:^(NSString *p) {
		weakSelf.mjb_pbTextField.stringValue = p;
        NSString* projectFilePath = [p stringByAppendingPathComponent:@"project.pbxproj"];
        self.projectFilePath = projectFilePath;
	}];
}



///开始执行
- (IBAction)startAction:(id)sender {
//    //混淆图片
    ConfusionImageName *imageName = [[ConfusionImageName alloc] init];
    [imageName confusionImage:self.sourceCodeDir projectFile:self.projectFilePath];

//    导出函数白名单
//    ExportWhiteFunction *exportWhiteFunction = [[ExportWhiteFunction alloc] init];
//    [exportWhiteFunction exportWhiteFunction:@"/Users/guochencheng/Desktop/白名单函数"];

//    混淆静态变量
    ConfusionStaticVariable *confusionVariable = [[ConfusionStaticVariable alloc] init];
    confusionVariable.sourceCodeDir = self.sourceCodeDir;
    [confusionVariable confusionStaticVariable];

    //混淆代码块逻辑
    ConfusionCode *confusionCode = [[ConfusionCode alloc] init];
    [confusionCode confusion:self.sourceCodeDir];
    
    //混淆函数名
    ConfusionFunction *confusionFunction = [[ConfusionFunction alloc] init];
    confusionFunction.sourceCodeDir = self.sourceCodeDir;
    [confusionFunction confusionFunction];

    //混淆类名
    ConfusionClass *confusionClass = [[ConfusionClass alloc] init];
    confusionClass.sourceCodeDir = self.sourceCodeDir;
    confusionClass.projectFilePath = self.projectFilePath;
    [confusionClass confusionClassName];

//    混淆字符串
    ConfusionLocalString *confusionLocalStr = [[ConfusionLocalString alloc] init];
    [confusionLocalStr confusionLocalString:self.sourceCodeDir];

    //混淆类数量
    ConfunsionClassNumber *classNumber = [[ConfunsionClassNumber alloc] init];
    classNumber.modelNameArray = confusionCode.modelNameArray;
    [classNumber confusionClassCode:self.sourceCodeDir];
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
