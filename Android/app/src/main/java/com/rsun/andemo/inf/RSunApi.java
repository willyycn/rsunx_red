package com.rsun.andemo.inf;

import okhttp3.ResponseBody;
import retrofit2.Call;
import retrofit2.http.Field;
import retrofit2.http.FormUrlEncoded;
import retrofit2.http.GET;
import retrofit2.http.POST;
import retrofit2.http.Path;
import retrofit2.http.Query;

public interface RSunApi {

    @GET("/demo/authCode")
    Call<ResponseBody> getAuthCode(@Query("phone") String phone);

    @GET("/demo/getLoginToken")
    Call<ResponseBody> getLoginToken(@Query("seed") String seed);

    @POST("/demo/registerUser")
    @FormUrlEncoded
    Call<ResponseBody> registerUser(@Field("phone") String phone, @Field("token") String token, @Field("passwd") String passwd, @Field("authCode") String authCode);

    @GET("/demo/challenge")
    Call<ResponseBody> getChallenge(@Query("token") String token);

    @POST("/demo/verify")
    @FormUrlEncoded
    Call<ResponseBody> verifySign(@Field("token") String token,@Field("sign") String sign,@Field("passwd") String passwd);

    @GET("/demo/{api_path}")
    Call<ResponseBody> get(@Path("api_path") String api_path);

}
