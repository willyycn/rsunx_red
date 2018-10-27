//
//  LoginOpHandler.m
//  iOSDemo
//
//  Created by willyy on 2018/5/30.
//  Copyright © 2018年 willyy. All rights reserved.
//

#import "LoginOpHelper.h"
#import "GlobalEnv.h"
#import <RSAppSDK/RSunKit.h>
@implementation LoginOpHelper

/**
 * 设计一个token 格式 以便登陆业务可以使用
 * token = ios+phoneNumber+uuid+deviceType+appName+appVersion
 */
+(NSString*)genLoginTokenSeed:(NSString *)phone{
    NSString *token = @"";
    NSString *uuid = [GlobalEnv getUUID];
    NSString *deviceType = [GlobalEnv getDeviceType];
    NSString *appName = [GlobalEnv getAppName];
    NSString *appVersion = [GlobalEnv getAppVersion];
    token = [@"iOS" stringByAppendingFormat:@"_%@_%@_%@_%@_%@",phone,uuid,deviceType,appName,appVersion];
    return token;
}

+(NSString *)getSaltPasswd:(NSString *)passwd{
//    return [GlobalEnv salt:[GlobalEnv getUUID] passwd:passwd];
    return [RSunKit hash_passwd:passwd salt:[GlobalEnv getUUID]];
}

-(void)getChallenge:(NSString *)token handler:(void (^)(NSDictionary *res,NSError *error))handler{
    NSDictionary *para = @{@"token":token};
    [super network_base:@"/demo/challenge" param:para method:@"GET" progress:nil handler:^(NSDictionary * _Nullable res, NSError * _Nullable error) {
        handler(res,error);
    }];
}

/**
 * 登陆属于低安全场景 不用设置密码, 这样的好处再次打开app时不用输入登陆密码
 */
-(void)getLoginKey:(NSString *)token authCode:(NSString *)authCode handler:(void (^)(NSDictionary *res,NSError *error))handler{
    NSDictionary *param = @{@"token":token,@"authCode":authCode};
    [super network_base:@"/demo/generateKey" param:param method:@"POST" progress:nil handler:^(NSDictionary * _Nullable res, NSError * _Nullable error) {
        handler(res,error);
    }];
}

/**
 * 高安全级时使用的Key
 * 比如付费等操作前需要的鉴权工作
 */
-(void)getPrivilegeKey:(NSString *)token passwd:(NSString *)passwd authCode:(NSString *)authCode handler:(void (^)(NSDictionary *res,NSError *error))handler{
    NSDictionary *param;
    if (passwd==nil) {
       param = @{@"token":token,@"passwd":passwd,@"authCode":authCode};
    }
    else{
    param = @{@"token":token,@"passwd":passwd,@"authCode":authCode,@"passwd":passwd};
    }
    [super network_base:@"/demo/generateKey" param:param method:@"POST" progress:nil handler:^(NSDictionary * _Nullable res, NSError * _Nullable error) {
        handler(res,error);
    }];
}

/**
 * verifySign接口
 */
-(void)verifySign:(NSString *)token sign:(NSString *)sign passwd:(NSString *)passwd handler:(void (^)(NSDictionary *res,NSError *error))handler{
    if (passwd==nil) {
        passwd = @"";
    }
    NSDictionary *param = @{@"token":token, @"sign":sign, @"passwd":passwd};
    [super network_base:@"/demo/verify" param:param method:@"POST" progress:nil handler:^(NSDictionary * _Nullable res, NSError * _Nullable error) {
        handler(res,error);
    }];
}

-(void)getAuthCode:(NSString *)phone handler:(void (^)(NSDictionary *res, NSError *error))handler{
    [super network_base:@"/demo/authCode" param:@{@"phone":phone} method:@"GET" progress:nil handler:^(NSDictionary * _Nullable res, NSError * _Nullable error) {
        handler(res, error);
    }];
}

/**
 * register接口, 业务服务器同时生成低安全级别和高安全级别的Key
 */
-(void)registerUser:(NSString *)phone passwd:(NSString *)passwd authCode:(NSString *)authCode handler:(void (^)(BOOL success, NSString *error))handler{
    NSString *TokenSeed = [[self class] genLoginTokenSeed:phone];
    [super network_base:@"/demo/getLoginToken" param:@{@"seed":TokenSeed} method:@"GET" progress:nil handler:^(NSDictionary * _Nullable res, NSError * _Nullable error) {
        NSString *token = res[@"token"];
        [[GlobalEnv env] setLoginToken:token];
        [super network_base:@"/demo/registerUser" param:@{@"phone":phone,@"token":token,@"passwd":passwd,@"authCode":authCode} method:@"POST" progress:nil handler:^(NSDictionary * _Nullable res, NSError * _Nullable error) {
            if (error!=nil) {
                handler(NO,error.description);
            }
            NSString *err = res[@"error"];
            NSString *lowKey = res[@"low"];
            NSString *highKey = res[@"high"];
            if (err.length == 0) {
                [[GlobalEnv env] setLoginKey:lowKey];
                [[GlobalEnv env] setPrivilegeKey:highKey];
                handler(YES,nil);
            }
            else{
                handler(NO,err);
            }
        }];
    }];
}

@end
