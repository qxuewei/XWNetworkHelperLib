//
//  XWNetworkHelper.m
//  XWNetworkHelperDemo
//
//  Created by 邱学伟 on 2018/2/24.
//  Copyright © 2018年 邱学伟. All rights reserved.
//

#import "XWNetworkHelper.h"
#import "AFNetworking.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "YYCache.h"

#pragma mark - 宏

#ifdef DEBUG
#define XWNetLog(...) printf("[%s] %s [第%d行]: %s\n", __TIME__ ,__PRETTY_FUNCTION__ ,__LINE__, [[NSString stringWithFormat:__VA_ARGS__] UTF8String])
#else
#define XWNetLog(...)
#endif

#define XWNSStringFormat(format,...) [NSString stringWithFormat:format,##__VA_ARGS__]


//********************************************************************************************
#pragma mark - 网络工具类
@interface XWNetworkHelper ()
@end

//********************************************************************************************
#pragma mark - 缓存相关
@interface XWNetworkHelperCache : NSObject

/**
 缓存网络请求

 @param httpData 请求数据
 @param URL 路径
 @param paramters 参数
 */
+ (void)setHttpCache:(id)httpData URL:(NSString *)URL parameters:(NSDictionary *)paramters;

/**
 获取已缓存网络数据

 @param URL 路径
 @param paramters 参数
 @return 已缓存数据
 */
+ (id)httpCacheWithURL:(NSString *)URL paramters:(NSDictionary *)paramters;

/**
 获取已缓存数据大小

 @return 当前已缓存数据
 */
+ (NSUInteger)getAllHttpCacheSize;

/**
 移除所有缓存数据
 */
+ (void)removeAllHttpCache;
@end

//********************************************************************************************
#pragma mark - 网络工具类
@implementation XWNetworkHelper
static BOOL xw_isOpenLog;
static NSMutableArray <NSURLSessionTask *> *xw_allSessionTask;
static AFHTTPSessionManager *xw_sessionManager;

#pragma mark - public
/// 有网YES, 无网:NO
+ (BOOL)isNetwork {
    return [AFNetworkReachabilityManager sharedManager].isReachable;
}

/// 手机网络:YES, 反之:NO
+ (BOOL)isWWANNetwork {
    return [AFNetworkReachabilityManager sharedManager].isReachableViaWWAN;
}

/// WiFi网络:YES, 反之:NO
+ (BOOL)isWiFiNetwork {
    return [AFNetworkReachabilityManager sharedManager].isReachableViaWiFi;
}

/// 取消所有HTTP请求
+ (void)cancelAllRequest {
    [[self xw_allSessionTask] enumerateObjectsUsingBlock:^(NSURLSessionTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj cancel];
    }];
    [[self xw_allSessionTask] removeAllObjects];
}

/// 实时获取网络状态,通过Block回调实时获取(此方法可多次调用)
+ (void)networkStatusWithBlock:(XWNetworkStatus)networkStatus {
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
                networkStatus ? networkStatus(XWNetworkStatusTypeUnknown) : nil;
                if (xw_isOpenLog) {
                    XWNetLog(@"未知网络!");
                }
                break;
            case AFNetworkReachabilityStatusNotReachable:
                networkStatus ? networkStatus(XWNetworkStatusTypeNotReachable) : nil;
                if (xw_isOpenLog) {
                    XWNetLog(@"无网络!");
                }
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
                networkStatus ? networkStatus(XWNetworkStatusTypeReachableWWAN) : nil;
                if (xw_isOpenLog) {
                    XWNetLog(@"手机网络!");
                }
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                networkStatus ? networkStatus(XWNetworkStatusTypeReachableWifi) : nil;
                if (xw_isOpenLog) {
                    XWNetLog(@"wifi网络!");
                }
                break;
                
            default:
                break;
        }
    }];
}

/// 取消指定URL的HTTP请求
+ (void)cancelRequestWithURL:(NSString *)URL {
    if (!URL || URL.length == 0) {
        return;
    }
    @synchronized(self) {
        [[self xw_allSessionTask] enumerateObjectsUsingBlock:^(NSURLSessionTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.currentRequest.URL.absoluteString hasPrefix:URL]) {
                [obj cancel];
                [[self xw_allSessionTask] removeObject:obj];
                *stop = YES;
            }
        }];
    }
}

/// 开启日志打印 (Debug级别)
+ (void)openLog {
    xw_isOpenLog = YES;
}

/// 关闭日志打印,默认关闭
+ (void)closeLog {
    xw_isOpenLog = NO;
}

#pragma mark Get 请求
/// Get 无缓存
+ (__kindof NSURLSessionTask *)GET:(NSString *)URL
                        parameters:(id)parameters
                           success:(XWHttpRequestSuccess)success
                           failure:(XWHttpRequestFailed)failure {
    return [self GET:URL parameters:parameters responseCache:nil success:success failure:failure];
}

/// Get 自动缓存
+ (__kindof NSURLSessionTask *)GET:(NSString *)URL
                        parameters:(id)parameters
                     responseCache:(XWHttpRequestCache)responseCache
                           success:(XWHttpRequestSuccess)success
                           failure:(XWHttpRequestFailed)failure {
    responseCache != nil ? responseCache([XWNetworkHelperCache httpCacheWithURL:URL paramters:parameters]) : nil;
    NSURLSessionTask *sessionTask = [xw_sessionManager GET:URL parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [[self xw_allSessionTask] removeObject:task];
        success ? success(responseObject) : nil;
        responseObject != nil ? [XWNetworkHelperCache setHttpCache:responseObject URL:URL parameters:parameters] : nil;
        if (xw_isOpenLog) {
            XWNetLog(@"success -> url:%@ -> param:%@ -> responseObject:%@",URL,parameters,responseObject);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [[self xw_allSessionTask] removeObject:task];
        failure ? failure(error) : nil;
        if (xw_isOpenLog) {
            XWNetLog(@"error -> url:%@ -> param:%@ -> error:%@",URL,parameters,error);
        }
        
    }];
    sessionTask ? [[self xw_allSessionTask] addObject:sessionTask] : nil;
    return sessionTask;
}

#pragma mark POST 请求
/// POST 无缓存
+ (__kindof NSURLSessionTask *)POST:(NSString *)URL
                        parameters:(id)parameters
                           success:(XWHttpRequestSuccess)success
                           failure:(XWHttpRequestFailed)failure {
    return [self POST:URL parameters:parameters responseCache:nil success:success failure:failure];
}

/// POST 自动缓存
+ (__kindof NSURLSessionTask *)POST:(NSString *)URL
                        parameters:(id)parameters
                     responseCache:(XWHttpRequestCache)responseCache
                           success:(XWHttpRequestSuccess)success
                           failure:(XWHttpRequestFailed)failure {
    responseCache != nil ? responseCache([XWNetworkHelperCache httpCacheWithURL:URL paramters:parameters]) : nil;
    NSURLSessionTask *sessionTask = [xw_sessionManager POST:URL parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [[self xw_allSessionTask] removeObject:task];
        success ? success(responseObject) : nil;
        responseObject != nil ? [XWNetworkHelperCache setHttpCache:responseObject URL:URL parameters:parameters] : nil;
        if (xw_isOpenLog) {
            XWNetLog(@"success -> url:%@ -> param:%@ -> responseObject:%@",URL,parameters,responseObject);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [[self xw_allSessionTask] removeObject:task];
        failure ? failure(error) : nil;
        if (xw_isOpenLog) {
            XWNetLog(@"error -> url:%@ -> param:%@ -> error:%@",URL,parameters,error);
        }
        
    }];
    sessionTask ? [[self xw_allSessionTask] addObject:sessionTask] : nil;
    return sessionTask;
}

#pragma mark 上传
#pragma mark 上次单个文件
+ (NSURLSessionTask *)uploadFileWithURL:(NSString *)URL
                             parameters:(id)parameters
                                   name:(NSString *)name
                               filePath:(NSString *)filePath
                               progress:(XWHttpProgress)progress
                                success:(XWHttpRequestSuccess)success
                                failure:(XWHttpRequestFailed)failure {
    NSURLSessionTask *sessionTask = [xw_sessionManager POST:URL parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSError *error = nil;
        [formData appendPartWithFileURL:[NSURL URLWithString:filePath] name:name error:&error];
        (failure && error) ? failure(error) : nil;
        
    } progress:^(NSProgress * _Nonnull downloadProgress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            progress ? progress(downloadProgress) : nil;
        });
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [[self xw_allSessionTask] removeObject:task];
        success ? success(responseObject) : nil;
        responseObject != nil ? [XWNetworkHelperCache setHttpCache:responseObject URL:URL parameters:parameters] : nil;
        if (xw_isOpenLog) {
            XWNetLog(@"success -> url:%@ -> param:%@ -> responseObject:%@",URL,parameters,responseObject);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [[self xw_allSessionTask] removeObject:task];
        failure ? failure(error) : nil;
        if (xw_isOpenLog) {
            XWNetLog(@"error -> url:%@ -> param:%@ -> error:%@",URL,parameters,error);
        }
        
    }];
    sessionTask ? [[self xw_allSessionTask] addObject:sessionTask] : nil;
    return sessionTask;
}


#pragma mark 上传单张/多张图片
+ (NSURLSessionTask *)uploadImagesWithURL:(NSString *)URL
                               parameters:(id)parameters
                                     name:(NSString *)name
                                   images:(NSArray<UIImage *> *)images
                                fileNames:(NSArray<NSString *> *)fileNames
                               imageScale:(CGFloat)imageScale
                                imageType:(NSString *)imageType
                                 progress:(XWHttpProgress)progress
                                  success:(XWHttpRequestSuccess)success
                                  failure:(XWHttpRequestFailed)failure {
    NSURLSessionTask *sessionTask = [xw_sessionManager POST:URL parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        for (NSUInteger i = 0; i < images.count; i++) {
            NSData *imageData = UIImageJPEGRepresentation(images[i], imageScale ?: 1.0f);
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmmss";
            NSString *dataStr = [formatter stringFromDate:[NSDate date]];
            NSString *imageFileName = XWNSStringFormat(@"%@%ld.%@",dataStr,i,imageType?:@"jpg");
            
            /// 存储路径默认时间戳加序号,若外部定义则使用定义的文件路径
            if (fileNames && fileNames.count == images.count && imageType) {
                imageFileName = XWNSStringFormat(@"%@.%@",fileNames[i],imageType);
            }
            
            [formData appendPartWithFileData:imageData name:name fileName:imageFileName mimeType:XWNSStringFormat(@"image/%@",imageType ?: @"jpg")];
        }
        
    } progress:^(NSProgress * _Nonnull downloadProgress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            progress ? progress(downloadProgress) : nil;
        });
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [[self xw_allSessionTask] removeObject:task];
        success ? success(responseObject) : nil;
        responseObject != nil ? [XWNetworkHelperCache setHttpCache:responseObject URL:URL parameters:parameters] : nil;
        if (xw_isOpenLog) {
            XWNetLog(@"success -> url:%@ -> param:%@ -> responseObject:%@",URL,parameters,responseObject);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [[self xw_allSessionTask] removeObject:task];
        failure ? failure(error) : nil;
        if (xw_isOpenLog) {
            XWNetLog(@"error -> url:%@ -> param:%@ -> error:%@",URL,parameters,error);
        }
        
    }];
    sessionTask ? [[self xw_allSessionTask] addObject:sessionTask] : nil;
    return sessionTask;
}

#pragma mark 下载
+ (NSURLSessionTask *)downloadWithURL:(NSString *)URL
                              fileDir:(NSString *)fileDir
                             progress:(XWHttpProgress)progress
                              success:(void(^)(NSString *))success
                              failure:(XWHttpRequestFailed)failure {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URL]];
    __block NSURLSessionDownloadTask *downloadTask = [xw_sessionManager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            progress ? progress(downloadProgress) : nil;
        });
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        NSString *downloadSaveFileStr = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:fileDir ?: @"XWDownloder"];
        [[NSFileManager defaultManager] createDirectoryAtPath:downloadSaveFileStr withIntermediateDirectories:YES attributes:nil error:nil];
        NSString *filePath = [downloadSaveFileStr stringByAppendingPathComponent:response.suggestedFilename];
        return [NSURL URLWithString:filePath];
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        [[self xw_allSessionTask] removeObject:downloadTask];
        if (error) {
            failure ? failure(error) : nil;
            if (xw_isOpenLog) {
                XWNetLog(@"error -> url:%@ -> fileDir:%@ -> error:%@",URL,fileDir,error);
            }
        }else{
            success ? success(filePath.absoluteString) : nil;
            if (xw_isOpenLog) {
                XWNetLog(@"success -> url:%@ -> fileDir:%@",URL,fileDir);
            }
        }
        
    }];
    [downloadTask resume];
    downloadTask ? [[self xw_allSessionTask] addObject:downloadTask] : nil;
    return downloadTask;
}


#pragma mark - 设置AFHTTPSessionManager相关属性
#pragma mark 注意: 因为全局只有一个AFHTTPSessionManager实例,所以以下设置方式全局生效
/**
 在开发中,如果以下的设置方式不满足项目的需求,就调用此方法获取AFHTTPSessionManager实例进行自定义设置
 (注意: 调用此方法时在要导入AFNetworking.h头文件,否则可能会报找不到AFHTTPSessionManager的❌)
 @param sessionManager AFHTTPSessionManager的实例
 */
+ (void)setAFHTTPSessionManagerProperty:(void(^)(AFHTTPSessionManager *sessionManager))sessionManager {
    xw_sessionManager ? sessionManager(xw_sessionManager) : nil;
}

/**
 *  设置网络请求参数的格式:默认为二进制格式
 *
 *  @param requestSerializer XWRequestSerializerJSON(JSON格式),XWRequestSerializerHTTP(二进制格式),
 */
+ (void)setRequestSerializer:(XWRequestSerializer)requestSerializer {
    xw_sessionManager.requestSerializer = requestSerializer == XWRequestSerializerHTTP ? [AFHTTPRequestSerializer serializer] : [AFJSONRequestSerializer serializer];
}

/**
 *  设置服务器响应数据格式:默认为JSON格式
 *
 *  @param responseSerializer XWResponseSerializerJSON(JSON格式),XWResponseSerializerHTTP(二进制格式)
 */
+ (void)setResponseSerializer:(XWResponseSerializer)responseSerializer {
    xw_sessionManager.responseSerializer = responseSerializer == XWResponseSerializerHTTP ? [AFHTTPResponseSerializer serializer] : [AFJSONResponseSerializer serializer];
}

/**
 *  设置请求超时时间:默认为30S
 *
 *  @param time 时长
 */
+ (void)setRequestTimeoutInterval:(NSTimeInterval)time {
    xw_sessionManager.requestSerializer.timeoutInterval = time;
}

/// 设置请求头
+ (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    [xw_sessionManager.requestSerializer setValue:value forHTTPHeaderField:field];
}

/**
 *  是否打开网络状态转圈菊花:默认打开
 *
 *  @param open YES(打开), NO(关闭)
 */
+ (void)openNetworkActivityIndicator:(BOOL)open {
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:open];
}

/**
 配置自建证书的Https请求, 参考链接: http://blog.csdn.net/syg90178aw/article/details/52839103
 
 @param cerPath 自建Https证书的路径
 @param validatesDomainName 是否需要验证域名，默认为YES. 如果证书的域名与请求的域名不一致，需设置为NO; 即服务器使用其他可信任机构颁发
 的证书，也可以建立连接，这个非常危险, 建议打开.validatesDomainName=NO, 主要用于这种情况:客户端请求的是子域名, 而证书上的是另外
 一个域名。因为SSL证书上的域名是独立的,假如证书上注册的域名是www.google.com, 那么mail.google.com是无法验证通过的.
 */
+ (void)setSecurityPolicyWithCerPath:(NSString *)cerPath validatesDomainName:(BOOL)validatesDomainName {
    NSData *cerData = [NSData dataWithContentsOfFile:cerPath];
    // 使用证书验证模式
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    // 如果需要验证自建证书(无效证书)，需要设置为YES
    securityPolicy.allowInvalidCertificates = YES;
    // 是否需要验证域名，默认为YES;
    securityPolicy.validatesDomainName = validatesDomainName;
    securityPolicy.pinnedCertificates = [[NSSet alloc] initWithObjects:cerData, nil];
    
    [xw_sessionManager setSecurityPolicy:securityPolicy];
}


#pragma mark - getter
+ (NSMutableArray <NSURLSessionTask *>*)xw_allSessionTask {
    if(!xw_allSessionTask){
        xw_allSessionTask = [[NSMutableArray alloc] init];
    }
    return xw_allSessionTask;
}

#pragma mark - 全局请求单例属性
+ (void)load {
    [super load];
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}

+ (void)initialize {
    [super initialize];
    if (!xw_sessionManager) {
        xw_sessionManager = [AFHTTPSessionManager manager];
        xw_sessionManager.requestSerializer.timeoutInterval = 30.0;
        xw_sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/plain", @"text/javascript", @"text/xml", @"image/*", nil];
        [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;//状态栏等待菊花
    }
}

@end

//********************************************************************************************
#pragma mark - 缓存相关
@implementation XWNetworkHelperCache
static NSString *const kXWNetworkHelperCacheName = @"kXWNetworkHelperCacheName";
static YYCache *xw_dataCache;

#pragma mark - system
+ (void)initialize {
    [super initialize];
    xw_dataCache = [YYCache cacheWithName:kXWNetworkHelperCacheName];
}

#pragma mark - public
+ (void)setHttpCache:(id)httpData URL:(NSString *)URL parameters:(NSDictionary *)paramters {
    [xw_dataCache setObject:httpData forKey:[self cacheKeyWithURL:URL parameters:paramters] withBlock:nil];
}

+ (id)httpCacheWithURL:(NSString *)URL paramters:(NSDictionary *)paramters {
    return [xw_dataCache objectForKey:[self cacheKeyWithURL:URL parameters:paramters]];
}

+ (NSUInteger)getAllHttpCacheSize {
    return [xw_dataCache.diskCache totalCost];
}

+ (void)removeAllHttpCache {
    [xw_dataCache removeAllObjects];
}

#pragma mark - private
+ (NSString *)cacheKeyWithURL:(NSString *)URL parameters:(NSDictionary *)paramters {
    if (!paramters || paramters.count == 0) {
        return URL;
    }
    NSData *paramterData = [NSJSONSerialization dataWithJSONObject:paramters options:0 error:nil];
    NSString *paramterStr = [[NSString alloc] initWithData:paramterData encoding:NSUTF8StringEncoding];
    return [NSString stringWithFormat:@"%@%@",URL,paramterStr];
}

@end


#pragma mark - NSDictionary,NSArray的分类
/*
 ************************************************************************************
 *新建NSDictionary与NSArray的分类, 控制台打印json数据中的中文
 ************************************************************************************
 */

#ifdef DEBUG
@implementation NSArray (XWNetworkHelper)

- (NSString *)descriptionWithLocale:(id)locale {
    NSMutableString *strM = [NSMutableString stringWithString:@"(\n"];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [strM appendFormat:@"\t%@,\n", obj];
    }];
    [strM appendString:@")"];
    
    return strM;
}

@end

@implementation NSDictionary (XWNetworkHelper)

- (NSString *)descriptionWithLocale:(id)locale {
    NSMutableString *strM = [NSMutableString stringWithString:@"{\n"];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [strM appendFormat:@"\t%@ = %@;\n", key, obj];
    }];
    
    [strM appendString:@"}\n"];
    
    return strM;
}
@end
#endif
