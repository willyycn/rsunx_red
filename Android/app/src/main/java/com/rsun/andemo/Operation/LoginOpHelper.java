package com.rsun.andemo.Operation;

import android.content.Context;
import android.util.Log;

import com.rsun.Global.GlobalEnv;
import com.rsun.andemo.inf.RSunApi;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;

import okhttp3.ResponseBody;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class LoginOpHelper {
    private static final String TAG = "LoginOpHelper";

    private static LoginOpHelper mHelper = null;

    private Context mContext;

    private LoginOpHelper(Context context) {
        mContext = context;
    }

    public static LoginOpHelper getHelper(Context context) {
        if (mHelper == null) {
            mHelper = new LoginOpHelper(context);
        }

        return mHelper;
    }

    /**
     * 设计一个token 格式 以便登陆业务可以使用
     * token = android+phoneNumber+uuid+Brand+OSVersion+appName+appVersion+expireTime
     */
    public static String genLoginTokenSeed(String phone){
        String token = "";
        if (GlobalEnv.GUID.length()!=0){
            token = "android"+"_"+phone+"_"+ GlobalEnv.GUID+"_"+GlobalEnv.phoneBrand+"_"+GlobalEnv.OSVersion+"_"+GlobalEnv.packageName+"_"+GlobalEnv.appVersion;
        }
        return token;
    }
    public static String getSaltPasswd(String passwd){
        return GlobalEnv.salt(GlobalEnv.GUID,passwd);
    }

    public interface LoginOpCallback{
        void onResponse(boolean response);
        void onFailure(Error error);
        void challenge(String challenge);
    }

    public void getAuthCode(String phone, final LoginOpCallback callback){
        Call<ResponseBody> challenge = GlobalEnv.getInstance(mContext).getRetrofit().create(RSunApi.class).getAuthCode(phone);
        challenge.enqueue(new Callback<ResponseBody>() {
            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {

                String t;
                try {
                    t = response.body().string();
                    try {
                        JSONObject jsonResponse = new JSONObject(t);
                        boolean codeSend = jsonResponse.getBoolean("codeSend");
                        callback.onResponse(codeSend);
                    } catch (JSONException e) {
                        e.printStackTrace();
                    }
                } catch (IOException e) {
                    e.printStackTrace();
                }

            }
            @Override
            public void onFailure(Call<ResponseBody> call, Throwable throwable) {
                callback.onFailure(new Error("连接失败"));
            }
        });
    }

    public void registerUser(final String phone, final String passwd, final String authCode, final LoginOpCallback callback){
        String TokenSeed = genLoginTokenSeed(phone);
        if (TokenSeed.length()==0){
            Log.d(TAG, "registerUser: fail to generate token seed");
            return;
        }
        Call<ResponseBody> getLoginTokenQueue = GlobalEnv.getInstance(mContext).getRetrofit().create(RSunApi.class).getLoginToken(TokenSeed);
        getLoginTokenQueue.enqueue(new Callback<ResponseBody>() {
            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {
                String t;
                try {
                    t = response.body().string();
                    try {
                        JSONObject jsonResponse = new JSONObject(t);
                        String token = jsonResponse.getString("token");
                        GlobalEnv.getInstance(mContext).setLoginToken(token);
                        Call<ResponseBody> registerUserQueue = GlobalEnv.getInstance(mContext).getRetrofit().create(RSunApi.class).registerUser(phone,token,passwd,authCode);
                        registerUserQueue.enqueue(new Callback<ResponseBody>() {
                            @Override
                            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {
                                String r;
                                try {
                                    r = response.body().string();
                                    try {
                                        JSONObject jsonObject = new JSONObject(r);
                                        String lowKey = jsonObject.getString("low");
                                        String highKey = jsonObject.getString("high");
                                        GlobalEnv.getInstance(mContext).setLoginKey(lowKey);
                                        GlobalEnv.getInstance(mContext).setPrivilegeKey(highKey);
                                        callback.onResponse(true);
                                    } catch (JSONException e) {
                                        e.printStackTrace();
                                    }
                                } catch (IOException e) {
                                    e.printStackTrace();
                                }
                            }

                            @Override
                            public void onFailure(Call<ResponseBody> call, Throwable t) {
                                callback.onFailure(new Error("连接失败"));
                            }
                        });
                    } catch (JSONException e) {
                        e.printStackTrace();
                    }
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                callback.onFailure(new Error("连接失败"));
            }
        });
    }

    public void getChallenge(final String token, final LoginOpCallback callback){
        Call<ResponseBody> getChallengeQueue = GlobalEnv.getInstance(mContext).getRetrofit().create(RSunApi.class).getChallenge(token);
        getChallengeQueue.enqueue(new Callback<ResponseBody>() {
            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {
                String t;
                try {
                    t = response.body().string();
                    try {
                        JSONObject jsonResponse = new JSONObject(t);
                        String rand = jsonResponse.getString("rand");
                        callback.challenge(rand);
                    } catch (JSONException e) {
                        e.printStackTrace();
                    }
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                callback.onFailure(new Error("连接失败"));
            }
        });
    }

    public void verifySign(final String token, final String sign, final String passwd, final LoginOpCallback callback){
        String pwd;
        if (passwd==null){
            pwd = "";
        }
        else{
            pwd = passwd;
        }
        Call<ResponseBody> verifySignQueue = GlobalEnv.getInstance(mContext).getRetrofit().create(RSunApi.class).verifySign(token,sign,pwd);
        verifySignQueue.enqueue(new Callback<ResponseBody>() {
            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {
                String t;
                try {
                    t = response.body().string();
                    try {
                        JSONObject jsonResponse = new JSONObject(t);
                        boolean verify = jsonResponse.getBoolean("verify");
                        callback.onResponse(verify);
                    } catch (JSONException e) {
                        e.printStackTrace();
                    }
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                callback.onFailure(new Error("连接失败"));
            }
        });
    }
}
