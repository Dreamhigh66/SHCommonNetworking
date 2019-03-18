//
//  SHNetworkClient.m
//  SHNetworking
//
//  Created by 张世豪 on 2019/3/16.
//

#import "SHNetworkClient.h"
#import "SHNetworkBasePathReformer.h"
#import "SHNetworkBaseCacheHandler.h"
#import "SHNetworkBaseParameterReformer.h"
#import "SHNetworkBaseResponseReformer.h"
#import "SHNetworkBaseErrorHandler.h"
#import "SHNetworkBaseAPIErrorHandler.h"
#import "AFNetworking.h"
#import "NSString+SHNetworkUtil.h"
#import "SHNetworkUtil.h"
#import <objc/runtime.h>

#ifdef DEBUG
#define SHNetworkLog( s, ... ) printf("class: <%p %s:(%d) > method: %s \n%s\n", self, [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, __PRETTY_FUNCTION__, [[NSString stringWithFormat:(s), ##__VA_ARGS__] UTF8String] )
#else
#define SHNetworkLog( s, ... )
#endif


@interface SHNetworkRequest (SHNetworkPrivate)

@property (nonatomic, strong) NSURLSessionDataTask *dataTask;

@property (nonatomic, strong) id responseObject;

@end

@implementation SHNetworkRequest (SHNetworkPrivate)

- (NSURLSessionDataTask *)dataTask {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setDataTask:(NSURLSessionDataTask *)dataTask {
    objc_setAssociatedObject(self, @selector(dataTask), dataTask, OBJC_ASSOCIATION_RETAIN);
}

- (id)responseObject {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setResponseObject:(id)responseObject {
    objc_setAssociatedObject(self, @selector(responseObject), responseObject, OBJC_ASSOCIATION_RETAIN);
}


@end

@interface SHNetworkClient ()

@property (nonatomic, strong) AFHTTPSessionManager *sessionManger;

@end

@implementation SHNetworkClient

+ (SHNetworkClient *)defaultClient {
    static SHNetworkClient *client;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        client = [[SHNetworkClient alloc] init];
    });
    return client;
}
- (instancetype)init
{
    if (self = [super init]) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.timeoutIntervalForRequest = self.timeoutIntervalForRequest > 0 ?self.timeoutIntervalForRequest : 20.f;
        configuration.timeoutIntervalForResource = self.timeoutIntervalForResource > 0 ?self.timeoutIntervalForResource : 20.f;
        _sessionManger = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
        _networkReachablity = [SHNetworkReachability reachabilityForInternetConnection];
        [_networkReachablity startNotifier];
        // 建立串行队列执行completeCallback
        dispatch_queue_t queue = dispatch_queue_create("com.feiniu.networking", DISPATCH_QUEUE_SERIAL);
        _sessionManger.completionQueue = queue;
    }
    return self;
}
- (void)requestWithPath:(NSString *)path param:(id)param reformClass:(Class)reformClass success:(SHNetworkRequestSuccess)success failure:(SHNetworkRequestFailure)failure {
    [self requestWithPath:path param:param reformClass:reformClass JSONValidater:nil cacheKey:@"" success:success failure:failure];
}
- (void)requestWithPath:(NSString *)path param:(id)param reformClass:(Class)reformClass JSONValidater:(id _Nullable)JSONValidater cacheKey:(NSString *)cacheKey success:(SHNetworkRequestSuccess)success failure:(SHNetworkRequestFailure)failure {
    SHNetworkRequest *request = [[SHNetworkRequest alloc] init];
    request.path = path;
    request.params = param;
    request.reformClass = reformClass;
    request.JSONValidater = JSONValidater;
    request.cacheKey = cacheKey;
    [self sendRequest:request success:success failure:failure];
}

- (void)sendRequest:(SHNetworkRequest *)request success:(SHNetworkRequestSuccess)success failure:(SHNetworkRequestFailure)failure {
    [self sendRequest:request completed:^(id responseObject, BOOL isCache, NSError *error) {
        if (error) {
            if (failure) {
                failure(responseObject, error);
            }
        }
        else {
            if (success) {
                success(responseObject, isCache);
            }
        }
    }];
}

- (void)sendRequest:(SHNetworkRequest *)request completed:(void (^)(id, BOOL, NSError *))completed
{
    NSString *requestPath = [self requestPathWithRequest:request];
    NSDictionary *parameter = [self paramterWithRequest:request];
    __weak typeof(self) weakSelf = self;
    if (request.constructingBodyBlock) {
        //上传
        request.dataTask = [self uploadWithPath:requestPath parameters:parameter constructingBodyWithBlock:request.constructingBodyBlock progress:request.uploadProgress success:^(NSURLSessionDataTask *task, id responseObject) {
            [weakSelf logRequestResponse:responseObject path:requestPath params:parameter httpResponse:nil error: nil];
            [weakSelf handleResponseObect:responseObject error:nil request:request completed:completed];
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            [weakSelf handleResponseObect:nil error:error request:request completed:completed];
        }];
    } else {
        request.dataTask = [self
                            requestWithMethod:request.method
                            withPath:requestPath
                            withParams:parameter
                            completionHandler:^(NSURLResponse *response, id responseObject,
                                                NSError *error) {
                                
                                [weakSelf logRequestResponse:responseObject path:requestPath params:parameter httpResponse:response error: error];
                                
                                [weakSelf handleResponseObect:responseObject error:error request:request completed:completed];
                            }];
    }
}

- (void)cancelRequestsForPath:(NSString *)path
{
    [self.sessionManager.tasks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSURLSessionDataTask *task = obj;
        if ([task.currentRequest.URL.relativePath hasSuffix:path]) {
            [task cancel];
        }
    }];
}

- (void)cancelAllRequests {
    [self.sessionManger.tasks makeObjectsPerformSelector:@selector(cancel)];
}
#pragma mark - 格式化log输出

- (void)logRequestResponse:(id)responseObject path:(NSString *)path params:(NSDictionary *)params httpResponse:(NSURLResponse *)httpResponse error:(NSError *)error
{
    NSString *jsonStatus = error ? @"OK" : @"Error";
    
    NSString *paramString = [NSString JSONStringNoFormartForDictionary:params];
    
    NSString *dataJSONString = [NSString formatJSON:paramString];
    
    NSString *responseJSONString = [responseObject isKindOfClass:[NSDictionary class]] ? [NSString JSONStringForDictionary:responseObject] : responseObject;
    SHNetworkLog(@"params\n%@", params[@"data"]);
    if (error) {
        
        NSHTTPURLResponse *httpURLResponse = (NSHTTPURLResponse *)httpResponse;
        NSMutableDictionary *httpInfo = [NSMutableDictionary dictionary];
        if (httpURLResponse) {
            
            [httpInfo setObject:httpURLResponse forKey:@"HTTPResponse"];
            NSString * localizedString = [NSHTTPURLResponse localizedStringForStatusCode:httpURLResponse.statusCode];
            [httpInfo setObject:localizedString forKey:@"localizedString"];
        }
        
    } else {
        
        SHNetworkLog(@"\n==============================  Begin  ====================================\n--- \n---URLPath:\n%@\n\n---Params：\n%@\n---Response:  (JSON %@) = \n%@\n==============================   End   ====================================", path, dataJSONString,jsonStatus, responseJSONString);
    }
}


#pragma mark - 封装使用 AFNetworking 请求

- (NSURLSessionDataTask *)requestWithMethod:(NSString*)method
                                   withPath:(NSString*)path
                                 withParams:(NSDictionary*)params
                          completionHandler:(void (^)(NSURLResponse *, id, NSError *))completionHandler
{
    NSError *error;
    NSURLRequest *request = [_sessionManger.requestSerializer requestWithMethod:method URLString:path parameters:params error:&error];
    if (error) {
        SHNetworkLog(@"%@", error.localizedDescription);
        return nil;
    }
    NSURLSessionDataTask *dataTask = [_sessionManger dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:completionHandler];
    [dataTask resume];
    return dataTask;
}


- (NSURLSessionDataTask *)uploadWithPath:(NSString *)path
                              parameters:(id)parameters
               constructingBodyWithBlock:(void (^)(id<AFMultipartFormData>))block
                                progress:(void (^)(NSProgress *))uploadProgress
                                 success:(void (^)(NSURLSessionDataTask *, id))success
                                 failure:(void (^)(NSURLSessionDataTask *, NSError *))failure

{
    NSURLSessionDataTask *dataTask = [_sessionManger POST:path parameters:parameters constructingBodyWithBlock:block progress:uploadProgress success:success failure:failure];
    [dataTask resume];
    return dataTask;
}

- (NSURLSessionDownloadTask *)downloadWithPath:(NSString *)path
                                      progress:(void (^)(NSProgress *))downloadProgressBlock
                                   destination:(NSURL *(^)(NSURL *, NSURLResponse *))destination
                             completionHandler:(void (^)(NSURLResponse *, NSURL *, NSError *))completionHandler
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:path]];
    NSURLSessionDownloadTask *downloadTask =
    [_sessionManger downloadTaskWithRequest:request
                                   progress:downloadProgressBlock
                                destination:destination
                          completionHandler:completionHandler];
    [downloadTask resume];
    return downloadTask;
}
#pragma mark - 处理回调逻辑

- (void)handleResponseObect:(id)responseObject
                      error:(NSError *)error
                    request:(SHNetworkRequest *)request
                  completed:(void (^)(id, BOOL, NSError *))completed {
    if (error) {
        SHNetworkLog(@"HttpRequest Status Code:%@, errorDesc:%@\n", @(error.code),
                     error.localizedDescription);
        if (error.code != -999) {
            if ([self.networkReachablity isReachable]) {
                error = [self errorWithSHNetworkErrorCode:SHNetworkErrorServerUnReachablility request:request];
            } else {
                error = [self errorWithSHNetworkErrorCode:SHNetworkErrorNoNetworking request:request];
            }
        } else {
            error = [self errorWithSHNetworkErrorCode:SHNetworkErrorRequestCancel request:request];
        }
        [self handleFailResponseModel:nil
                                error:error
                              request:request
                            completed:completed];
        return;
    }
    if (responseObject) {
        request.responseObject = responseObject;
        
        error = [self validateObjectFormat:responseObject request:request];
        if (error) {
            [self handleFailResponseModel:nil error:error request:request completed:completed];
            return;
        }
        id reformObject = [self responseReformWithRequest:request responseObject:responseObject];
        error = [self APIErrorCodeHandleWithResponseObject:responseObject request:request];
        if (error) {
            [self handleFailResponseModel:reformObject error:error request:request completed:completed];
            return;
        }
        
        [self setObject:responseObject forRequest:request];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completed) {
                completed(reformObject, NO, nil);
            }
        });
    }
}

- (void)handleFailResponseModel:(id)responseModel error:(NSError *)error request:(SHNetworkRequest *)request completed:(void (^)(id, BOOL, NSError *))completed
{
    id cacheResponseObject = [self objectForRequest:request];
    if (cacheResponseObject) {
        id reformedResponse = [self responseReformWithRequest:request responseObject:cacheResponseObject];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completed) {
                completed(reformedResponse, YES, nil);
            }
        });
    } else {
        
        if (!responseModel) {
            id responseObject = [self responseObjectWithError:error request:request];
            responseModel = [self responseReformWithRequest:request responseObject:responseObject];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.APIErrorHandler && [self.APIErrorHandler respondsToSelector:@selector(handleError:request:)]) {
                [self.APIErrorHandler handleError:error request:request];
            }
            if (completed) {
                completed(responseModel, NO, error);
            }
        });
    }
}

- (NSError *)validateObjectFormat:(id)object request:(SHNetworkRequest *)request {
    NSError *error = nil;
    if (!request.JSONValidater) {
        if (![object isKindOfClass:[NSDictionary class]]) {
            error = [self errorWithSHNetworkErrorCode:SHNetworkErrorResponseFormatInvalidate request:request];
        }
    } else {
        if (![SHNetworkUtil validateJSON:object
                              withValidator:request.JSONValidater]) {
            error = [self errorWithSHNetworkErrorCode:SHNetworkErrorResponseFormatInvalidate request:request];
        }
    }
    return error;
}

#pragma mark - 判断是否使用 request 配置相关方法

- (NSString *)requestPathWithRequest:(SHNetworkRequest *)request {
    id<SHNetworkPathReformer> pathReformer = request.pathReformer ?: self.pathReformer;
    NSString *path = request.path;
    if ([pathReformer respondsToSelector:@selector(pathReform:request:)]) {
        path = [pathReformer pathReform:request.path request:request];
    }
    return path;
}

- (NSDictionary *)paramterWithRequest:(SHNetworkRequest *)request {
    id<SHNetworkParameterReformer> paramterReformer = request.parameterReformer ?: self.parameterReformer;
    NSDictionary *parameter = request.params;
    if ([paramterReformer respondsToSelector:@selector(parametersReform:request:)]) {
        parameter = [paramterReformer parametersReform:request.params request:request];
    }
    return parameter;
}

- (id)responseReformWithRequest:(SHNetworkRequest *)request responseObject:(id)responseObject {
    id<SHNetworkResponseReformer> responseReformer = request.responseReformer ?: self.responseReformer;
    id response = responseObject;
    if ([responseReformer respondsToSelector:@selector(responseReform:reformClass:request:)] && request.reformClass) {
        response = [responseReformer responseReform:responseObject reformClass:request.reformClass request:request];
    }
    return response;
}

- (void)setObject:(id<NSCoding>) object forRequest:(SHNetworkRequest *)request {
    
    id<SHNetworkCacheHandler> cacheHandler = request.cacheHandler ?: self.cacheHandler;
    if ([cacheHandler respondsToSelector:@selector(setObject:forKey:)] && request.cacheKey.length > 0) {
        [cacheHandler setObject:object forKey:request.cacheKey];
    }
}

- (id<NSCoding>)objectForRequest:(SHNetworkRequest *)request {
    id<SHNetworkCacheHandler> cacheHandler = request.cacheHandler ?: self.cacheHandler;
    if ([cacheHandler respondsToSelector:@selector(objectForKey:)] && request.cacheKey.length > 0) {
        return [cacheHandler objectForKey:request.cacheKey];
    }
    return nil;
}

- (NSError *)errorWithSHNetworkErrorCode:(SHNetworkErrorCode)errorCode request:(SHNetworkRequest *)request {
    id<SHNetworkErrorHandler> errorHandler = request.errorHandler ?: self.errorHandler;
    NSError *error = nil;
    if ([errorHandler respondsToSelector:@selector(errorWithSHNetworkErrorCode:request:)]) {
        error = [errorHandler errorWithSHNetworkErrorCode:errorCode request:request];
    }
    if (!error) {
        SHNetworkLog(@"SHNetworkRequest errorHandler 没有实现 errorWithSHNetworkErrorCode:");
        error = [self.errorHandler errorWithSHNetworkErrorCode:errorCode request:request];
    }
    return error;
}

- (id)responseObjectWithError:(NSError *)error request:(SHNetworkRequest *)request {
    id<SHNetworkErrorHandler> errorHandler = request.errorHandler ?:self.errorHandler;
    
    if ([errorHandler respondsToSelector:@selector(responseObjectWithError:request:)]) {
        return [errorHandler responseObjectWithError:error request:request];
    }
    
    return nil;
    
}

- (NSError *)APIErrorCodeHandleWithResponseObject:(id)responseObject request:(SHNetworkRequest *)request {
    id<SHNetworkAPIErrorHandler> errorHandler = request.APIErrorHandler ?: self.APIErrorHandler;
    NSError *error = nil;
    if ([errorHandler respondsToSelector:@selector(APIErrorCodeValidated:request:)]) {
        error = [errorHandler APIErrorCodeValidated:responseObject request:request];
    }
    return error;
}
#pragma mark - getters

- (AFHTTPSessionManager *)sessionManager {
    return _sessionManger;
}

- (id<SHNetworkPathReformer>)pathReformer {
    if (!_pathReformer) {
        _pathReformer = [[SHNetworkBasePathReformer alloc] init];
    }
    return _pathReformer;
}

- (id<SHNetworkParameterReformer>)parameterReformer {
    if (!_parameterReformer) {
        _parameterReformer = [[SHNetworkBaseParameterReformer alloc] init];
    }
    return _parameterReformer;
}

- (id<SHNetworkResponseReformer>)responseReformer {
    if (!_responseReformer) {
        _responseReformer = [[SHNetworkBaseResponseReformer alloc] init];
    }
    return _responseReformer;
}

- (id<SHNetworkCacheHandler>)cacheHandler {
    if (!_cacheHandler) {
        _cacheHandler = [[SHNetworkBaseCacheHandler alloc] init];
    }
    return _cacheHandler;
}

- (id<SHNetworkErrorHandler>)errorHandler {
    if (!_errorHandler) {
        _errorHandler = [[SHNetworkBaseErrorHandler alloc] init];
    }
    return _errorHandler;
}

- (id<SHNetworkAPIErrorHandler>)APIErrorHandler {
    if (!_APIErrorHandler) {
        _APIErrorHandler = [[SHNetworkBaseAPIErrorHandler alloc] init];
    }
    return _APIErrorHandler;
}

@end
