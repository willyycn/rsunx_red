//
//  GlobalEnv.h
//  iOSDemo
//
//  Created by willyy on 2018/5/30.
//  Copyright © 2018年 willyy. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const ServerUrl;
extern NSString * const PublicParam;

@interface GlobalEnv : NSObject
+(instancetype _Nonnull)env;

+ (void)alertWithTitle:(NSString *)title message:(NSString *)message;

-(NSString *)getLoginToken;
-(void)setLoginToken:(NSString *)token;
-(NSString *)getLoginKey;
-(void)setLoginKey:(NSString *)key;
-(NSString *)getPrivilegeKey;
-(void)setPrivilegeKey:(NSString *)key;

-(BOOL)logoff;

+(NSString *)getDeviceOwner;
+(NSString *)getDeviceSystem;
+(NSString *)getDeviceType;
+(NSString *)getUUID;
+(NSString *)getAppName;
+(NSString *)getAppVersion;
+(NSString *)getAppBuild;
+(NSString *)getAppBundleID;
+(NSString *)salt:(NSString *)salt passwd:(NSString *)passwd;
@end
