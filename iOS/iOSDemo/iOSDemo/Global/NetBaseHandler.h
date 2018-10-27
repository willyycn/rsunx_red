//
//  NetBaseHandler.h
//  iOSDemo
//
//  Created by willyy on 2018/5/30.
//  Copyright © 2018年 willyy. All rights reserved.
//

#import "AFHTTPSessionManager.h"

@interface NetBaseHandler : AFHTTPSessionManager
+ (instancetype _Nonnull)sharedHandler;
- (void)network_base:(NSString *_Nonnull)api_path param:(NSDictionary *_Nullable)param method:(NSString *_Nonnull)method progress:(nullable void (^)(NSProgress *_Nonnull downloadProgress))progress handler:(nullable void (^)(NSDictionary *_Nullable res,NSError *_Nullable error))handler;
@end
