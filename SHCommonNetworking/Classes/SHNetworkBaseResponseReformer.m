//
//  SHNetworkBaseResponseReformer.m
//  SHNetworking
//
//  Created by 张世豪 on 2019/3/16.
//

#import "SHNetworkBaseResponseReformer.h"

@implementation SHNetworkBaseResponseReformer

- (id)responseReform:(id)response reformClass:(Class)reformClass request:(SHNetworkRequest *)request {
    return response;
}

@end
