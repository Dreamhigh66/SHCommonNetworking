//
//  SHNetworkCache.m
//  Pods
//
//  Created by 张世豪 on 2019/3/16.
//

#import "SHNetworkCache.h"

@implementation SHNetworkCache

+ (instancetype)defaultCache
{
    static SHNetworkCache *netWorkCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        netWorkCache = [[SHNetworkCache alloc] init];
    });
    return netWorkCache;
}

- (instancetype)init
{
    if (self = [super init]) {
        _yyCache = [[YYCache alloc] initWithName:@"SHNetworking"];
    }
    return self;
}


@end
