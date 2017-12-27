//
//  AppDelegate.h
//  testJSCore
//
//  Created by fx on 2017/11/28.
//  Copyright © 2017年 fx. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;


@end

/*
 综合
 http://www.jianshu.com/p/ac45d99cf912
 http://www.jianshu.com/p/4db513ed2c1a
 http://www.jianshu.com/p/0042d8eb67c0
 
 
 
 //jscore
 http://nshipster.cn/javascriptcore/
 https://www.qcloud.com/community/article/873202?fromSource=gwzcw.93410.93410.93410
 
 http://www.jianshu.com/p/3f5dc8042dfc
 
 http://www.jianshu.com/p/1328e15416f3
 
 
 
 http://www.jb51.net/article/80861.htm   // js 函数
 
 https://www.zhihu.com/question/20653055   iframe
 https://zhidao.baidu.com/question/19235846.html
 https://zhidao.baidu.com/question/144610550.html
 https://www.cnblogs.com/inJS/p/6129945.html
 
 
 
 */



/*
 
 一
 
 
 第一版  WebViewJavascriptBridge  只有三个文件
 WebViewJavascriptBridge.h .m .js
 
 WebViewJavascriptBridge.h .m   用于 iOS
 - (void)registerHandler:(NSString *)handlerName handler:(WVJBHandler)handler;
 - (void)callHandler:(NSString *)handlerName data:(id)data responseCallback:(WVJBResponseCallback)responseCallback;
 
 
 WebViewJavascriptBridge.js 用于 注入 webview，在 web中 使用 window.WebViewJavascriptBridge
 registerHandler(handlerName, handler);
 callHandler(handlerName, data, responseCallback);
 
 
 这些函数 是做什么的，流程又是什么呢？
 
 
 _________

 二
 在与js交互 的 控制器
 
 WebViewJavascriptBridge *bridge = [WebViewJavascriptBridge bridgeForWebView:webView handler:^(id data, WVJBResponseCallback responseCallback) {}];
 
 创建 WebViewJavascriptBridge 对象，初始化其属性，成为 webview 的代理
 
 
 
 在 webview 的代理方法 中， webViewDidFinishLoad（request finish loaded） 执行 一段 js 代码
 [webview stringByEvaluatingJavaScriptFromString: WebViewJavascriptBridge.js];
 
 
 WebViewJavascriptBridge.js 定义了一个立即执行函数，函数内 定义 一系列闭包变量，及函数，执行完成后，
 
 
 window.WebViewJavascriptBridge = {}
 document 创建 iframe（用于发送请求（.src））
 
 
 
 加载完成后的页面，便可使用 执行 WebViewJavascriptBridge 函数
 

 ---------------
 
 三  js 调用 oc
 可通过发送请求 在 shouldStartLoadWithRequest 截获 url 进行解析，  oc方法 调用
 只是 调用了 oc 方法，交互完成，js 却不知调用结果
 
 
 因此，在bridge中，OC 先注册 方法  ，用于之后 js 的调用
 [bridge registerHandler:@"" handler:^(id data, WVJBResponseCallback responseCallback) {
 
 
 }];
 
 （来到 WebViewJavascriptBridge.m）该方法有两个参数， OC注册的函数名，以及 block 对应的函数实现。

 【 在 block 中写入函数实现，等待回调 block（js 调用函数）。该 block 存在参数，除用于回调 block 时传递数据（用于block 实现）外，还有个 block 参数，这个 参数 block（js函数）由 js 实现，我们负责回调该函数，告诉 js，js 方法调用结果。如在 block 内（如结尾），调用 参数block（当然，如果参数block 存在参数 ，也是 block 调用时传入） 】
 （之前一直把 参数block 理解为函数指针，发现 js 传入的是一个匿名函数实现）
 

 这个方法实现只有一句代码
 _messageHandlers[handlerName] = [handler copy];     键值对放入字典
 

 
 
 
 
 
 OC 注册完成，js 调用
 
 bridge.callHandler(handlerName, data, responseCallback)
 等价于 window.bridge.......（由于 执行js文件，window已经存在这个属性）， 而该函数调用 多在 html的js中
 
 【 handlerName  对应 regist 的函数名。传入的实参 ，调用函数，也即是回调 OC regist 的对应block，data 是 block的数据参数，responseCallback 则是 block的block实参，一个js函数实现，用于 回调结果 】
 
 
 1 来到 WebViewJavascriptBridge.js文件
 callHandler 的函数实现，将 handlerName，data 包装为字典，与 responseCallback  一同作为 _doSend()的参数
 
 2 _doSend 中 为回调函数 responseCallback 分配 id（callbackId） ，作为 回调函数键值对的key 放入 responseCallbacks 字典 ，然后 将 callbackId 放入 实参字典中作为value   （********正是通过这些变量作为仓库交互*****）
 
 将实参字典加入 sendMessageQueue 数组，然后  配置 scheme  隐藏的 iframe 发送请求，
 

 
 这一步 将回调 webview delegate 也就是 bridge（.m） 的  shouldStartLoadWithRequest  方法
 
 3 来到 WebViewJavascriptBridge.m 的方法实现
 
 stringByEvaluatingJavaScriptFromString:@"WebViewJavascriptBridge._fetchQueue();"
 
 执行 window.WebViewJavascriptBridge 的 _fetchQueue 函数，将 js callHandler 时存放字典的数组 sendMessageQueue 转json字符串返回，并清空其元素。
 然后 NSJSONSerialization 序列化，遍历数组，取出字典（这些字典就是 上一步js中包装 调用函数名 参数 回调函数实现id 的字典）
 
 如果，字典存在 callbackId ，则 js存在回调函数，也即是 regist 时，block的 block 实参是存在的。因此，构建一个 block。如何构建 该 block 呢？ 目的是，通过回调 该 block，调用 responseCallback
 
 【 当前在 .m，存在 对应 responseCallback 的 callbackId，responseCallback 存在 js变量中，因此 我们需要将 callbackId 传给 js，responseCallback 可能存在形参，实参也需要传递。因此将 两者包装成字典。然后 json 序列化，再转为OC string，进行格式调整。最后， stringByEvaluatingJavaScriptFromString   执行 js 函数（_handleMessageFromObjC），作为函数参数（类似 数据传递）
 
 
_handleMessageFromObjC，根据 callbackId，取出 responseCallbacks 字典中的 responseCallback，取出 执行，字典删除键值对 】
 

 
 根据 handlerName，取出 _messageHandlers 字典中 block实现，然后 传入参数（data（取自字典），和刚构建的block），回调 block
 


 


 -----------

 四 OC 调用 js
 同样的流程，js 先注册
 
 
 在 需要交互的html 中 定义 一个js 函数
 function connectWebViewJavascriptBridge(callback) {
     if (window.WebViewJavascriptBridge) {
         callback(WebViewJavascriptBridge);
     } else {
         document.addEventListener('WebViewJavascriptBridgeReady', function() {
     callback(WebViewJavascriptBridge);}, false);
     }
 }
 
 函数存在 类似一个函数指针的形参，函数内判断 window.WebViewJavascriptBridge 是否存在，存在则调用函数指针，传入 window.WebViewJavascriptBridge 作为参数，否则 接收到 WebViewJavascriptBridgeReady 事件后，调用
 
 
 接下来是函数调用，调用上面定义的函数，传入的实参函数
 connectWebViewJavascriptBridge(function(bridge) {
 
     bridge.init(function(message, responseCallback) {});
 
 
     bridge.registerHandler('objc_Call_JS_UpdateNum', function(data, responseCallback) {});
 
 
     xxx.onclick = function(e) {
         bridge.callHandler('', '', function(response) {   });}
 });
 
 实参函数的 参数 bridge 就是 调用时传入的 window.WebViewJavascriptBridge
 
 
 
 在 实参函数中 js regist 函数（在实参函数能拿到 window.WebViewJavascriptBridge）
 function registerHandler(handlerName, handler) {
    messageHandlers[handlerName] = handler
 }
 
 
 
 来到 WebViewJavascriptBridge.js，实现如此与 WebViewJavascriptBridge.m ，oc regist 相似
 
 
 
 
 
 而 oc 调用时，也是 传入 函数名，函数参数，回调block（看 .m 的OC 实现更易懂）
 [bridge callHandler:@"" data:@{} responseCallback:^(id response) {
 
 }];
 
 - (void)callHandler:(NSString *)handlerName data:(id)data responseCallback:(WVJBResponseCallback)responseCallback {
     [self _sendData:data responseCallback:responseCallback handlerName:handlerName];
 }
 
 
 同样 包装成字典，回调 block 放入 _responseCallbacks，callbackId 放入字典。进行分发 执行 js 方法，传递数据
 - (void)_sendData:(id)data responseCallback:(WVJBResponseCallback)responseCallback handlerName:(NSString*)handlerName {
     NSMutableDictionary* message = [NSMutableDictionary dictionary];
 
     if (data) {
         message[@"data"] = data;
     }
 
     if (responseCallback) {
         NSString* callbackId = [NSString stringWithFormat:@"objc_cb_%ld", ++_uniqueId];
         _responseCallbacks[callbackId] = [responseCallback copy];
         message[@"callbackId"] = callbackId;
     }
 
     if (handlerName) {
         message[@"handlerName"] = handlerName;
     }
     [self _queueMessage:message];
 }
 
 来到 _dispatchMessageFromObjC，如果 存在 callbackId，则 包装成一个函数 responseCallback
 从 messageHandlers 取出函数实现，传入 参数执行
 
 
 responseCallback 如何实现？之前 js 调用 oc，回调函数 js 实现，在 oc 中包装成 block，block 中调用 js 方法，包装一个字典进行数据传递。这里一样，也是通过 一个字典进行数据传递 ，包装 callbackResponseId  与 data
 
 放入 数组，然后 iframe 发出 请求，.m 拦截到请求 会 取出数组字典~
 
 
 
 
 
 
 
 
 
 
 
 js 如果想呼叫 oc    iframe
 oc 如果想呼叫 js    stringByEvaluatingJavaScriptFromString
 再配合  数组 字典属性
 
 
 
 
 
 跳转另一个网页 ——>  didfinishload  也会注入 bridge
 
 
 */











/*
 JSContext *context = [[JSContext alloc] init];
 
 
 // 1 常量
 JSValue *constV = [context evaluateScript:@"2+2"];
 NSLog(@"constV = %@",[constV toNumber]);
 
 
 
 // 2 变量 类似键值对
 [context evaluateScript:@"var num = 10"];
 JSValue *varV = context[@"num"];
 NSLog(@"varV = %@",varV.toNumber);
 
 
 // 3 函数调用方式似乎比较多
 [context evaluateScript:@"var mup = function(x,y) {return x * y}"];
 // [context evaluateScript:@"function add(a,b) {return a + b}"];
 
 JSValue *funV = [context evaluateScript:@"mup(2,3)"];
 NSLog(@"funV = %@",funV.toNumber);
 JSValue *funv = [context[@"mup"] callWithArguments:@[@"3", @"3"]];
 NSLog(@"funv = %@",funv.toNumber);
 
 
 
 
 
 
 
 
 // 方法映射
 - (void)webViewDidFinishLoad:(UIWebView *)webView
 {
 
 1 获取 JSContext
 JSContext *context = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
 
 
 2 方法注册 oc -> js（OC方法 添加或替换 JS实现 ）
 context[@"jsFunctionName"] = ^(){
 };
 
 
 
 };
 
 // 获取 js 调用时 传入的实参 @[JSValue, JSValue...]
 NSArray *args = [JSContext currentArguments];
 
 
 

 
 
 
 
 
 
 js 调用 oc（注册 js 方法）
 context[@"jsFunctionName"] = ^(){
 
 };
 
 
 
 oc 调用 js（执行 js 函数）
 evaluateScript:
 
 
 
 那么，回调呢？
 
 
 context[@"jsFunctionName"] = ^(){
 
 
 ....
 evaluateScript:
 
 
 };
 
 
 
 异步?
 取出实参中的 函数指针 ，包装到  block ，回调 block
 
 
 
 
 
 
 
 
 
 */









/*
 
 
 wkwebview
 
 
 http://liuyanwei.jumppo.com/2015/10/17/ios-webView.html
 https://lvwenhan.com/ios/460.html
 
 http://huanhoo.net/2016/12/13/WKWebView中的那些坑/
 
 http://www.jianshu.com/p/f94cad074196
 
 
 http://www.brighttj.com/ios/ios-wkwebview-new-features-and-use.html
 
 http://www.jianshu.com/p/4fa8c4eb1316
 
 http://www.jianshu.com/p/7bb5f15f1daa
 
 
 
 
 
 
 
 */







