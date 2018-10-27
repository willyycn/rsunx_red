//
//  MainViewController.m
//  iOSDemo
//
//  Created by willyy on 2018/6/3.
//  Copyright © 2018年 willyy. All rights reserved.
//

#import "MainViewController.h"
#import "LoginViewController.h"
#import "Global/GlobalEnv.h"
#import "LoginOperation/LoginOpHelper.h"
#import <RSAppSDK/RSunKit.h>
#import "Global/GlobalEnv.h"
@interface MainViewController ()
{
    BOOL fastMode;
}
@property (weak, nonatomic) IBOutlet UISwitch *algSwitchBtn;
- (IBAction)algSwitchAction:(id)sender;
@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    fastMode = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)highRiskAction:(id)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"高安全操作" message:@"请输入密码" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"密码";
        textField.secureTextEntry = true;
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *passwd = alertController.textFields[0].text;
        passwd = [LoginOpHelper getSaltPasswd:passwd];
        NSString *token = [[GlobalEnv env] getLoginToken];
        NSString *phone = [token componentsSeparatedByString:@"_"][1];
        [[LoginOpHelper sharedHandler] getChallenge:token handler:^(NSDictionary *res, NSError *error) {
            NSString *rand = res[@"rand"];
            if (rand.length>0) {
                NSDictionary *sign =[[RSunKit sharedKit] signatureWithLevel:self->fastMode privateKey:[[GlobalEnv env] getPrivilegeKey] withParam:PublicParam challenge2sign:rand header:nil];
                NSString *p = [[phone stringByAppendingString:@"_"] stringByAppendingString:GlobalEnv.getUUID];
                [[LoginOpHelper sharedHandler] verifySign:p sign:sign[@"signature"] passwd:passwd handler:^(NSDictionary *res, NSError *error) {
                    BOOL server_verify = [res[@"verify"] boolValue];
                    NSLog(@"server verify: %d",server_verify);
                    [GlobalEnv alertWithTitle:@"结果" message:[NSString stringWithFormat:@"server verify: %d",server_verify]];
                }];
                
                BOOL client_verify = [[RSunKit sharedKit] verify:p passwd:passwd param:PublicParam challenge:rand sign:sign[@"signature"]];
                
                NSLog(@"client verify: %d",client_verify);
            }
            else{
                [GlobalEnv alertWithTitle:@"错误" message:@"无法获取挑战"];
            }
        }];
        
    }];
    [alertController addAction:okAction];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

-(void)callLowRisk{
    NSString *token = [[GlobalEnv env] getLoginToken];
    [[LoginOpHelper sharedHandler] getChallenge:token handler:^(NSDictionary *res, NSError *error) {
        NSString *rand = res[@"rand"];
        if (rand.length>0) {
            NSDictionary *sign =[[RSunKit sharedKit] signatureWithLevel:self->fastMode privateKey:[[GlobalEnv env] getLoginKey] withParam:PublicParam challenge2sign:rand header:nil];
            [[LoginOpHelper sharedHandler] verifySign:token sign:sign[@"signature"] passwd:nil handler:^(NSDictionary *res, NSError *error) {
                BOOL server_verify = [res[@"verify"] boolValue];
                NSLog(@"server verify: %d",server_verify);
                [GlobalEnv alertWithTitle:@"结果" message:[NSString stringWithFormat:@"server verify: %d",server_verify]];
            }];
            
            BOOL client_verify = [[RSunKit sharedKit] verify:token passwd:nil param:PublicParam challenge:rand sign:sign[@"signature"]];
            
            NSLog(@"client verify: %d",client_verify);
        }
        else{
            [GlobalEnv alertWithTitle:@"错误" message:@"无法获取挑战"];
        }
    }];
}

- (IBAction)lowRiskAction:(id)sender {
    [self callLowRisk];
}

- (IBAction)logoff:(id)sender {
    BOOL done = [[GlobalEnv env] logoff];
    if (done) {
        LoginViewController *loginViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"LoginView"];
        [self presentViewController:loginViewController animated:YES completion:nil];
    }
}

- (IBAction)algSwitchAction:(id)sender {
    if (_algSwitchBtn.on) {
        fastMode = NO;
    }
    else{
        fastMode = YES;
    }
}

@end
