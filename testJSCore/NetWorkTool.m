//
//  NetWorkTool.m
//  testJSCore
//
//  Created by fx on 2017/12/12.
//  Copyright © 2017年 fx. All rights reserved.
//

#import "NetWorkTool.h"
#import <AFNetworking.h>

@interface NetWorkTool()
@property (nonatomic,strong)AFHTTPSessionManager *manager;
@property (nonatomic,weak)AFNetworkReachabilityManager *reachManager;
@end




@implementation NetWorkTool

static NetWorkTool *_instance;
static bool isConnect;

+ (id)defaultTool
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
        isConnect = YES;
        
        [self setupManager];
        [self setupReachabilityManager];
    });
    return _instance;
}


+ (void)setupManager
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    _instance.manager = manager;
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    
    //        [manager setTaskWillPerformHTTPRedirectionBlock:^NSURLRequest * _Nonnull(NSURLSession * _Nonnull session, NSURLSessionTask * _Nonnull task, NSURLResponse * _Nonnull response, NSURLRequest * _Nonnull request) {
    //
    //            return nil;
    //        }];
    
}

 + (void)setupReachabilityManager
{
    AFNetworkReachabilityManager *reachManager = [AFNetworkReachabilityManager sharedManager];
    _instance.reachManager = reachManager;
    [reachManager startMonitoring];
    [reachManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
            case AFNetworkReachabilityStatusReachableViaWWAN:
            case AFNetworkReachabilityStatusReachableViaWiFi:
            {
                isConnect = YES;
                break;
            }
            case AFNetworkReachabilityStatusNotReachable:
            {
                isConnect = NO;
                break;
            }
        }}];
}


- (void)requestWithUrl:(NSString *)url
{
    [_instance.manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"++++");
        NSLog(@"%@",responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"%@",error);
    }];
}

- (BOOL)isConnect
{
    return isConnect;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}

@end

