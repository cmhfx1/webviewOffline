
//  NSURLSessionConfiguration+ToDefault.m
//  testJSCore
//
//  Created by fx on 2017/12/13.
//  Copyright © 2017年 fx. All rights reserved.
//

#import "NSURLSessionConfiguration+ToDefault.h"
#import <objc/runtime.h>

@implementation NSURLSessionConfiguration (ToDefault)


+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL originSel = @selector(defaultSessionConfiguration);
        SEL customSel = @selector(defaultSessionConfigurationCustom);
        Method m1 = class_getClassMethod(self, originSel);
        Method m2 = class_getClassMethod(self, customSel);
        if (m1 && m2) {
            method_exchangeImplementations(m1, m2);
        }
    });
}

// 或定义一个新方法
+ (NSURLSessionConfiguration *)defaultSessionConfigurationCustom
{
    NSURLSessionConfiguration *sessionConfig =  [self defaultSessionConfigurationCustom];//并不是单例方法
    sessionConfig.protocolClasses = @[[NSClassFromString(@"CustomP") class]];
    return sessionConfig;
}


@end
