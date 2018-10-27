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
NSString * const PublicParam = @"490b8008685bfc33526a50bb26e08bdb08cdb2ecf539e4ba94f05c00f557715cac67bcab3622a4525a08ef29baf4bf6ad3c638bce055df1a40b767ae403469b41906ec44799d57ee171993bc931009ace39b4408a2d18832b82fd496e60edc6c4b1483fdf73eb20d7387646c70c2c98f054b14e68398c0c3b5e2b9de174b70ec01.b3940619ca2b0cdf2851a51ac57a0da188c17073bb32a349f697ae214696007777ee434e2dc4c80af370e42e964717d55e4ad90cb710a6e47ee80f49119d3fecfc6bce38ebcb83df8442a2b1385d4ee2c3ebaa4efa36f47f77589ed2cbdab07c0b52b7751c24accffa9c908d58182b5fd123556b18271602d08506861a9b4a58061394eb322189dcf0df200020e0987cc6b2361a07119b0f2959a1b419c0d6c605a12aeb99f1c62a9250aa8cbaaa3ba4c3c90636344034b58af31691589dfdc92c39ae22534021e62035c619e0cdd842be06d81243afd5bbaa15d52a51fac5bcb2f699949752f03cb17d206efccb7ee986c085950f066a5f2d04eb768b9166d5010001";
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
