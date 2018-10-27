//
//  LoginOpHandler.h
//  iOSDemo
//
//  Created by willyy on 2018/5/30.
//  Copyright © 2018年 willyy. All rights reserved.
//

#import "NetBaseHandler.h"

@interface LoginOpHelper : NetBaseHandler
+(NSString *)getSaltPasswd:(NSString *)passwd;
+(NSString*)genLoginTokenSeed:(NSString *)phone;

-(void)getChallenge:(NSString *)token handler:(void (^)(NSDictionary *res,NSError *error))handler;
-(void)verifySign:(NSString *)token sign:(NSString *)sign passwd:(NSString *)passwd handler:(void (^)(NSDictionary *res,NSError *error))handler;

-(void)getAuthCode:(NSString *)phone handler:(void (^)(NSDictionary *res, NSError *error))handler;
-(void)registerUser:(NSString *)phone passwd:(NSString *)passwd authCode:(NSString *)authCode handler:(void (^)(BOOL success, NSString *error))handler;

@end
