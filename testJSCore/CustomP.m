//
//  CustomP.m
//  testJSCore
//
//  Created by fx on 2017/12/13.
//  Copyright © 2017年 fx. All rights reserved.
//

#import "CustomP.h"
#import <objc/runtime.h>
#import <CommonCrypto/CommonDigest.h>
#import "NetWorkTool.h"

@interface ArchiverModel : NSObject<NSCoding>
@property (nonatomic,strong)NSURLResponse *response;
@property (nonatomic,strong)NSData *data;
@property (nonatomic,strong)NSDate *date;
@end

@implementation ArchiverModel
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    unsigned int count;
    Ivar *ivar = class_copyIvarList([self class], &count);
    for (int i = 0; i < count; i++) {
        Ivar iv = ivar[i];
        const char *name = ivar_getName(iv);
        NSString *key = [NSString stringWithUTF8String:name];
        id value = [self valueForKey:key];
        [aCoder encodeObject:value forKey:key];
    }
    free(ivar);
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        unsigned int count = 0;
        Ivar *ivar = class_copyIvarList([self class], &count);
        for (int i = 0; i < count; i++) {
            Ivar var = ivar[i];
            const char *name = ivar_getName(var);
            NSString *key = [NSString stringWithUTF8String:name];
            id value = [aDecoder decodeObjectForKey:key];
            [self setValue:value forKey:key];
        }
        free(ivar);
    }
    return self;
}
@end


@interface NSString (MD5)
- (NSString *)md5String;
@end
@implementation NSString(MD5)
- (NSString *)md5String {
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, (unsigned int)data.length, digest);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return output;
}
@end


NSString *dealedKey = @"CustomPDealed";
NSString *dirName = @"webcache";
@interface CustomP()<NSURLSessionDelegate,NSURLSessionDataDelegate>
@property (nonatomic,strong)NSURLSession * session;
@property (nonatomic,strong)NSMutableData *data;
@property (nonatomic,strong)NSURLResponse *response;
@property (nonatomic,assign)BOOL isConnect;
@end

@implementation CustomP

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    if ([[NSURLProtocol propertyForKey:dealedKey inRequest:request] integerValue])
    {
        return NO;
    }
    return YES;
}
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b{
    return [super requestIsCacheEquivalent:a toRequest:b];
}

- (void)startLoading{
    NSMutableURLRequest * request = [self.request mutableCopy];
    if ([[NetWorkTool defaultTool] isConnect]) {
        [NSURLProtocol setProperty:@(YES) forKey:dealedKey inRequest:request];
    
        NSURLSession *session =[NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
        self.session =session;
        NSURLSessionDataTask*task= [session dataTaskWithRequest:request];
        [task resume];
    }else{
        
        NSString *dir =  [self direPath];;
        NSString *path = [dir stringByAppendingPathComponent: [self.request.URL.absoluteString md5String]];
        ArchiverModel *model = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
        if (model) {
            NSLog(@"无网络 使用缓存");
            [self.client URLProtocol:self didReceiveResponse:model.response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
            [self.client URLProtocol:self didLoadData:model.data];
            [self.client URLProtocolDidFinishLoading:self];
        }else{
            NSLog(@"无网络 无缓存");
        }
    }
}

- (void)stopLoading {
    [self.session invalidateAndCancel];
    self.session = nil;
    self.response = nil;
    self.data = nil;
}

#pragma mark -- session delegate ---
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    NSLog(@"%@",response);
    
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    completionHandler(NSURLSessionResponseAllow);
    self.response = response;
    self.data = [NSMutableData data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSLog(@"error %@",error);
    if (error) {
        [self.client URLProtocol:self didFailWithError:error];
        self.response = nil;
        self.data = nil;
    } else {
        if (!self.response || !self.data) return;
         [self insertFile];
         [self.client URLProtocolDidFinishLoading:self];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    NSLog(@"didReceiveData");
    [self.client URLProtocol:self didLoadData:data];
    
    [self.data appendData:data];
}


- (NSString *)direPath
{
    NSString *cachepath =  [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *dir = [cachepath stringByAppendingPathComponent:dirName];
    return dir;
}

- (void)insertFile
{
    ArchiverModel *model = [ArchiverModel new];
    model.response = self.response;
    model.data = self.data;
    NSString *dirPath = [self direPath];
    BOOL isDir;
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:dirPath isDirectory:&isDir];
    if (isExist && isDir) {
        BOOL insetF = [NSKeyedArchiver archiveRootObject:model toFile:[dirPath stringByAppendingPathComponent:[self.request.URL.absoluteString md5String]]];
        if (insetF) {
            NSLog(@"插入文件成功");
        }else{
            NSLog(@"插入文件失败");
        }
    }else if(!isExist){
        BOOL isCreate = [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
        if (isCreate) {
            NSLog(@"创建 cache 成功");
        }else{
            NSLog(@"创建 cache 失败");
        }
    }
}

@end


