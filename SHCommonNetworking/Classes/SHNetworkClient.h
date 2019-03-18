//
//  SHNetworkClient.h
//  SHNetworking
//
//  Created by 张世豪 on 2019/3/16.
//

#import "AFNetworking.h"
#import "SHNetworkReachability.h"
#import "SHNetworkRequest.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^SHNetworkRequestSuccess)(id responseObject, BOOL isCache);
typedef void(^SHNetworkRequestFailure)(id responseObject, NSError *error);

@interface SHNetworkClient : NSObject

/**
 *  AFHTTPSessionManager 实例
 */
@property (nonatomic, readonly) AFHTTPSessionManager *sessionManager;

@property (nonatomic, readonly) SHNetworkReachability *networkReachablity;

/* default timeout for requests. default:20s */
@property (nonatomic, assign) NSTimeInterval timeoutIntervalForRequest;

/* default timeout for requests. default:20s */
@property (nonatomic, assign) NSTimeInterval timeoutIntervalForResource;
// 全局配置
@property (nonatomic, strong) id<SHNetworkPathReformer> pathReformer;
@property (nonatomic, strong) id<SHNetworkParameterReformer> parameterReformer;
@property (nonatomic, strong) id<SHNetworkResponseReformer> responseReformer;
@property (nonatomic, strong) id<SHNetworkCacheHandler> cacheHandler;
@property (nonatomic, strong) id<SHNetworkErrorHandler> errorHandler;
@property (nonatomic, strong) id<SHNetworkAPIErrorHandler> APIErrorHandler;

/**
 *  获取 SHNetworkClient 实例
 *
 *  @return SHNetworkClient 实例, 此方法返回单例
 */
+ (SHNetworkClient *)defaultClient;

/**
 直接传参请求数据
 @param path 请求地址
 @param param 参数
 @param reformClass 转换Model 的class
 @param success 成功回调
 @param failure 失败回调
 */
- (void)requestWithPath:(NSString *)path param:(id)param reformClass:(Class)reformClass success:(SHNetworkRequestSuccess)success failure:(SHNetworkRequestFailure)failure;


/**
 
 @param path path
 @param param 参数
 @param reformClass 转换 Model 的 class
 @param JSONValidater 校验回调数据
 @param cacheKey 缓存key
 @param success 成功回调
 @param failure 失败回调
 */
- (void)requestWithPath:(NSString *)path param:(id)param reformClass:(Class)reformClass JSONValidater:(id _Nullable)JSONValidater cacheKey:(NSString *)cacheKey success:(SHNetworkRequestSuccess)success failure:(SHNetworkRequestFailure)failure;

/**
 通过 SHBaseRequest 作为参数发送请求
 
 @param request SHBaseRequest 实例
 @param success 成功回调
 @param failure 失败回调
 */
- (void)sendRequest:(SHNetworkRequest *)request success:(SHNetworkRequestSuccess)success failure:(SHNetworkRequestFailure)failure;

/**
 通过SHBaseRequest 下载
 
 @param request SHBaseRequest 实例
 @param completionHandler 下载完成回调
 */

/**
 通过SHBaseRequest 下载

 @param path path
 @param downloadProgressBlock 进度回调
 @param destination destination
 @param completionHandler 完成回调
 @return task
 */
- (NSURLSessionDownloadTask *)downloadWithPath:(NSString *)path
                                      progress:(void (^)(NSProgress *))downloadProgressBlock
                                   destination:(NSURL *(^)(NSURL *, NSURLResponse *))destination
                             completionHandler:(void (^)(NSURLResponse *, NSURL *, NSError *))completionHandler;


/**
 *  取消某路径下所有请求
 *
 *  @param path 地址
 */
- (void)cancelRequestsForPath:(NSString *)path;

/**
 取消所有请求
 */
- (void)cancelAllRequests;



@end

NS_ASSUME_NONNULL_END
