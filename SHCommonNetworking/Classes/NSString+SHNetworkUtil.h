//
//  NSString+SHNetworkUtil.h
//  SHNetworking
//
//  Created by 张世豪 on 2019/3/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (SHNetworkUtil)

/**
 * 清除json中多余的转义字符 \
 */
+ (NSString *)clearJSONFormart:(NSString *)str;

/**
 * 重新给json 字符串添加 格式
 */
+ (NSString *)formatJSON:(NSString *)str;

/**
 * 将json字典直接转化为格式好的json字符串
 */
+ (NSString *)JSONStringForDictionary:(NSDictionary *)dictionary;

+ (NSString *)JSONStringNoFormartForDictionary:(NSDictionary *)dictionary;


@end

NS_ASSUME_NONNULL_END
