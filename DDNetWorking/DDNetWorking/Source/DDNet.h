//
//  DDNet.h
//  DDNetWorking
//
//  Created by apple on 2018/9/28.
//  Copyright © 2018年 wjy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DDNet : NSObject
+(void)getUrl:(NSString *)URL withParDic:(NSMutableDictionary*)parDic completion:(void (^)(BOOL, NSArray *, NSString *))block;
@end
