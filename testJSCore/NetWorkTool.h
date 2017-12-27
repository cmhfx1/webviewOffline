//
//  NetWorkTool.h
//  testJSCore
//
//  Created by fx on 2017/12/12.
//  Copyright © 2017年 fx. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface NetWorkTool : NSObject

+ (id)defaultTool;
- (void)requestWithUrl:(NSString *)url;
- (BOOL)isConnect;
@end
