//
//  MJB_Utils.h
//  MJB_Project
//
//  Created by wangzhi on 2018/7/29.
//  Copyright © 2018年 wangzhi. All rights reserved.
//

#import <Foundation/Foundation.h> 
extern NSString *gSourceCodeDir;
extern NSString *kNotificationPrint;
@interface MJB_Utils : NSObject

void  executeModifyClassNamePrefix(NSString *oldClassNamePrefix,
										  NSString *newClassNamePrefix, 
										  NSArray<NSString *> *ignoreDirNames,
										  NSString *projectFilePath);

void modifyClassNamePrefix(NSMutableString *projectContent, 
								  NSString *sourceCodeDir, 
								  NSArray<NSString *> *ignoreDirNames, 
								  NSString *oldName, 
								  NSString *newName);
 
@end
