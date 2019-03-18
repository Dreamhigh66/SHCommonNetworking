//
//  SHNetworkBaseErrorHandler.m
//  SHNetworking
//
//  Created by 张世豪 on 2019/3/16.
//

#import "SHNetworkBaseErrorHandler.h"

static NSString *kSHErrorDomain = @"SHErrorDomain";
static NSString *kNoCacheErrorDesc = @"读取缓存数据失败";
static NSString *kCacheFormaterErrorDesc = @"缓存数据格式错误";
static NSString *kNoErrorCodeErrorDesc = @"返回数据格式错误";
static NSString *kResponseFormatErrorDesc = @"返回数据格式错误";
static NSString *kNoNetworkConnectErrorDesc = @"啊哦，网络有些不稳定￣へ￣";
static NSString *kServerUnReachabilityErrorDesc = @"当前服务器忙，请稍候重试";

@implementation SHNetworkBaseErrorHandler

- (NSError *)errorWithSHNetworkErrorCode:(SHNetworkErrorCode)errorCode request:(SHNetworkRequest *)request {
    NSDictionary *userInfo;
    switch (errorCode) {
        case SHNetworkErrorNoCache:
            userInfo = @{@"NSLocalizedDescription":kNoCacheErrorDesc};
            break;
        case SHNetworkErrorCacheFormatInvalidate:
            userInfo = @{@"NSLocalizedDescription":kCacheFormaterErrorDesc};
            break;
        case SHNetworkErrorNoErrorCode:
            userInfo = @{@"NSLocalizedDescription":kNoErrorCodeErrorDesc};
            break;
        case SHNetworkErrorResponseFormatInvalidate:
            userInfo = @{@"NSLocalizedDescription":kResponseFormatErrorDesc};
            break;
        case SHNetworkErrorNoNetworking:
            userInfo = @{@"NSLocalizedDescription":kNoNetworkConnectErrorDesc};
            break;
        case SHNetworkErrorServerUnReachablility:
            userInfo = @{@"NSLocalizedDescription":kServerUnReachabilityErrorDesc};
            break;
        case SHNetworkErrorRequestCancel:
            userInfo = @{@"NSLocalizedDescription":@""};
            break;
        default:
            break;
    }
    NSError *error = [NSError errorWithDomain:kSHErrorDomain code:errorCode userInfo:userInfo];
    return error;
}

- (id)responseObjectWithError:(NSError *)error request:(SHNetworkRequest *)request {
    if (error) {
        return @{
                 @"errorCode":@(error.code),
                 @"errorDesc":error.localizedDescription
                 };
    }
    return nil;
}

@end
