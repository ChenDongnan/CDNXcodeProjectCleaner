//
//  CDNProjectCleanManager.m
//  CDNXcodeProjectCleaner
//
//  Created by 陈栋楠 on 2018/6/19.
//  Copyright © 2018年 陈栋楠. All rights reserved.
//

#import "CDNProjectCleanManager.h"
#import <Cocoa/Cocoa.h>

@implementation CDNProjectCleanManager {
    NSMutableDictionary *_allClasses;
    NSMutableDictionary *_unusedClasses;
    NSMutableDictionary *_usedClasses;
    NSMutableArray *_ignoredClasses;
    NSDictionary *_objects;
    NSString *_projectDir;
    NSString *_pbxprojPath;
}


- (instancetype)init {
    if (self = [super init]) {
        _allClasses = [NSMutableDictionary dictionary];
        _unusedClasses = [NSMutableDictionary dictionary];
        _usedClasses = [NSMutableDictionary dictionary];
        [self resetIgnoredClasses];
    }
    return self;
}

- (void)dealloc {
    _allClasses = nil;
    _unusedClasses = nil;
    _usedClasses = nil;
    _ignoredClasses = nil;
    _objects = nil;
    _projectDir = nil;
    _pbxprojPath = nil;
}

/** 设置忽略的类 */
- (void)setIgnoredClasses:(NSArray *)array {
    if (!array || array.count == 0) return;
    [self resetIgnoredClasses];
    for (id str in array) {
        if ([str isKindOfClass:[NSString class]] && ![_ignoredClasses containsObject:str]) {
            [_ignoredClasses addObject:str];
        }
    }
    
}


/**
 搜索未用到的类

 @param path 项目路径
 */

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wimplicit-retain-self"

- (void)startSearchingWithProjectPath:(NSString *)path {
    if (!path || ![path containsString:@".xcodeproj"]) {
        NSError *error = [NSError errorWithDomain:@"please input correct xcodeprojectpath" code:-1 userInfo:nil];
        NSAlert* alert = [NSAlert alertWithError:error];
        [alert beginSheetModalForWindow:[NSApplication sharedApplication].keyWindow completionHandler:nil];
        if (self.delegate && [self.delegate respondsToSelector:@selector(searchAllClassesError:)]) {
            [self.delegate searchAllClassesError:error];
        }
        return;
    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        /** 获取pbprojPath */
        _pbxprojPath = [path stringByAppendingPathComponent:@"project.pbxproj"];
         NSDictionary* pbxprojDic = [NSDictionary dictionaryWithContentsOfFile:_pbxprojPath];
        /** 获取objects和rootObject */
        _objects = pbxprojDic[@"objects"];
        NSString* rootObjectUuid = pbxprojDic[@"rootObject"];
        NSDictionary* projectObject = _objects[rootObjectUuid];
        /** 获取mainGroup dictionary */
        NSString* mainGroupUuid = projectObject[@"mainGroup"];
        NSDictionary* mainGroupDic = _objects[mainGroupUuid];
        /** 搜索所有类 */
        _projectDir = [path stringByDeletingLastPathComponent];
        [self searchAllClassesWithDir:_projectDir mainGroupDic:mainGroupDic uuid:mainGroupUuid];
        if ([self.delegate respondsToSelector:@selector(searchAllClassesSuccess:)]) {
            [self.delegate searchAllClassesSuccess:_allClasses];
        }
        /** 搜索用到的类 */
        [self searchUsedClassesWithDir:_projectDir mainGroupDic:mainGroupDic uuid:mainGroupUuid];
        
        /** 计算未用到的类 */
        _unusedClasses = [NSMutableDictionary dictionaryWithDictionary:_allClasses];
        for (NSString *key in _unusedClasses) {
            [_unusedClasses removeObjectForKey:key];
        }
        if ([_delegate respondsToSelector:@selector(searchUnusedClassesSuccess:)]) {
            [_delegate searchUnusedClassesSuccess:_unusedClasses];
        }
        
    });
}

#pragma clang diagnostic pop

- (void)clearFileAndMetaData {
    for (NSString *ignoredKey in _ignoredClasses) {
        [_unusedClasses removeObjectForKey:ignoredKey];
    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *projectContent = [NSString stringWithContentsOfFile:_pbxprojPath encoding:NSUTF8StringEncoding error:nil];
        NSMutableArray *projectContentArray = [NSMutableArray arrayWithArray:[projectContent componentsSeparatedByString:@"\n"]];
        NSArray *deleteImages = _unusedClasses.allValues;
        for (NSDictionary *classInfo in deleteImages) {
            NSArray *classKeys = classInfo[@"keys"];
            NSArray *classPaths = classInfo[@"paths"];
            /** 判断有没有.m文件 */
            BOOL hasMFile = NO;
            for (NSString *path in classPaths) {
                if ([path.pathExtension isEqualToString:@".m"]) {
                    hasMFile = YES;
                }
            }
            if (hasMFile == NO)
                continue;
            for (NSString *key in classKeys) {
                [projectContentArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj containsString:key]) {
                        [projectContentArray removeObjectAtIndex:idx];
                    }
                }];
            }
            
            for (NSString *path in classPaths) {
                [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
            }
        }
        
        projectContent = [projectContentArray componentsJoinedByString:@"\n"];
        
        NSError *error = nil;
        [projectContent writeToFile:_pbxprojPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *alert = [NSAlert alertWithError:error];
                [alert beginSheetModalForWindow:[NSApplication sharedApplication].keyWindow completionHandler:nil];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([_delegate respondsToSelector:@selector(cleanUnusedClassesSuccess:)]) {
                    [_delegate cleanUnusedClassesSuccess:_unusedClasses];
                }
            });
        }
        
    });
}


/** 重置忽略的类 */
- (void)resetIgnoredClasses {
    _ignoredClasses = [NSMutableArray arrayWithObjects:@"main",@"AppDelegate",@"ViewController", nil];
}


- (void)searchAllClassesWithDir:(NSString*)dir mainGroupDic:(NSDictionary*)mainGroupDic uuid:(NSString*)uuid{
}

- (void)searchUsedClassesWithDir:(NSString*)dir mainGroupDic:(NSDictionary*)mainGroupDic uuid:(NSString*)uuid{
    
}
















@end
