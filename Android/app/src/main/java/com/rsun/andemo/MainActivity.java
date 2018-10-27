package com.rsun.andemo;

import android.app.AlertDialog;
import android.app.Dialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Switch;
import android.widget.TextView;

import com.rsun.Global.GlobalEnv;
import com.rsun.andemo.Operation.LoginOpHelper;
import com.rsun.kit.RSunKit;

import java.util.Map;

public class MainActivity extends AppCompatActivity {
    private static final String TAG = "MainActivity";
    private Button lowBTN;
    private Button highBTN;
    private Button logoffBTN;
    private Switch algSwitch;
    private int fastMode;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        initUI();
    }

    private void initUI(){
        fastMode = 1;
        lowBTN = findViewById(R.id._mainLowRiskBtn);
        highBTN = findViewById(R.id._mainHighRiskBtn);
        logoffBTN = findViewById(R.id._mainLogoff);
        lowBTN.setOnClickListener(mClickListener);
        highBTN.setOnClickListener(mClickListener);
        logoffBTN.setOnClickListener(mClickListener);
        algSwitch = findViewById(R.id._fastModeSwitch);
        algSwitch.setOnClickListener(mClickListener);
        algSwitch.setChecked(false);
    }
    View.OnClickListener mClickListener = new View.OnClickListener() {
        @Override
        public void onClick(View view) {
            switch (view.getId()){
                case R.id._mainLowRiskBtn:
                    try {
                        lowRiskAction();
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    break;
                case R.id._mainHighRiskBtn:
                    try {
                        highRiskAction();
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    break;
                case R.id._mainLogoff:
                    try {
                        GlobalEnv.getInstance(MainActivity.this).logoff();
                        Intent i = new Intent(MainActivity.this,LoginActivity.class);
                        startActivity(i);
                        MainActivity.this.finish();
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    break;
                case R.id._fastModeSwitch:
                    try {
                        if (algSwitch.isChecked()){
                            fastMode = 0;
                        }
                        else{
                            fastMode = 1;
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    break;
                default:
                    break;
            }
        }
    };
    private void lowRiskAction(){
        final String token = GlobalEnv.getInstance(MainActivity.this).getLoginToken();
        LoginOpHelper.getHelper(MainActivity.this).getChallenge(token, new LoginOpHelper.LoginOpCallback() {
            @Override
            public void onResponse(boolean response) {

            }

            @Override
            public void onFailure(Error error) {

            }

            @Override
            public void challenge(String challenge) {
                String loginKey = GlobalEnv.getInstance(MainActivity.this).getLoginKey();
                Map<String,String> sign = RSunKit.sign(fastMode,loginKey,GlobalEnv.PublicParam,challenge,"");
                LoginOpHelper.getHelper(MainActivity.this).verifySign(token, sign.get("signature"), null, new LoginOpHelper.LoginOpCallback() {
                    @Override
                    public void onResponse(boolean response) {
                        GlobalEnv.getInstance(MainActivity.this).makeAlertDialog(MainActivity.this,"结果","server verify: "+response);
                    }

                    @Override
                    public void onFailure(Error error) {

                    }

                    @Override
                    public void challenge(String challenge) {

                    }
                });
            }
        });
    }

    private Dialog alertDialog;
    private void highRiskAction(){
        LayoutInflater layoutInflater = LayoutInflater.from(this);
        View mSettingView = layoutInflater.inflate(R.layout.tf_edit_setting, null);
        TextView title = (TextView)mSettingView.findViewById(R.id._tf_edit_setting_title);
        title.setText("高安全操作请输入密码");
        final EditText et = (EditText)mSettingView.findViewById(R.id._tf_edit_setting_edit);
        alertDialog = new AlertDialog.Builder(this).
                setView(mSettingView).
                setPositiveButton("确定", new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        // TODO Auto-generated method stub
                        final String passwd = LoginOpHelper.getSaltPasswd(et.getText().toString());
                        final String token = GlobalEnv.getInstance(MainActivity.this).getLoginToken();
                        final String phone = token.split("_")[1];
                        LoginOpHelper.getHelper(MainActivity.this).getChallenge(token, new LoginOpHelper.LoginOpCallback() {
                            @Override
                            public void onResponse(boolean response) {

                            }

                            @Override
                            public void onFailure(Error error) {

                            }

                            @Override
                            public void challenge(final String challenge) {
                                String loginKey = GlobalEnv.getInstance(MainActivity.this).getPrivilegeKey();
                                final Map<String,String> sign = RSunKit.sign(fastMode,loginKey,GlobalEnv.PublicParam,challenge,"");
                                LoginOpHelper.getHelper(MainActivity.this).verifySign(phone+"_"+GlobalEnv.GUID, sign.get("signature"), passwd, new LoginOpHelper.LoginOpCallback() {
                                    @Override
                                    public void onResponse(boolean response) {
                                        GlobalEnv.getInstance(MainActivity.this).makeAlertDialog(MainActivity.this,"结果","server verify: "+response);
                                        int verify = RSunKit.verify(phone+"_"+GlobalEnv.GUID,passwd,GlobalEnv.PublicParam,challenge,sign.get("signature"));
                                        Log.d(TAG, "onCreate: verify : "+verify);
                                    }

                                    @Override
                                    public void onFailure(Error error) {

                                    }

                                    @Override
                                    public void challenge(String challenge) {

                                    }
                                });
                            }
                        });
                    }
                }).
                setNegativeButton("取消", new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        // TODO Auto-generated method stub
                    }
                }).
                create();
        if (!alertDialog.isShowing()) {
            alertDialog.show();
        }

    }
}
