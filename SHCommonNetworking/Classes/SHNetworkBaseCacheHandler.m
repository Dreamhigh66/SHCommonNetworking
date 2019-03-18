//
//  SHNetworkBaseCacheHandler.m
//  SHNetworking
//
//  Created by 张世豪 on 2019/3/16.
//

#import "SHNetworkBaseCacheHandler.h"
#import "SHNetworkCache.h"
@implementation SHNetworkBaseCacheHandler

- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key {
    [[SHNetworkCache defaultCache].yyCache setObject:object forKey:key];
}

- (id<NSCoding>)objectForKey:(NSString *)key {
    return [[SHNetworkCache defaultCache].yyCache objectForKey:key];
}

@end
