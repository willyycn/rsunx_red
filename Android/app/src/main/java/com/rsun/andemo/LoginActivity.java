package com.rsun.andemo;

import android.Manifest;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.support.annotation.NonNull;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;

import com.rsun.Global.GlobalEnv;
import com.rsun.andemo.Operation.LoginOpHelper;


public class LoginActivity extends AppCompatActivity {
    private EditText phoneET;
    private EditText authCodeET;
    private EditText passwdET;
    private EditText cpasswdET;
    private Button authCodeBTN;
    private Button registerBTN;

    private Context context;
    private static final String TAG = "LoginActivity";
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_login);
        initUI();
        checkPermission();
    }

    View.OnClickListener mClickListener = new View.OnClickListener() {
        @Override
        public void onClick(View view) {
            switch (view.getId()) {
                case R.id._authCode:
                    authCode();

                    break;
                case R.id._register:
                    register();

                    break;
                default:
                    break;
            }
        }
    };

    private void register(){
        if (!passwdET.getText().toString().equalsIgnoreCase(cpasswdET.getText().toString())){
            GlobalEnv.makeAlertDialog(LoginActivity.this,"警告","密码不一样");
            return;
        }
        if (!authCodeBTN.isClickable()){
            LoginOpHelper.getHelper(context).registerUser(phoneET.getText().toString(), LoginOpHelper.getSaltPasswd(passwdET.getText().toString()), authCodeET.getText().toString(), new LoginOpHelper.LoginOpCallback() {
                @Override
                public void onResponse(boolean response) {
                    if (response){
                        GlobalEnv.makeAlertDialog(LoginActivity.this,"提示","注册成功");
                        Intent i = new Intent(context,MainActivity.class);
                        startActivity(i);
                    }
                }

                @Override
                public void onFailure(Error error) {

                }

                @Override
                public void challenge(String challenge) {

                }
            });
        }
    }

    private void authCode(){
        authCodeBTN.setClickable(false);
        try {
            LoginOpHelper.getHelper(getApplicationContext()).getAuthCode(phoneET.getText().toString(), new LoginOpHelper.LoginOpCallback() {
                @Override
                public void onResponse(boolean response) {
                    if (response){
                        GlobalEnv.makeAlertDialog(LoginActivity.this,"警告","为简化Demo, 请在验证码框内输入 123123");
                    }
                }

                @Override
                public void onFailure(Error error) {

                }

                @Override
                public void challenge(String challenge) {

                }
            });
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void initUI(){
        context = getApplicationContext();
        phoneET = findViewById(R.id._loginPhone);
        authCodeET = findViewById(R.id._loginAuthcode);
        passwdET = findViewById(R.id._loginPasswd);
        cpasswdET = findViewById(R.id._loginConfirmPasswd);
        authCodeBTN = findViewById(R.id._authCode);
        registerBTN = findViewById(R.id._register);
        authCodeBTN.setOnClickListener(mClickListener);
        registerBTN.setOnClickListener(mClickListener);
    }
    private int REQUEST_IMEI_PERMISSION = 1;
    private void checkPermission(){
        if(ContextCompat.checkSelfPermission(this,"Manifest.permission.READ_PHONE_STATE")
                != PackageManager.PERMISSION_GRANTED)
        {
            ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.READ_PHONE_STATE},REQUEST_IMEI_PERMISSION);
        }
    }
    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        //The data is returned to null when the request permission is canceled in the monkey test
        if(grantResults==null)return;

        if (requestCode == REQUEST_IMEI_PERMISSION) {
            if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                //permission granted
                if (GlobalEnv.GUID.length()==0){
                    GlobalEnv.getAppInfo(context);
                }
            } else {
                //permission denied
                //TODO 显示对话框告知用户必须打开权限
                GlobalEnv.makeAlertDialog(LoginActivity.this,"警告","未获取权限, 无法生成UUID, 即将退出程序, 请去设置打开权限", "确认", false, new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialogInterface, int i) {
                        finish();
                    }
                });
            }
        }
    }
}
