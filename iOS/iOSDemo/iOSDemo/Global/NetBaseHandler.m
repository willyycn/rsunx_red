//
//  NetBaseHandler.m
//  iOSDemo
//
//  Created by willyy on 2018/5/30.
//  Copyright © 2018年 willyy. All rights reserved.
//

#import "NetBaseHandler.h"
#import "GlobalEnv.h"
@implementation NetBaseHandler
+ (instancetype _Nonnull)sharedHandler{
    static id _sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[[self class] alloc] init];
    });
    return _sharedInstance;
}

-(id)init
{
    self=[super init];
    if (self) {
        //init
        self = [self initWithBaseURL:[NSURL URLWithString:ServerUrl]];
        self.securityPolicy = [self customSecurityPolicy];
        self.requestSerializer = [AFHTTPRequestSerializer serializer];
        self.responseSerializer = [AFJSONResponseSerializer serializer];
        self.requestSerializer.timeoutInterval = 20.f;
        self.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        self.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html",@"application/x-www-form-urlencoded; charset=UTF-8", nil];
        [self setSessionDidBecomeInvalidBlock:^(NSURLSession * _Nonnull session, NSError * _Nonnull error) {
            NSLog(@"setSessionDidBecomeInvalidBlock");
        }];
        __weak typeof(self)weakSelf = self;
        [self setSessionDidReceiveAuthenticationChallengeBlock:^NSURLSessionAuthChallengeDisposition(NSURLSession*session, NSURLAuthenticationChallenge *challenge, NSURLCredential *__autoreleasing*_credential) {
            NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
            __autoreleasing NSURLCredential *credential =nil;
            if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
                if([weakSelf.securityPolicy evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:challenge.protectionSpace.host]) {
                    credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
                    if(credential) {
                        disposition =NSURLSessionAuthChallengeUseCredential;
                    } else {
                        disposition =NSURLSessionAuthChallengePerformDefaultHandling;
                    }
                } else {
                    disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
                }
            } else {
                // client authentication
                SecIdentityRef identity = NULL;
                SecTrustRef trust = NULL;
                NSString *p12 = [[NSBundle mainBundle] pathForResource:@"demo"ofType:@"pfx"];
                NSFileManager *fileManager =[NSFileManager defaultManager];
                
                if(![fileManager fileExistsAtPath:p12])
                {
                    NSLog(@"demo.pfx:not exist");
                }
                else
                {
                    NSData *PKCS12Data = [NSData dataWithContentsOfFile:p12];
                    
                    if ([[weakSelf class]extractIdentity:&identity andTrust:&trust fromPKCS12Data:PKCS12Data])
                    {
                        SecCertificateRef certificate = NULL;
                        SecIdentityCopyCertificate(identity, &certificate);
                        const void*certs[] = {certificate};
                        CFArrayRef certArray =CFArrayCreate(kCFAllocatorDefault, certs,1,NULL);
                        credential =[NSURLCredential credentialWithIdentity:identity certificates:(__bridge  NSArray*)certArray persistence:NSURLCredentialPersistencePermanent];
                        disposition =NSURLSessionAuthChallengeUseCredential;
                    }
                }
            }
            *_credential = credential;
            return disposition;
        }];
    }
    return self;
}

- (AFSecurityPolicy *)customSecurityPolicy{
    NSString *certFilePath = [[NSBundle mainBundle] pathForResource:@"demo" ofType:@"cer"];
    NSData *certData = [NSData dataWithContentsOfFile:certFilePath];
    NSSet *certSet = [NSSet setWithObject:certData];
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate withPinnedCertificates:certSet];
    policy.allowInvalidCertificates = YES;
    policy.validatesDomainName = NO;
    return policy;
}

+ (BOOL)extractIdentity:(SecIdentityRef*)outIdentity andTrust:(SecTrustRef *)outTrust fromPKCS12Data:(NSData *)inPKCS12Data {
    OSStatus securityError = errSecSuccess;
    NSDictionary*optionsDictionary = [NSDictionary dictionaryWithObject:@"123456" forKey:(__bridge id)kSecImportExportPassphrase];
    
    CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
    securityError = SecPKCS12Import((__bridge CFDataRef)inPKCS12Data,(__bridge CFDictionaryRef)optionsDictionary,&items);
    
    if(securityError == 0) {
        CFDictionaryRef myIdentityAndTrust =CFArrayGetValueAtIndex(items,0);
        const void*tempIdentity =NULL;
        tempIdentity= CFDictionaryGetValue (myIdentityAndTrust,kSecImportItemIdentity);
        *outIdentity = (SecIdentityRef)tempIdentity;
        const void*tempTrust =NULL;
        tempTrust = CFDictionaryGetValue(myIdentityAndTrust,kSecImportItemTrust);
        *outTrust = (SecTrustRef)tempTrust;
    } else {
        NSLog(@"Failedwith error code %d",(int)securityError);
        return NO;
    }
    return YES;
}

- (void)network_base:(NSString *_Nonnull)api_path param:(NSDictionary *_Nullable)param method:(NSString *_Nonnull)method progress:(nullable void (^)(NSProgress *_Nonnull downloadProgress))progress handler:(nullable void (^)(NSDictionary *_Nullable res,NSError *_Nullable error))handler{
    method = [method lowercaseString];
    if ([method isEqualToString:@"get"]) {
        [[[self class] sharedHandler]GET:api_path parameters:param progress:^(NSProgress * _Nonnull uploadProgress) {
            if (progress!=nil) {
                progress(uploadProgress);
            }
        }  success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if (handler!=nil) {
                handler(responseObject,nil);
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                if (handler!=nil) {
                    handler(nil,error);
                }
        }];
    }
    else if ([method isEqualToString:@"post"]){
        [[[self class] sharedHandler]POST:api_path parameters:param progress:^(NSProgress * _Nonnull uploadProgress) {
            if (progress!=nil) {
                progress(uploadProgress);
            }
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if (handler!=nil) {
                handler(responseObject,nil);
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            if (handler!=nil) {
                handler(nil,error);
            }
        }];
    }
    else{
        NSLog(@"not support method");
    }
}
@end
