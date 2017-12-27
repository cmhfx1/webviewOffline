//
//  AFNetController.m
//  testJSCore
//
//  Created by fx on 2017/12/12.
//  Copyright © 2017年 fx. All rights reserved.
//

#import "AFNetController.h"
#import "NetWorkTool.h"
#import "CustomP.h"

@interface AFNetController ()<NSURLConnectionDelegate,NSURLConnectionDataDelegate,UIWebViewDelegate>
@end

@implementation AFNetController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor grayColor];
     [NetWorkTool defaultTool];
    

}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    // 1 测试网络请求拦截
    
    /** don't work   有效的姿势在类目 */
    //    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    //    NSLog(@"%@",sessionConfiguration);// AFURLSessionManager.m 520 不是单例对象
    //    sessionConfiguration.protocolClasses = @[[CustomP class]];
    
//    [self testRequestData];
    
    
    // 2 测试 webview 离线缓存
    [self testWebview];
    
    
    
    // 3 测试 重定向
//        [self testRedirect];
    
//    [NSURLProtocol registerClass:[CustomP class]];
//    UIWebView *web = [[UIWebView alloc] init];
//    web.frame = CGRectMake(0, 100, 320, self.view.frame.size.height-100);
//    web.backgroundColor = [UIColor whiteColor];
//    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://www.geogle.com"]];
//    [web loadRequest:request];
//    [self.view addSubview:web];
    
    
//    NSURL *url = [NSURL URLWithString:@"http://www.geogle.com"];
//    NSMutableURLRequest *quest = [NSMutableURLRequest requestWithURL:url];
//    //    quest.HTTPMethod = @"GET";
//    NSURLConnection *connect = [NSURLConnection connectionWithRequest:quest delegate:self];
//    [connect start];
}

- (void)testRequestData
{
    [[NetWorkTool defaultTool] requestWithUrl:@"http://www.233.com"];
}

- (void)testRedirect
{
   [[NetWorkTool defaultTool] requestWithUrl:@"http://www.geogle.com"];
}
- (void)testWebview
{
    [NSURLProtocol registerClass:[CustomP class]];
    UIWebView *web = [[UIWebView alloc] init];
    web.frame = CGRectMake(0, 100, 320, self.view.frame.size.height-100);
    web.backgroundColor = [UIColor whiteColor];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://www.baidu.com"]];//http://www.233.com
    web.delegate = self;
    [web loadRequest:request];
    [self.view addSubview:web];
    
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    NSLog(@"webViewDidStartLoad ____%@",[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]);

}


- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"webViewDidFinishLoad ____%@",[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]);
    
    
//    NSData *cookiesData = [NSKeyedArchiver archivedDataWithRootObject: [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]];
//
//    //存储归档后的cookie
//
//    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//
//    [userDefaults setObject: cookiesData forKey: @"cookie"];
    
}


- (nullable NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(nullable NSURLResponse *)response{

    NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)response;

    NSLog(@"%ld",urlResponse.statusCode);
    NSLog(@"%@",urlResponse.allHeaderFields);
    NSDictionary *dic = urlResponse.allHeaderFields;
    NSLog(@"%@",dic[@"Location"]);
    return request;
}
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"%@",response);
    NSLog(@"d");
}




- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    NSLog(@"d");
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    
    NSLog(@"data = %@",data);
}



@end
