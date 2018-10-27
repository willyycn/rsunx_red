package com.rsun.andemo;

import android.content.Intent;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;

import com.rsun.Global.GlobalEnv;

public class LoadingActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_loading);
        String LoginKey = GlobalEnv.getInstance(getApplicationContext()).getLoginKey();
        if (LoginKey.length()>0){
            Intent i = new Intent(LoadingActivity.this,MainActivity.class);
            startActivity(i);
            this.finish();
        }
        else{
            Intent i = new Intent(LoadingActivity.this,LoginActivity.class);
            startActivity(i);
            this.finish();
        }
    }
}
