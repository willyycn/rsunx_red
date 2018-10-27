//
//  ViewController.m
//  iOSDemo
//
//  Created by willyy on 2018/5/29.
//  Copyright © 2018年 willyy. All rights reserved.
//

#import "LoginViewController.h"
#import "MainViewController.h"
#import "LoginOpHelper.h"
#import "Global/GlobalEnv.h"
@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *PhoneTF;
@property (weak, nonatomic) IBOutlet UITextField *AuthCodeTF;
@property (weak, nonatomic) IBOutlet UITextField *PasswdTF;
@property (weak, nonatomic) IBOutlet UITextField *VerifyPasswdTF;
@property (weak, nonatomic) IBOutlet UIButton *authCodeBtn;
- (IBAction)getAuthCode:(id)sender;
- (IBAction)registerUser:(id)sender;
@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)getAuthCode:(id)sender {
    if (!_authCodeBtn.selected) {
        [[LoginOpHelper sharedHandler] getAuthCode:_PhoneTF.text handler:^(NSDictionary *res, NSError *error) {
            BOOL codeSend = [res[@"codeSend"] boolValue];
            if (codeSend) {
                [GlobalEnv alertWithTitle:@"警告" message:@"为简化Demo, 请在验证码框内输入 123123"];
                [self->_authCodeBtn setSelected:YES];
                [self->_authCodeBtn setBackgroundColor:[UIColor whiteColor]];
            }
        }];
    }
}

- (IBAction)registerUser:(id)sender {
    if (![_PasswdTF.text isEqualToString:_VerifyPasswdTF.text]) {
        [GlobalEnv alertWithTitle:@"错误" message:@"密码不一样"];
        return;
    }
    if (self.authCodeBtn.selected) {
        [[LoginOpHelper sharedHandler] registerUser:_PhoneTF.text passwd:[LoginOpHelper getSaltPasswd:_PasswdTF.text] authCode:_AuthCodeTF.text handler:^(BOOL success, NSString *error) {
            if (success) {
                [GlobalEnv alertWithTitle:@"提示" message:@"注册成功"];
                MainViewController *mainViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"MainView"];
                [self presentViewController:mainViewController animated:YES completion:nil];
            }
            else{
                [GlobalEnv alertWithTitle:@"错误" message:error];
            }
        }];
    }
    else{
        [GlobalEnv alertWithTitle:@"错误" message:@"请点击验证码按钮"];
    }
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
     [self.view endEditing:YES];
}

@end
