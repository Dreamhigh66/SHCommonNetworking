//
//  SHNetworkUtil.h
//  SHNetworking
//
//  Created by 张世豪 on 2019/3/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SHNetworkUtil : NSObject
+ (BOOL)validateJSON:(id)json withValidator:(id)jsonValidator;

@end

NS_ASSUME_NONNULL_END
