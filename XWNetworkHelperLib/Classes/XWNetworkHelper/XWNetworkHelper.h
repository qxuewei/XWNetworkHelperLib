//
//  XWNetworkHelper.h
//  XWNetworkHelperDemo
//
//  Created by 邱学伟 on 2018/2/24.
//  Copyright © 2018年 邱学伟. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class AFHTTPSessionManager;

#pragma mark - 枚举
typedef NS_ENUM(NSUInteger, XWNetworkStatusType) {
    XWNetworkStatusTypeUnknown      = 0,        //未知网络
    XWNetworkStatusTypeNotReachable = 1 << 0,   //无网络
    XWNetworkStatusTypeReachableWWAN= 1 << 1,   //手机网络
    XWNetworkStatusTypeReachableWifi= 1 << 2    //WiFi网络
};

typedef NS_ENUM(NSUInteger, XWRequestSerializer) {
    XWRequestSerializerJSON = 0,                 /// 设置请求数据为JSON格式
    XWRequestSerializerHTTP = 1 << 0,            /// 设置请求数据为二进制格式
};

typedef NS_ENUM(NSUInteger, XWResponseSerializer) {
    XWResponseSerializerJSON = 0,                /// 设置响应数据为JSON格式
    XWResponseSerializerHTTP = 1 << 0,           /// 设置响应数据为二进制格式
};

#pragma mark - 回调
/// 网络状态
typedef void(^XWNetworkStatus)(XWNetworkStatusType networkStatus);

/// 请求成功回调
typedef void(^XWHttpRequestSuccess)(id responseObject);

/// 请求成功回调 responseObject:服务端返回最新数据, allHeaderFields: Header
typedef void(^XWHttpRequestHeaderSuccess)(id responseObject, NSDictionary *allHeaderFields);

/// 请求失败回调
typedef void(^XWHttpRequestFailed)(NSError *error, NSInteger code, NSString *message);

/// 缓存的数据
typedef void(^XWHttpRequestCache)(id responseObject);

/// 上传或者下载的进度, progress.completedUnitCount:当前大小 - progress.totalUnitCount:总大小
typedef void(^XWHttpProgress)(NSProgress *progress);

#ifndef kIsNetwork
#define kIsNetwork     [XWNetworkHelper isNetwork]  // 一次性判断是否有网的宏
#endif

#ifndef kIsWWANNetwork
#define kIsWWANNetwork [XWNetworkHelper isWWANNetwork]  // 一次性判断是否为手机网络的宏
#endif

#ifndef kIsWiFiNetwork
#define kIsWiFiNetwork [XWNetworkHelper isWiFiNetwork]  // 一次性判断是否为WiFi网络的宏
#endif

@interface XWNetworkHelper : NSObject

/// 有网YES, 无网:NO
+ (BOOL)isNetwork;

/// 手机网络:YES, 反之:NO
+ (BOOL)isWWANNetwork;

/// WiFi网络:YES, 反之:NO
+ (BOOL)isWiFiNetwork;

/// 取消所有HTTP请求
+ (void)cancelAllRequest;

/// 实时获取网络状态,通过Block回调实时获取(此方法可多次调用)
+ (void)networkStatusWithBlock:(XWNetworkStatus)networkStatus;

/// 取消指定URL的HTTP请求
+ (void)cancelRequestWithURL:(NSString *)URL;

/// 开启日志打印 (Debug级别)
+ (void)openLog;

/// 关闭日志打印,默认关闭
+ (void)closeLog;

#pragma mark Get 请求
/**
 Get 无缓存
 */
+ (__kindof NSURLSessionTask *)GET:(NSString *)URL
                        parameters:(NSDictionary *)parameters
                           success:(XWHttpRequestSuccess)success
                           failure:(XWHttpRequestFailed)failure;

/**
 Get 自动缓存
 */
+ (__kindof NSURLSessionTask *)GET:(NSString *)URL
                        parameters:(NSDictionary *)parameters
                     responseCache:(XWHttpRequestCache)responseCache
                           success:(XWHttpRequestSuccess)success
                           failure:(XWHttpRequestFailed)failure;

/**
 Get 自动缓存 - 指定缓存参数
 */
+ (__kindof NSURLSessionTask *)GET:(NSString *)URL
                        parameters:(NSDictionary *)parameters
                   cacheParameters:(NSDictionary *)cacheParameters
                     responseCache:(XWHttpRequestCache)responseCache
                           success:(XWHttpRequestSuccess)success
                           failure:(XWHttpRequestFailed)failure;

#pragma mark POST 请求
/**
 POST 无缓存
 */
+ (__kindof NSURLSessionTask *)POST:(NSString *)URL
                         parameters:(NSDictionary *)parameters
                            success:(XWHttpRequestSuccess)success
                            failure:(XWHttpRequestFailed)failure;

/**
 POST 无缓存  成功回调 (包含 header)
 */
+ (__kindof NSURLSessionTask *)POST:(NSString *)URL
                         parameters:(NSDictionary *)parameters
                  successWithHeader:(XWHttpRequestHeaderSuccess)successWithHeader
                            failure:(XWHttpRequestFailed)failure;

/**
 POST 自动缓存
 */
+ (__kindof NSURLSessionTask *)POST:(NSString *)URL
                         parameters:(NSDictionary *)parameters
                      responseCache:(XWHttpRequestCache)responseCache
                            success:(XWHttpRequestSuccess)success
                            failure:(XWHttpRequestFailed)failure;

/**
 POST 自动缓存 - 指定缓存参数
 */
+ (__kindof NSURLSessionTask *)POST:(NSString *)URL
                         parameters:(NSDictionary *)parameters
                    cacheParameters:(NSDictionary *)cacheParameters
                      responseCache:(XWHttpRequestCache)responseCache
                            success:(XWHttpRequestSuccess)success
                            failure:(XWHttpRequestFailed)failure;

#pragma mark PUT
+ (__kindof NSURLSessionTask *)PUT:(NSString *)URL
                        parameters:(NSDictionary *)parameters
                           success:(XWHttpRequestSuccess)success
                           failure:(XWHttpRequestFailed)failure;

#pragma mark DELETE
+ (__kindof NSURLSessionTask *)DELETE:(NSString *)URL
                           parameters:(NSDictionary *)parameters
                              success:(XWHttpRequestSuccess)success
                              failure:(XWHttpRequestFailed)failure;

#pragma mark 上传
/**
 上次单个文件

 @param URL 请求地址
 @param parameters 参数
 @param name 文件存储在服务端名称
 @param filePath 所上传文件本地沙盒路径
 @param progress 进度
 @param success 成功回调
 @param failure 失败回调
 @return 请求对象
 */
+ (NSURLSessionTask *)uploadFileWithURL:(NSString *)URL
                             parameters:(id)parameters
                                   name:(NSString *)name
                               filePath:(NSString *)filePath
                               progress:(XWHttpProgress)progress
                                success:(XWHttpRequestSuccess)success
                                failure:(XWHttpRequestFailed)failure;

/**
 上传单张/多张图片

 @param URL 请求路径
 @param parameters 参数
 @param name 文件存储在服务端对应名称
 @param images 所上传图片数组
 @param fileNames 图文件名数组,可以为nil, 数组内的文件名默认为当前日期时间"yyyyMMddHHmmss"
 @param imageScale 图片文件压缩比 范围 (0.f ~ 1.f)
 @param imageType 图片文件的类型,例:png、jpg(默认类型)....
 @param progress 进度
 @param success 成功回调
 @param failure 失败回调
 @return 请求对象
 */
+ (NSURLSessionTask *)uploadImagesWithURL:(NSString *)URL
                               parameters:(id)parameters
                                     name:(NSString *)name
                                   images:(NSArray<UIImage *> *)images
                                fileNames:(NSArray<NSString *> *)fileNames
                               imageScale:(CGFloat)imageScale
                                imageType:(NSString *)imageType
                                 progress:(XWHttpProgress)progress
                                  success:(XWHttpRequestSuccess)success
                                  failure:(XWHttpRequestFailed)failure;

#pragma mark 下载

/**
 下载文件

 @param URL 请求路径
 @param fileDir 文件存储目录(默认存储目录为XWDownload)
 @param progress 进度
 @param success 成功回调
 @param failure 失败回调
 @return 下载对象
 */
+ (NSURLSessionTask *)downloadWithURL:(NSString *)URL
                              fileDir:(NSString *)fileDir
                             progress:(XWHttpProgress)progress
                              success:(void(^)(NSString *))success
                              failure:(XWHttpRequestFailed)failure;


#pragma mark - 设置AFHTTPSessionManager相关属性
#pragma mark 注意: 因为全局只有一个AFHTTPSessionManager实例,所以以下设置方式全局生效
/**
 在开发中,如果以下的设置方式不满足项目的需求,就调用此方法获取AFHTTPSessionManager实例进行自定义设置
 (注意: 调用此方法时在要导入AFNetworking.h头文件,否则可能会报找不到AFHTTPSessionManager的❌)
 @param sessionManager AFHTTPSessionManager的实例
 */
+ (void)setAFHTTPSessionManagerProperty:(void(^)(AFHTTPSessionManager *sessionManager))sessionManager;

/**
 *  设置网络请求参数的格式:默认为二进制格式
 *
 *  @param requestSerializer XWRequestSerializerJSON(JSON格式),XWRequestSerializerHTTP(二进制格式),
 */
+ (void)setRequestSerializer:(XWRequestSerializer)requestSerializer;

/**
 *  设置服务器响应数据格式:默认为JSON格式
 *
 *  @param responseSerializer XWResponseSerializerJSON(JSON格式),XWResponseSerializerHTTP(二进制格式)
 */
+ (void)setResponseSerializer:(XWResponseSerializer)responseSerializer;

/**
 *  设置请求超时时间:默认为30S
 *
 *  @param time 时长
 */
+ (void)setRequestTimeoutInterval:(NSTimeInterval)time;

/// 设置请求头
+ (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;

/**
 *  是否打开网络状态转圈菊花:默认打开
 *
 *  @param open YES(打开), NO(关闭)
 */
+ (void)openNetworkActivityIndicator:(BOOL)open;

/// 移除AuthorizationHeader - Clears any existing value for the "Authorization" HTTP header.
+ (void)clearAuthorizationHeader;

/**
 配置自建证书的Https请求, 参考链接: http://blog.csdn.net/syg90178aw/article/details/52839103
 
 @param cerPath 自建Https证书的路径
 @param validatesDomainName 是否需要验证域名，默认为YES. 如果证书的域名与请求的域名不一致，需设置为NO; 即服务器使用其他可信任机构颁发
 的证书，也可以建立连接，这个非常危险, 建议打开.validatesDomainName=NO, 主要用于这种情况:客户端请求的是子域名, 而证书上的是另外
 一个域名。因为SSL证书上的域名是独立的,假如证书上注册的域名是www.google.com, 那么mail.google.com是无法验证通过的.
 */
+ (void)setSecurityPolicyWithCerPath:(NSString *)cerPath validatesDomainName:(BOOL)validatesDomainName;

@end
