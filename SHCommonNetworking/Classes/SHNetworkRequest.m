//
//  SHNetworkRequest.m
//  SHNetworking
//
//  Created by 张世豪 on 2019/3/11.
//

#import "SHNetworkRequest.h"



@implementation SHNetworkRequest

- (NSString *)method {
    if (!_method) {
        _method = @"POST";
    }
    return _method;
}


@end
