//
//  GlobalEnv.m
//  iOSDemo
//
//  Created by willyy on 2018/5/30.
//  Copyright © 2018年 willyy. All rights reserved.
//

#import "GlobalEnv.h"
#import <UIKit/UIKit.h>
#import <UIKit/UIDevice.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
//NSString * const ServerUrl = @"https://172.20.10.3:4043";
NSString * const ServerUrl = @"https://10.10.252.17:4043";
NSString * const PublicParam = @"3c4f1c1a30d41f726b63d6d04482b8566e52559980914eba3b4193f753f5ce1081c9820fe45d942896eaff3ff8402c84b1969b5e9f7f972d78fe62f36846e52baad957f23877dfedb4a22536c18d220a7e9e00999befae05246d275ea33188d764cb9900e8b8ecda40ba2228887882bf70e86809836d8199ecaaff4d1d3b601c01.8e6d1b58557ca0993a13738af831e99d7ca7411aff8aae26901cab5655ec237b9b96c3dae6ee3e1a164d2438575ac1f321409cb47b8edcfbce9be1ca5d9e0954d05985b043b547fde4fc79c18e75858383eb837cbe24f7c5a284c4e47798e238a1d6282c7786c54689e75ca2318716df984db7a06a3608359f4d2aa002494a755eca67b551aac076975fd53d1717fecdcda007342fb115cccb8ee2af819a1e35bddba2cebc57d527de0033538077a8cc0431a20ff43ae287416dff1d23e153882f0157cd9b42bee8e2d99b40211005d0b90e340b659236c3f40e6eaa813f6c741ab80c7893c9c0facd83f69be44324db4de0bc86ee95790cce31b9fc891e81e1010001";
//NSString * const PublicParam = @"3961f1e2a0a244c89b137eff1c0fbe8dfec2c63bb813a12f2fa0a4d0814668f8991295277d0269e5d8eb39b59cbf1340131523b516dc08403af9d825f9679e576c33ecb13f38c3bb01343defd423986ea8477c898c0a12791ed1521ec08f15936c46372d5f605199eff33f4c8d03657594d956f6ae188cae91f2e8832acb89c801.82de2a0b1ecd5867b8797c515ec6512e83a4089df0a8938e732978df0aa5e7813ea540ad3e83058af9796b3b9ee84d995869e729b3de72fd200d041ee6de07a00c87e5102e0b651cc89d1f1685cb7170cb33cbee14cdff0a52267ccbcc796cdf6c8df99855d63b9003e7764c280e48d5b14b847357924db110c3d3915c262a383c7ad2642002554c81ca17470dfe420721fbfae4646cdb14f513c8226a96e1e0125d20d4a08504884bfc69324b1a796e0a8b3aa757bf769c10eb8ca0be5723f798cf3f00712ed13a6cdcb1d4efb611eaaafbfd5814c4503177a5d5e710e96ae540fd12567409b7ab50ceb7c91e266b239143e73c0db4e49b1726b4e28a7b7db5010001";
NSString * const LoginTokenKey = @"loginToken";
NSString * const LoginKey = @"loginKey";
NSString * const PrivilegeKey = @"privilegeKey";
@interface GlobalEnv()
{
    NSString *aesKey;
    NSString *iv;
}
@end

@implementation GlobalEnv
+(instancetype _Nonnull)env {
    static id _env = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _env = [[[self class] alloc] init];
    });
    return _env;
}
-(id)init
{
    self=[super init];
    if (self) {
        //init
        aesKey = [self getAESKey];
        iv = [self getIV];
//        NSLog(@"aes: %@, iv: %@",aesKey,iv);
    }
    return self;
}

+ (void)alertWithTitle:(NSString *)title message:(NSString *)message
{
    UIAlertView *av = [[UIAlertView alloc]initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [av show];
}

-(NSString *)getLoginToken{
    NSString *token;
    token = [self rawLoadUserDataWithKey:LoginTokenKey];
    return token;
}
-(void)setLoginToken:(NSString *)token{
    [self rawSaveUserData:token withKey:LoginTokenKey];
}

-(NSString *)getLoginKey{
    NSString *token;
    token = [self secLoadUserDataWithKey:LoginKey];
    return token;
}
-(void)setLoginKey:(NSString *)key{
    [self secSaveUserData:key withKey:LoginKey];
}

-(NSString *)getPrivilegeKey{
    NSString *pkey;
    pkey = [self secLoadUserDataWithKey:PrivilegeKey];
    return pkey;
}
-(void)setPrivilegeKey:(NSString *)key{
    [self secSaveUserData:key withKey:PrivilegeKey];
}

-(BOOL)logoff{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:LoginKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:LoginTokenKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:PrivilegeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return YES;
}

#pragma mark store private method
-(NSString *)getAESKey{
    return [[[self class] sha256DigestFromString:[[self class]getUUID]]substringWithRange:NSMakeRange(8, 32)];
}

-(NSString *)getIV{
    return [[[self class] sha256DigestFromString:[[self class]getUUID]]substringWithRange:NSMakeRange(40, 16)];
}

-(void)rawSaveUserData:(NSString *)string withKey:(NSString *)key
{
    NSString *saveStr = string;
    NSData * se = [saveStr dataUsingEncoding:NSUTF8StringEncoding];
    [[NSUserDefaults standardUserDefaults] setObject:se forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSString *)rawLoadUserDataWithKey:(NSString *)key
{
    NSString *loadStr = @"";
    NSData * se = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    loadStr = [[NSString alloc]initWithData:se encoding:NSUTF8StringEncoding];
    return loadStr;
}

-(void)secSaveUserData:(NSString *)string withKey:(NSString *)key
{
    NSString *saveStr = string;
    NSData * se = [self encrypt:[saveStr dataUsingEncoding:NSUTF8StringEncoding] key:aesKey iv:iv];
    [[NSUserDefaults standardUserDefaults] setObject:se forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSString *)secLoadUserDataWithKey:(NSString *)key
{
    NSString *loadStr = @"";
    NSData * se = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    NSData * sd = [self decrypt:se key:aesKey iv:iv];
    loadStr = [[NSString alloc]initWithData:sd encoding:NSUTF8StringEncoding];
    return loadStr;
}

- (NSData *)encrypt:(NSData *)plainText key:(NSString *)key  iv:(NSString *)iv {
    char keyPointer[kCCKeySizeAES256+2],
        ivPointer[kCCBlockSizeAES128+2];
    BOOL patchNeeded;
    bzero(keyPointer, sizeof(keyPointer));
    patchNeeded= ([key length] > kCCKeySizeAES256+1);
    if(patchNeeded)
    {
        key = [key substringToIndex:kCCKeySizeAES256];
    }
    [key getCString:keyPointer maxLength:sizeof(keyPointer) encoding:NSUTF8StringEncoding];
    [iv getCString:ivPointer maxLength:sizeof(ivPointer) encoding:NSUTF8StringEncoding];
    if (patchNeeded) {
        keyPointer[0] = '\0';
    }
    NSUInteger dataLength = [plainText length];
    size_t buffSize = dataLength + kCCBlockSizeAES128;
    void *buff = malloc(buffSize);
    size_t numBytesEncrypted = 0;
    CCCryptorStatus status = CCCrypt(kCCEncrypt,
                                     kCCAlgorithmAES128,
                                     kCCOptionPKCS7Padding,
                                     keyPointer, kCCKeySizeAES256,
                                     ivPointer,
                                     [plainText bytes], [plainText length],
                                     buff, buffSize,
                                     &numBytesEncrypted);
    if (status == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buff length:numBytesEncrypted];
    }
    
    free(buff);
    return nil;
}

-(NSData *)decrypt:(NSData *)encryptedText key:(NSString *)key iv:(NSString *)iv {
    char keyPointer[kCCKeySizeAES256+2],
    ivPointer[kCCBlockSizeAES128+2];
    BOOL patchNeeded;
    patchNeeded = ([key length] > kCCKeySizeAES256+1);
    if(patchNeeded)
    {
        key = [key substringToIndex:kCCKeySizeAES256];
    }
    [key getCString:keyPointer maxLength:sizeof(keyPointer) encoding:NSUTF8StringEncoding];
    [iv getCString:ivPointer maxLength:sizeof(ivPointer) encoding:NSUTF8StringEncoding];
    if (patchNeeded) {
        keyPointer[0] = '\0';
    }
    NSUInteger dataLength = [encryptedText length];
    size_t buffSize = dataLength + kCCBlockSizeAES128;
    void *buff = malloc(buffSize);
    size_t numBytesEncrypted = 0;
    CCCryptorStatus status = CCCrypt(kCCDecrypt,
                                     kCCAlgorithmAES128,
                                     kCCOptionPKCS7Padding,
                                     keyPointer, kCCKeySizeAES256,
                                     ivPointer,
                                     [encryptedText bytes], [encryptedText length],
                                     buff, buffSize,
                                     &numBytesEncrypted);
    if (status == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buff length:numBytesEncrypted];
    }
    free(buff);
    return nil;
}

#pragma mark device info
+(NSString *)getDeviceOwner{
    return [[UIDevice currentDevice] name];
}

+(NSString *)getDeviceSystem{
    return [[UIDevice currentDevice] model];
}

+(NSString *)getDeviceType{
    return [NSString stringWithFormat:@"%@%@",[[UIDevice currentDevice] systemName], [[UIDevice currentDevice] systemVersion]];
}

+(NSString *)getUUID{
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

+(NSString *)getAppName{
    NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
    NSString *appName = [infoDic objectForKey:@"CFBundleName"];
    return appName;
}

+(NSString *)getAppVersion{
    NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDic objectForKey:@"CFBundleShortVersionString"];
    return appVersion;
}

+(NSString *)getAppBuild{
    NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
    NSString *appBuild = [infoDic objectForKey:@"CFBundleVersion"];
    return appBuild;
}

+(NSString *)getAppBundleID{
    return [[NSBundle mainBundle] bundleIdentifier];
}

#pragma mark passwd salt
+(NSString *)salt:(NSString *)salt passwd:(NSString *)passwd{
    NSString * retStr = @"";
    retStr = [passwd stringByAppendingString:salt];
    retStr = [[self class] sha256DigestFromString:retStr];
    return retStr;
}

+(NSString *)convertDataToHexStr:(NSData *)data {
    if (!data || [data length] == 0) {
        return @"";
    }
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[data length]];
    
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        unsigned char *dataBytes = (unsigned char*)bytes;
        for (NSInteger i = 0; i < byteRange.length; i++) {
            NSString *hexStr = [NSString stringWithFormat:@"%x", (dataBytes[i]) & 0xff];
            if ([hexStr length] == 2) {
                [string appendString:hexStr];
            } else {
                [string appendFormat:@"0%@", hexStr];
            }
        }
    }];
    
    return string;
}

+(NSString *)sha256DigestFromString:(NSString *)str
{
    NSData *stringData = [str dataUsingEncoding:NSUTF8StringEncoding];
    if (stringData == nil) {
        return nil;
    }
    NSData *hashData = [[self class] sha256DigestData:stringData];
    NSString *sha256Digest = [[self class] convertDataToHexStr:hashData];
    return sha256Digest.uppercaseString;
}

+(NSData*) sha256DigestData:(NSData*)data {
    
    unsigned char sha256Digest[CC_SHA256_DIGEST_LENGTH];
    if (data) {
        CC_SHA256(data.bytes, (CC_LONG)data.length, sha256Digest);
    }
    return [[NSData alloc] initWithBytes:sha256Digest length:sizeof(sha256Digest)];
}

@end
