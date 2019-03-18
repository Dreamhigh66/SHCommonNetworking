//
//  SHNetworkRequest.h
//  SHNetworking
//
//  Created by 张世豪 on 2019/3/11.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SHNetworkErrorCode) {
    SHNetworkErrorNoCache = -1L,
    SHNetworkErrorCacheFormatInvalidate = -2L,
    SHNetworkErrorNoErrorCode = -3L,
    SHNetworkErrorResponseFormatInvalidate = -4L,
    SHNetworkErrorNoNetworking = -5L,
    SHNetworkErrorServerUnReachablility = -6L,
    SHNetworkErrorRequestCancel = -7L
};

typedef void(^SHNetworkConstructingBodyBlock)(id <AFMultipartFormData> formData);
typedef void(^SHNetworkProgress)(NSProgress *progress);
typedef NSURL *(^SHNetworkDownloadDestination)(NSURL *targetPath, NSURLResponse *response);

@class SHNetworkRequest;

@protocol SHNetworkPathReformer <NSObject>
    
- (NSString *)pathReform:(NSString *)path request:(SHNetworkRequest *)request;
    
@end

@protocol SHNetworkParameterReformer <NSObject>

- (NSDictionary *)parametersReform:(id)params request:(SHNetworkRequest *)request;

@end

@protocol SHNetworkResponseReformer <NSObject>

- (id)responseReform:(id)response reformClass:(Class)reformClass request:(SHNetworkRequest *)request;

@end

@protocol SHNetworkCacheHandler <NSObject>

- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key;

- (id<NSCoding>)objectForKey:(NSString *)key;

@end

@protocol SHNetworkErrorHandler <NSObject>

- (NSError *)errorWithSHNetworkErrorCode:(SHNetworkErrorCode)errorCode request:(SHNetworkRequest *)request;

/**
 如果因为网络问题或其他问题造成没有数据返回，可以在这个方法中创建带有错误信息的 ResponseObject 来返回给调用者，主要目的是为了可能有些人在判断错误时使用的是 ResponseObject 中的信息， 如果统一使用返回的 error 参数来判断则不需要实现该方法
 
 @param error
 @return
 */

@optional
- (id)responseObjectWithError:(NSError *)error request:(SHNetworkRequest *)request;

@end

@protocol SHNetworkAPIErrorHandler <NSObject>

// 判断 API 数据是否有error，不要在此方法中修改 UI
- (NSError *)APIErrorCodeValidated:(id)responseObject request:(SHNetworkRequest *)request;

// 全局处理error，配置在FNNetClient 中使用的话，可以拦截所有请求失败的error，可以用来统一处理特殊的error
// 此方法是在主线程中运行
// 如果是当request 参数用不需要实现该方法，在complete 回调中解决问题就可以了
@optional
- (void)handleError:(NSError *)error request:(SHNetworkRequest *)request;

@end

@interface SHNetworkRequest : NSObject

@property (nonatomic, strong) id<SHNetworkPathReformer> pathReformer;
@property (nonatomic, strong) id<SHNetworkParameterReformer> parameterReformer;
@property (nonatomic, strong) id<SHNetworkResponseReformer> responseReformer;
@property (nonatomic, strong) id<SHNetworkCacheHandler> cacheHandler;
@property (nonatomic, strong) id<SHNetworkErrorHandler> errorHandler;
@property (nonatomic, strong) id<SHNetworkAPIErrorHandler> APIErrorHandler;

//请求地址
@property (nonatomic, copy) NSString *path;

//请求参数
@property (nonatomic, strong) id params;

//请求方式 默认为POST
@property (nonatomic, copy) NSString *method;

//JSON 数据类型校验，如果不传，默认 JSON 格式为 NSDictionary 即为正确
@property (nonatomic, strong) id JSONValidater;

//缓存使用的key
@property (nonatomic, copy) NSString *cacheKey;

//上传
@property (nonatomic, copy) SHNetworkConstructingBodyBlock constructingBodyBlock;
@property (nonatomic, copy) SHNetworkProgress uploadProgress;

//下载
@property (nonatomic, copy) SHNetworkDownloadDestination downloadDestination;
@property (nonatomic, copy) SHNetworkProgress downloadProgress;


//下载的dataTask
@property (nonatomic, readonly) NSURLSessionDataTask *dataTask;

//原始responseObject
@property (nonatomic, readonly) id responseObject;

//response 转换成的 class
@property (nonatomic, assign) Class reformClass;


    
    
@end

NS_ASSUME_NONNULL_END
