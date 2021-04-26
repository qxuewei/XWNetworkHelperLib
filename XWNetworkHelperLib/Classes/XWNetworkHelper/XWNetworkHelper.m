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
#import "XWSafeMutableArray.h"

typedef NS_ENUM(NSUInteger, XWRequestMethod) {
    XWRequestMethodGet      =   0,
    XWRequestMethodPost     =   1,
    XWRequestMethodPut      =   2,
    XWRequestMethodDelete   =   3,
    XWRequestMethodPatch    =   4,
    XWRequestMethodHead     =   5,
};

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
static XWSafeMutableArray *xw_allSessionTask;
static AFHTTPSessionManager *xw_sessionManager;
static NSDictionary *xw_networkGlobalHeader;
static NSDateFormatter *xw_networkDateFormatter;

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
/**
 Get 无缓存
 */
+ (__kindof NSURLSessionTask *)GET:(NSString *)URL
                        parameters:(NSDictionary *)parameters
                           success:(XWHttpRequestSuccess)success
                           failure:(XWHttpRequestFailed)failure {
    return [self xw_requestWithURL:URL method:XWRequestMethodGet parameters:parameters cacheParameters:nil headers:nil responseCache:nil success:success successWithHeader:nil failure:failure];
    
}

/**
 Get 无缓存 (自定义Header)
 */
+ (__kindof NSURLSessionTask *)GET:(NSString *)URL
                        parameters:(NSDictionary *)parameters
                           headers:(NSDictionary *)headers
                           success:(XWHttpRequestSuccess)success
                           failure:(XWHttpRequestFailed)failure {
    return [self xw_requestWithURL:URL method:XWRequestMethodGet parameters:parameters cacheParameters:nil headers:headers responseCache:nil success:success successWithHeader:nil failure:failure];
    
}

/**
 Get 自动缓存
 */
+ (__kindof NSURLSessionTask *)GET:(NSString *)URL
                        parameters:(NSDictionary *)parameters
                     responseCache:(XWHttpRequestCache)responseCache
                           success:(XWHttpRequestSuccess)success
                           failure:(XWHttpRequestFailed)failure {
    return [self xw_requestWithURL:URL method:XWRequestMethodGet parameters:parameters cacheParameters:nil headers:nil responseCache:responseCache success:success successWithHeader:nil failure:failure];
    
}

/**
 Get 自动缓存  (自定义Header)
 */
+ (__kindof NSURLSessionTask *)GET:(NSString *)URL
                        parameters:(NSDictionary *)parameters
                           headers:(NSDictionary *)headers
                     responseCache:(XWHttpRequestCache)responseCache
                           success:(XWHttpRequestSuccess)success
                           failure:(XWHttpRequestFailed)failure {
    return [self xw_requestWithURL:URL method:XWRequestMethodGet parameters:parameters cacheParameters:nil headers:headers responseCache:responseCache success:success successWithHeader:nil failure:failure];
    
}

/**
 Get 自动缓存 - 指定缓存参数
 */
+ (__kindof NSURLSessionTask *)GET:(NSString *)URL
                        parameters:(NSDictionary *)parameters
                   cacheParameters:(NSDictionary *)cacheParameters
                     responseCache:(XWHttpRequestCache)responseCache
                           success:(XWHttpRequestSuccess)success
                           failure:(XWHttpRequestFailed)failure {
    return [self xw_requestWithURL:URL method:XWRequestMethodGet parameters:parameters cacheParameters:cacheParameters headers:nil responseCache:responseCache success:success successWithHeader:nil failure:failure];
    
}


/**
 Get 自动缓存 - 指定缓存参数    (自定义Header)
 */
+ (__kindof NSURLSessionTask *)GET:(NSString *)URL
                        parameters:(NSDictionary *)parameters
                   cacheParameters:(NSDictionary *)cacheParameters
                           headers:(NSDictionary *)headers
                     responseCache:(XWHttpRequestCache)responseCache
                           success:(XWHttpRequestSuccess)success
                           failure:(XWHttpRequestFailed)failure {
    return [self xw_requestWithURL:URL method:XWRequestMethodGet parameters:parameters cacheParameters:cacheParameters headers:headers responseCache:responseCache success:success successWithHeader:nil failure:failure];
    
}

#pragma mark POST 请求
/**
 POST 无缓存
 */
+ (__kindof NSURLSessionTask *)POST:(NSString *)URL
                         parameters:(NSDictionary *)parameters
                            success:(XWHttpRequestSuccess)success
                            failure:(XWHttpRequestFailed)failure {
    return [self xw_requestWithURL:URL method:XWRequestMethodPost parameters:parameters cacheParameters:nil headers:nil responseCache:nil success:success successWithHeader:nil failure:failure];
    
}

/**
 POST 无缓存  (自定义Header)
 */
+ (__kindof NSURLSessionTask *)POST:(NSString *)URL
                         parameters:(NSDictionary *)parameters
                            headers:(NSDictionary *)headers
                            success:(XWHttpRequestSuccess)success
                            failure:(XWHttpRequestFailed)failure {
    return [self xw_requestWithURL:URL method:XWRequestMethodPost parameters:parameters cacheParameters:nil headers:headers responseCache:nil success:success successWithHeader:nil failure:failure];
    
}

/**
 POST 无缓存  成功回调 (返回值包含 header)
 */
+ (__kindof NSURLSessionTask *)POST:(NSString *)URL
                         parameters:(NSDictionary *)parameters
                  successWithHeader:(XWHttpRequestHeaderSuccess)successWithHeader
                            failure:(XWHttpRequestFailed)failure {
    return [self xw_requestWithURL:URL method:XWRequestMethodPost parameters:parameters cacheParameters:nil headers:nil responseCache:nil success:nil successWithHeader:successWithHeader failure:failure];
    
}

/**
 POST 无缓存  成功回调 (返回值包含 header)  (自定义Header)
 */
+ (__kindof NSURLSessionTask *)POST:(NSString *)URL
                         parameters:(NSDictionary *)parameters
                            headers:(NSDictionary *)headers
                  successWithHeader:(XWHttpRequestHeaderSuccess)successWithHeader
                            failure:(XWHttpRequestFailed)failure {
    return [self xw_requestWithURL:URL method:XWRequestMethodPost parameters:parameters cacheParameters:nil headers:headers responseCache:nil success:nil successWithHeader:successWithHeader failure:failure];
    
}

/**
 POST 自动缓存
 */
+ (__kindof NSURLSessionTask *)POST:(NSString *)URL
                         parameters:(NSDictionary *)parameters
                      responseCache:(XWHttpRequestCache)responseCache
                            success:(XWHttpRequestSuccess)success
                            failure:(XWHttpRequestFailed)failure {
    return [self xw_requestWithURL:URL method:XWRequestMethodPost parameters:parameters cacheParameters:nil headers:nil responseCache:responseCache success:success successWithHeader:nil failure:failure];
    
}

/**
 POST 自动缓存  (自定义Header)
 */
+ (__kindof NSURLSessionTask *)POST:(NSString *)URL
                         parameters:(NSDictionary *)parameters
                            headers:(NSDictionary *)headers
                      responseCache:(XWHttpRequestCache)responseCache
                            success:(XWHttpRequestSuccess)success
                            failure:(XWHttpRequestFailed)failure {
    return [self xw_requestWithURL:URL method:XWRequestMethodPost parameters:parameters cacheParameters:nil headers:headers responseCache:responseCache success:success successWithHeader:nil failure:failure];
    
}

/**
 POST 自动缓存 - 指定缓存参数
 */
+ (__kindof NSURLSessionTask *)POST:(NSString *)URL
                         parameters:(NSDictionary *)parameters
                    cacheParameters:(NSDictionary *)cacheParameters
                      responseCache:(XWHttpRequestCache)responseCache
                            success:(XWHttpRequestSuccess)success
                            failure:(XWHttpRequestFailed)failure {
    return [self xw_requestWithURL:URL method:XWRequestMethodPost parameters:parameters cacheParameters:cacheParameters headers:nil responseCache:responseCache success:success successWithHeader:nil failure:failure];
    
}

/**
 POST 自动缓存 - 指定缓存参数  (自定义Header)
 */
+ (__kindof NSURLSessionTask *)POST:(NSString *)URL
                         parameters:(NSDictionary *)parameters
                    cacheParameters:(NSDictionary *)cacheParameters
                            headers:(NSDictionary *)headers
                      responseCache:(XWHttpRequestCache)responseCache
                            success:(XWHttpRequestSuccess)success
                            failure:(XWHttpRequestFailed)failure {
    return [self xw_requestWithURL:URL method:XWRequestMethodPost parameters:parameters cacheParameters:cacheParameters headers:headers responseCache:responseCache success:success successWithHeader:nil failure:failure];
    
}

#pragma mark - PUT
/// PUT
/// @param URL URL
/// @param parameters 参数
/// @param success 成功
/// @param failure 失败
+ (__kindof NSURLSessionTask *)PUT:(NSString *)URL
                        parameters:(NSDictionary *)parameters
                           success:(XWHttpRequestSuccess)success
                           failure:(XWHttpRequestFailed)failure {
    return [self xw_requestWithURL:URL method:XWRequestMethodPut parameters:parameters cacheParameters:nil headers:nil responseCache:nil success:success successWithHeader:nil failure:failure];
}

/// PUT （自定义Header）
/// @param URL URL
/// @param parameters 参数
/// @param headers 自定义Header
/// @param success 成功
/// @param failure 失败
+ (__kindof NSURLSessionTask *)PUT:(NSString *)URL
                        parameters:(NSDictionary *)parameters
                           headers:(NSDictionary *)headers
                           success:(XWHttpRequestSuccess)success
                           failure:(XWHttpRequestFailed)failure {
    return [self xw_requestWithURL:URL method:XWRequestMethodPut parameters:parameters cacheParameters:nil headers:headers responseCache:nil success:success successWithHeader:nil failure:failure];
}

#pragma mark - DELETE

/// DELETE
/// @param URL URL
/// @param parameters 参数
/// @param success 成功
/// @param failure 失败
+ (__kindof NSURLSessionTask *)DELETE:(NSString *)URL
                           parameters:(NSDictionary *)parameters
                              success:(XWHttpRequestSuccess)success
                              failure:(XWHttpRequestFailed)failure {
    return [self xw_requestWithURL:URL method:XWRequestMethodDelete parameters:parameters cacheParameters:nil headers:nil responseCache:nil success:success successWithHeader:nil failure:failure];
}


/// DELETE
/// @param URL URL
/// @param parameters 参数
/// @param headers 自定义Header
/// @param success 成功
/// @param failure 失败
+ (__kindof NSURLSessionTask *)DELETE:(NSString *)URL
                           parameters:(NSDictionary *)parameters
                              headers:(NSDictionary *)headers
                              success:(XWHttpRequestSuccess)success
                              failure:(XWHttpRequestFailed)failure {
    return [self xw_requestWithURL:URL method:XWRequestMethodDelete parameters:parameters cacheParameters:nil headers:headers responseCache:nil success:success successWithHeader:nil failure:failure];
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
    NSURLSessionTask *sessionTask = [xw_sessionManager POST:URL parameters:parameters headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSError *error = nil;
        [formData appendPartWithFileURL:[NSURL URLWithString:filePath] name:name error:&error];
        ( failure && error ) ? failure(error,404,@"") : nil;
        
    } progress:^(NSProgress * _Nonnull downloadProgress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            progress ? progress(downloadProgress) : nil;
        });
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        success ? success(responseObject) : nil;
        [[self xw_allSessionTask] removeObject:task];
        responseObject != nil ? [XWNetworkHelperCache setHttpCache:responseObject URL:URL parameters:parameters] : nil;
        if (xw_isOpenLog) {
            XWNetLog(@"success -> url:%@ -> param:%@ -> responseObject:%@",URL,parameters,responseObject);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSInteger code = error.code;
        NSString *message = nil;
        NSData *data = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
        if (data) {
            NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (string) {
                NSData *jsonData = [string dataUsingEncoding:NSUTF8StringEncoding];
                NSError *err;
                NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
                message = responseObject[@"errorDescription"];
            }
        }
        failure ? failure(error,code,message) : nil;
        [[self xw_allSessionTask] removeObject:task];
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
    NSURLSessionTask *sessionTask = [xw_sessionManager POST:URL parameters:parameters headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        [images enumerateObjectsUsingBlock:^(UIImage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSData *imageData = UIImageJPEGRepresentation(obj, imageScale ?: 1.0f);
            NSString *imageFileName = [self imageFileNameIndex:idx imageType:imageType];
            if (fileNames && fileNames.count == images.count && imageType) {
                imageFileName = XWNSStringFormat(@"%@.%@",fileNames[idx],imageType);
            }
            [formData appendPartWithFileData:imageData name:name fileName:imageFileName mimeType:XWNSStringFormat(@"image/%@",imageType?:@"jpg")];
        }];
        
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
        NSInteger code = error.code;
        if ([task.response isKindOfClass:NSHTTPURLResponse.class]) {
            NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
            code = response.statusCode;
        }
        NSString *message = nil;
        NSData *data = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
        if (data) {
            NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (string) {
                NSData *jsonData = [string dataUsingEncoding:NSUTF8StringEncoding];
                NSError *err;
                NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
                message = responseObject[@"errorDescription"];
            }
        }
        failure ? failure(error,code,message) : nil;
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
                              success:(void(^)(NSString *filePath))success
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
            NSInteger errorCode = error.code;
            NSString *errorMessage = nil;
            failure ? failure(error,errorCode,errorMessage) : nil;
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

/// 设置全局 header
/// @param header header
+ (void)configGlobalHeader:(NSDictionary *)header {
    @synchronized (self) {
        xw_networkGlobalHeader = header;
    }
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
 移除AuthorizationHeader
 Clears any existing value for the "Authorization" HTTP header.
 */
+ (void)clearAuthorizationHeader {
    [xw_sessionManager.requestSerializer clearAuthorizationHeader];
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

#pragma mark - Private
/// 统一处理请求
+ (__kindof NSURLSessionTask *)xw_requestWithURL:(NSString *)URL
                                          method:(XWRequestMethod)method
                                      parameters:(NSDictionary *)parameters
                                 cacheParameters:(NSDictionary *)cacheParameters
                                         headers:(NSDictionary *)headers
                                   responseCache:(XWHttpRequestCache)responseCache
                                         success:(XWHttpRequestSuccess)success
                               successWithHeader:(XWHttpRequestHeaderSuccess)successWithHeader
                                         failure:(XWHttpRequestFailed)failure {
    if (responseCache) {
        /// 若需缓存先回调缓存数据
        if (cacheParameters) {
            responseCache([XWNetworkHelperCache httpCacheWithURL:[URL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]] paramters:cacheParameters]);
        }else{
            responseCache([XWNetworkHelperCache httpCacheWithURL:[URL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]] paramters:parameters]);
        }
    }
    
    NSURLSessionTask *sessionTask = [self xw_sessionTasktWithURL:[URL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]] method:method parameters:parameters headers:headers success:^(NSURLSessionDataTask *task, id  _Nullable responseObject) {
        success ? success(responseObject) : nil;
        if (successWithHeader) {
            if ([task.response isKindOfClass:NSHTTPURLResponse.class]) {
                NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
                NSDictionary *allHeaderFields = response.allHeaderFields;
                successWithHeader ? successWithHeader(responseObject,allHeaderFields) : nil;
            }
        }
        if (responseCache && responseObject) {
            if (cacheParameters) {
                [XWNetworkHelperCache setHttpCache:responseObject URL:URL parameters:cacheParameters];
            }else{
                [XWNetworkHelperCache setHttpCache:responseObject URL:URL parameters:parameters];
            }
        }
        if (xw_isOpenLog) {
            XWNetLog(@"*****  success -> method:%@ -> url:%@ -> param:%@ -> responseObject:%@",[self requestMethodWithType:method],URL,parameters,responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSInteger code = NSIntegerMax;
        NSString *message = nil;
        NSDictionary *responseObject;
        NSData *data = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
        if (data) {
            NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (string) {
                NSData *jsonData = [string dataUsingEncoding:NSUTF8StringEncoding];
                NSError *err;
                responseObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
                message = responseObject[@"msg"];
                code = [responseObject[@"code"] integerValue];
            }
        }
        failure ? failure(error,code,message) : nil;
        if (xw_isOpenLog) {
            XWNetLog(@"error -> method:%@ -> url:%@ -> param:%@ -> errorObject:%@-> error:%@",[self requestMethodWithType:method],URL,parameters,responseObject,error);
        }
    }];
    sessionTask ? [[self xw_allSessionTask] addObject:sessionTask] : nil;
    return sessionTask;
}

/// 包装 AFN 请求类
+ (NSURLSessionTask *)xw_sessionTasktWithURL:(NSString *)URL
                                      method:(XWRequestMethod)method
                                  parameters:(NSDictionary *)parameters
                                     headers:(NSDictionary *)headers
                                     success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                                     failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure {
    NSURLSessionTask *sessionTask;
    switch (method) {
        case XWRequestMethodGet:
            sessionTask = [xw_sessionManager GET:URL parameters:parameters headers: headers ?: xw_networkGlobalHeader progress:nil success:success failure:failure];
            break;

        case XWRequestMethodPost:
            sessionTask = [xw_sessionManager POST:URL parameters:parameters headers:headers ?: xw_networkGlobalHeader progress:nil success:success failure:failure];
            break;

        case XWRequestMethodPut:
            sessionTask = [xw_sessionManager PUT:URL parameters:parameters headers:headers ?: xw_networkGlobalHeader success:success failure:failure];
            break;

        case XWRequestMethodDelete:
            sessionTask = [xw_sessionManager DELETE:URL parameters:parameters headers:headers ?: xw_networkGlobalHeader success:success failure:failure];
            break;

        case XWRequestMethodPatch:
            sessionTask = [xw_sessionManager PATCH:URL parameters:parameters headers:headers ?: xw_networkGlobalHeader success:success failure:failure];
            break;
            
        case XWRequestMethodHead:
            sessionTask = [xw_sessionManager HEAD:URL parameters:parameters headers:headers ?: xw_networkGlobalHeader success:^(NSURLSessionDataTask * _Nonnull task) {
                success(task, nil);
            } failure:failure];
            break;
    }
    return sessionTask;
}

/// 上传文件名
+ (NSString *)imageFileNameIndex:(NSUInteger)index imageType:(NSString *)imageType {
    NSString *dateStr = [[self xw_networkDateFormatter] stringFromDate:[NSDate date]];
    return XWNSStringFormat(@"%@%lu.%@",dateStr,(unsigned long)index,imageType?:@"jpg");
}

+ (NSString *)requestMethodWithType:(XWRequestMethod)type {
    switch (type) {
        case XWRequestMethodGet:
            return @"GET";
        case XWRequestMethodPost:
            return @"POST";
        case XWRequestMethodPut:
            return @"PUT";
        case XWRequestMethodDelete:
            return @"DELETE";
        case XWRequestMethodPatch:
            return @"PATCH";
        case XWRequestMethodHead:
            return @"HEAD";
        default:
            return @"UNKNOWN";
    }
}

#pragma mark - getter
+ (XWSafeMutableArray *)xw_allSessionTask {
    if(!xw_allSessionTask){
        xw_allSessionTask = [[XWSafeMutableArray alloc] init];
    }
    return xw_allSessionTask;
}
+ (NSDateFormatter *)xw_networkDateFormatter {
    if (!xw_networkDateFormatter) {
        xw_networkDateFormatter = [[NSDateFormatter alloc] init];
        xw_networkDateFormatter.dateFormat = @"yyyyMMddHHmmss";
    }
    return xw_networkDateFormatter;
}

#pragma mark - 全局请求单例属性
+ (void)load {
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}

+ (void)initialize {
    if (!xw_sessionManager) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            xw_sessionManager = [AFHTTPSessionManager manager];
            xw_sessionManager.requestSerializer.timeoutInterval = 30.0;
            xw_sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
            xw_sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/plain", @"text/javascript", @"text/xml", @"image/*", nil];
            [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;//状态栏等待菊花
        });
    }
}
@end

//********************************************************************************************
#pragma mark - 缓存相关
@implementation XWNetworkHelperCache
static NSString *const kXWNetworkHelperCacheName = @"kXWNetworkHelperCacheName";
static YYCache *xw_dataCache;

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

#pragma mark - system
+ (void)initialize {
    xw_dataCache = [YYCache cacheWithName:kXWNetworkHelperCacheName];
}

#pragma mark - private
+ (NSString *)cacheKeyWithURL:(NSString *)URL parameters:(NSDictionary *)paramters {
    if (!paramters || paramters.count == 0) {
        return URL;
    }
    NSData *paramterData = [NSJSONSerialization dataWithJSONObject:paramters options:0 error:nil];
    NSString *paramterStr = [[NSString alloc] initWithData:paramterData encoding:NSUTF8StringEncoding];
    return [NSString stringWithFormat:@"%@>_<%@",URL,paramterStr];
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
