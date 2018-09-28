//
//  DDNet.m
//  DDNetWorking
//
//  Created by apple on 2018/9/28.
//  Copyright © 2018年 wjy. All rights reserved.
//

#import "DDNet.h"
#import "NSString+WJ_md5Str.h"
#import <AFNetworking.h>

#define encryptionKey @"JF0XMw6XhwU8jXHH"
@implementation DDNet
+(void)getUrl:(NSString *)URL withParDic:(NSMutableDictionary*)parDic completion:(void (^)(BOOL, NSArray *, NSString *))block {
    
//    NSString *URL = [NSString stringWithFormat:@"%@%@", imDev_Url, apiAppraisalList];
    
//    NSMutableDictionary *parDic = [NSMutableDictionary dictionary];
    
//    [parDic setValue:zone_id forKey:@"zone_id"];
//    [parDic setValue:[NSNumber numberWithInteger:[type integerValue]] forKey:@"type"];
//    [parDic setValue:[UserInfoModel sharedUserInfoModel].token forKey:@"token"];
    [parDic setValue:[self backTimeinterval] forKey:@"time"];
    NSString *sign = [self backSign:nil andDic:parDic];
    [parDic setValue:sign forKey:@"sign"];
    
    AFHTTPSessionManager *manager = [self manager];
    [manager.requestSerializer setValue:@"iOS" forHTTPHeaderField:@"platform"];
    [manager GET:URL parameters:parDic progress:nil success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        
        [self parseAppraisalList:YES responseObject:responseObject error:nil completion:block];
        
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        
        [self parseAppraisalList:NO responseObject:nil error:error completion:block];
        
    }];
}

+(void)parseAppraisalList:(BOOL)success responseObject:(id)responseObject error:(NSError *)error completion:(void (^)(BOOL success, NSArray *arr, NSString *msg))block
{
    NSString *message = nil;
    BOOL resultSuccess = NO;
    NSArray  *result =  [self parseData:YES responseObject:responseObject error:error dataClass:[NSArray class] success:&resultSuccess message:&message sessionExpired:nil content:@"轮播图"];
    
    if (!resultSuccess || !result || result.count == 0) {
        block(NO, nil, message);
        return;
    }
    
    block(YES,result,message);
}

+ (AFHTTPSessionManager *)manager {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    [manager.requestSerializer setTimeoutInterval:30];
    [manager.securityPolicy setAllowInvalidCertificates:YES];
    [manager.securityPolicy setValidatesDomainName:NO];
    [manager setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    
    return manager;
}
+ (id)parseData:(BOOL)responseSuccess responseObject:(id)responseObject error:(NSError *)error dataClass:(Class)dataClass success:(BOOL *)success message:(NSString **)message sessionExpired:(BOOL *)sessionExpired content:(NSString *)content {
    if (sessionExpired) {
        *sessionExpired = NO;
    }
    
    if (!responseSuccess) {
        *success = NO;
        *message = @"请检查网络";
        
        //RJSportErrorLog(@"%@请求响应失败，错误信息: %@", content, error.localizedDescription);
        
        return nil;
    }
    
    //RJSportDebugLog(@"请求响应成功");
    
    if (!responseObject) {
        *success = NO;
        if (error) {
            if(error.code == -1009)
            {
                *message = @"网络无连接，似乎断网了...";
                return nil;
            }
        }
        *message = @"出错啦！";
        
        //RJSportErrorLogAndUpload(@"%@响应数据为空", content);
        return nil;
    }
    
    if (![responseObject isKindOfClass:[NSData class]]) {
        *success = NO;
        *message = @"出错啦！";
        
        //RJSportErrorLogAndUpload(@"%@响应数据类型不是NSData，类型为: %@", content, NSStringFromClass([responseObject class]));
        return nil;
    }
    
    NSError *jsonError = nil;
    id jsonResult = [self parseJsonWithData:responseObject error:&jsonError];
    
    if (!jsonResult || jsonError) {
        *success = NO;
        *message = @"出错啦！";
        
        //RJSportErrorLogAndUpload(@"%@返回数据json解析失败, 失败原因: %@", content, jsonError.localizedDescription);
        return nil;
    }
    
    if (![jsonResult isKindOfClass:[NSDictionary class]]) {
        *success = NO;
        *message = @"出错啦！";
        
        //RJSportErrorLogAndUpload(@"%@返回数据解析出的类型不是NSDictionary, 解析出的类型: %@", content, NSStringFromClass([jsonResult class]));
        return nil;
    }
    
    NSDictionary *jsonResultDict = (NSDictionary *)jsonResult;
    
    NSInteger code = [[jsonResultDict objectForKey:@"code"] integerValue];
    NSString *msg = [jsonResultDict objectForKey:@"msg"];
    *message = msg;
    if (code == -99999 || code == -99998) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"tiren" object:nil];
        return nil;
    }
    if (code == -101) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"GoEditPersonVCTip" object:nil];
        return nil;
    }
    if (code == 10) {
        *success = NO;
        if (sessionExpired) {
            *sessionExpired = YES;
        }
        
        //RJSportErrorLog(@"%@会话过期，错误信息: %@", content, msg);
        
        return nil;
    }
    if(code == -20010)
    {
        *success = NO;
        *message = @"请输入正确的验证码";
        return nil;
    }
    if (code != 1) {
        *success = NO;
        
        //RJSportErrorLog(@"%@返回数据中code为%d，表示失败，错误信息: %@", content, (int)code, msg);
        
        return nil;
    }
    
    *success = YES;
    
    id data = [jsonResultDict objectForKey:@"data"];
    
    if (!data) {
        // RJSportDebugLog(@"%@返回数据中data为空，msg信息: %@", content, msg);
        
        return nil;
    }
    if ([dataClass isKindOfClass:[NSNull class]]) {
        //RJSportDebugLog(@"%@返回数据中data不为空，但开发者未赋予其类型，msg信息: %@", content, msg);
        
        return nil;
    }
    //    if (![data isKindOfClass:dataClass]) {
    //        //RJSportErrorLogAndUpload(@"%@返回数据中data类型非%@, data类型: %@", content, NSStringFromClass(dataClass), NSStringFromClass([data class]));
    //
    //        return nil;
    //    }
    
    
    // RJSportDebugLog(@"%@数据解析成功，data: %@, msg: %@", content, data, msg);
    
    return data;
}
+ (id)parseJsonWithData:(NSData *)jsonData error:(NSError **)error {
    return [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:error];
}

//获取时间戳
+(NSString *)backTimeinterval{
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970] * 1000;
    NSString *timeStr = [NSString stringWithFormat:@"%ld", (long)interval];
    return timeStr;
}
//签名
+(NSString *)backSign:(NSString *)url andDic:(NSDictionary *)dataDic{
    NSString *md5Str = @"";
    NSArray *ary = [dataDic.allKeys sortedArrayUsingSelector:@selector(compare:)];
    for (int i=0; i<ary.count; i++) {
        md5Str = [md5Str stringByAppendingString:[NSString stringWithFormat:@"%@",ary[i]]];
        md5Str = [md5Str stringByAppendingString:@"="];
        md5Str = [md5Str stringByAppendingString:[NSString stringWithFormat:@"%@",[dataDic valueForKey:ary[i]]]];
        if (i<(ary.count-1)) {
            md5Str = [md5Str stringByAppendingString:@"&"];
        }
    }
    md5Str = [md5Str stringByAppendingString:encryptionKey];
    return [md5Str stringToMD5:md5Str];
}
+(NSString *)backSign:(NSString *)p
{
    NSString *md5Str = p;
    md5Str = [md5Str stringByAppendingString:encryptionKey];
    return [md5Str stringToMD5:md5Str];
}
@end
