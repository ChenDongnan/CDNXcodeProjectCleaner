//
//  CDNProjectCleanManager.h
//  CDNXcodeProjectCleaner
//
//  Created by 陈栋楠 on 2018/6/19.
//  Copyright © 2018年 陈栋楠. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CDNProjectCleanManagerDelegate<NSObject>
@required
- (void)searchAllClassesSuccess:(NSMutableDictionary *)dic;
- (void)searchUnusedClassesSuccess:(NSMutableDictionary *)dic;
- (void)cleanUnusedClassesSuccess:(NSMutableDictionary *)dic;


@optional
- (void)searchAllClassesError:(NSError *)error;
- (void)searchUnusedClassesError:(NSError *)error;
- (void)cleanUnusedClassesError:(NSError *)error;

@end

@interface CDNProjectCleanManager : NSObject
@property (nonatomic, weak) id<CDNProjectCleanManagerDelegate> delegate;


/**
 设置不需要清理的类

 @param array 不需要清理的类
 */
- (void)setIgnoredClasses:(NSArray *)array;


/**
 开始搜索

 @param path 项目路径
 */
- (void)startSearchingWithProjectPath: (NSString *)path;


/**
 清理无用项目
 */
- (void)clearFileAndMetaData;

@end
