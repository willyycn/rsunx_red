//
//  RSunKit.h
//  RSAppDev
//
//  Created by willyy on 18/02/2018.
//  Copyright © 2018 willyy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RSunKit : NSObject
+ (instancetype)sharedKit;
- (NSDictionary *)signatureWithLevel:(int)level privateKey:(NSString *)privateKey withParam:(NSString *)parameter challenge2sign:(NSString *)challenge header:(NSString *)header;
- (BOOL)verify:(NSString *)token passwd:(NSString *)passwd param:(NSString *)param challenge:(NSString *)challenge sign:(NSString *)sign;
- (NSDictionary *)generateKeyPairWithLevel:(int)level signWithPrivateKey:(NSString *)privateKey withParam:(NSString *)param;
- (NSDictionary *)encryptWithMode:(int)mode withKey:(NSString *)key withInput:(NSString *)input;
- (NSString *)getChallenge;
+ (NSString *)hash_passwd:(NSString *)plain_passwd salt:(NSString *)salt;
@end
