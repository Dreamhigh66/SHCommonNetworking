//
//  SHNetworkCache.h
//  Pods
//
//  Created by 张世豪 on 2019/3/16.
//

#import <Foundation/Foundation.h>
#import "YYCache.h"

NS_ASSUME_NONNULL_BEGIN

@interface SHNetworkCache : NSObject

+ (instancetype)defaultCache;

@property (nonatomic, strong) YYCache *yyCache;

@end

NS_ASSUME_NONNULL_END
