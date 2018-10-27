package com.rsun.Global;

import android.Manifest;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.SharedPreferences;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.support.v4.app.ActivityCompat;
import android.telephony.TelephonyManager;
import android.util.Base64;
import android.util.Log;

import java.io.UnsupportedEncodingException;
import java.security.InvalidAlgorithmParameterException;
import java.security.InvalidKeyException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.UUID;

import javax.crypto.BadPaddingException;
import javax.crypto.Cipher;
import javax.crypto.IllegalBlockSizeException;
import javax.crypto.NoSuchPaddingException;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.SSLSession;

import okhttp3.OkHttpClient;
import retrofit2.Retrofit;


/**
 * Created by willyy on 2018/4/7.
 */
public class GlobalEnv {
    private static final String TAG = "GlobalEnv";
        public static final String ServerUrl = "https://10.10.252.17:4043";
    public static final String PublicParam = "490b8008685bfc33526a50bb26e08bdb08cdb2ecf539e4ba94f05c00f557715cac67bcab3622a4525a08ef29baf4bf6ad3c638bce055df1a40b767ae403469b41906ec44799d57ee171993bc931009ace39b4408a2d18832b82fd496e60edc6c4b1483fdf73eb20d7387646c70c2c98f054b14e68398c0c3b5e2b9de174b70ec01.b3940619ca2b0cdf2851a51ac57a0da188c17073bb32a349f697ae214696007777ee434e2dc4c80af370e42e964717d55e4ad90cb710a6e47ee80f49119d3fecfc6bce38ebcb83df8442a2b1385d4ee2c3ebaa4efa36f47f77589ed2cbdab07c0b52b7751c24accffa9c908d58182b5fd123556b18271602d08506861a9b4a58061394eb322189dcf0df200020e0987cc6b2361a07119b0f2959a1b419c0d6c605a12aeb99f1c62a9250aa8cbaaa3ba4c3c90636344034b58af31691589dfdc92c39ae22534021e62035c619e0cdd842be06d81243afd5bbaa15d52a51fac5bcb2f699949752f03cb17d206efccb7ee986c085950f066a5f2d04eb768b9166d5010001";
//    public static final String PublicParam = "3961f1e2a0a244c89b137eff1c0fbe8dfec2c63bb813a12f2fa0a4d0814668f8991295277d0269e5d8eb39b59cbf1340131523b516dc08403af9d825f9679e576c33ecb13f38c3bb01343defd423986ea8477c898c0a12791ed1521ec08f15936c46372d5f605199eff33f4c8d03657594d956f6ae188cae91f2e8832acb89c801.82de2a0b1ecd5867b8797c515ec6512e83a4089df0a8938e732978df0aa5e7813ea540ad3e83058af9796b3b9ee84d995869e729b3de72fd200d041ee6de07a00c87e5102e0b651cc89d1f1685cb7170cb33cbee14cdff0a52267ccbcc796cdf6c8df99855d63b9003e7764c280e48d5b14b847357924db110c3d3915c262a383c7ad2642002554c81ca17470dfe420721fbfae4646cdb14f513c8226a96e1e0125d20d4a08504884bfc69324b1a796e0a8b3aa757bf769c10eb8ca0be5723f798cf3f00712ed13a6cdcb1d4efb611eaaafbfd5814c4503177a5d5e710e96ae540fd12567409b7ab50ceb7c91e266b239143e73c0db4e49b1726b4e28a7b7db5010001";
    public static String appName;
    public static String packageName;
    public static String appVersion;
    public static String phoneModel;
    public static String phoneBrand;
    public static String OSVersion;
    public static String GUID;

    public static String AESKey;
    public static String IV;

    private static final String UserPref = "RSunPref";
    private static final String GUIDKEY = "RSunGuid";
    private static final String LoginTokenKey = "loginToken";
    private static final String LoginKey = "loginKey";
    private static final String PrivilegeKey = "privilegeKey";

    private Retrofit retrofit;
    private static GlobalEnv mEnv;
    private static SharedPreferences preferences;

    private GlobalEnv(Context context) {
        OkHttpClient okHttpClient = new OkHttpClient.Builder()
                .sslSocketFactory(SSLHelper.getSSLCertifcation(context))
                .hostnameVerifier(new UnSafeHostVerifier())
                .build();

        retrofit = new Retrofit.Builder()
                .baseUrl(ServerUrl)
                .client(okHttpClient)
                .build();

        preferences = context.getSharedPreferences(UserPref,context.MODE_PRIVATE);
        getAppInfo(context);
    }

    public Retrofit getRetrofit() {
        return mEnv.retrofit;
    }

    public static synchronized GlobalEnv getInstance(Context context) {
        if (mEnv == null) {
            mEnv = new GlobalEnv(context);
        }
        return mEnv;
    }

    public static String salt(String salt, String passwd){
        String retStr;
        retStr = passwd+salt;
        retStr = sha256(retStr);
        return retStr;
    }

    public void setLoginToken(String token){
        rawSaveUserData(token,LoginTokenKey);
    }

    public String getLoginToken(){
        return rawLoadUserData(LoginTokenKey);
    }

    public void setLoginKey(String key){
        secSaveUserData(key,LoginKey);
    }

    public String getLoginKey(){
        return secLoadUserData(LoginKey);
    }

    public void setPrivilegeKey(String key){
        secSaveUserData(key,PrivilegeKey);
    }

    public String getPrivilegeKey(){
        return secLoadUserData(PrivilegeKey);
    }

    public void logoff(){
        preferences.edit().remove(LoginTokenKey).apply();
        preferences.edit().remove(LoginKey).apply();
        preferences.edit().remove(PrivilegeKey).apply();
    }

    private static void rawSaveUserData(String data, String key){
        SharedPreferences.Editor prefEditor = preferences.edit();
        prefEditor.putString(key,data);
        prefEditor.apply();
    }

    private static String rawLoadUserData(String key){
        return  preferences.getString(key,"");
    }

    private static void secSaveUserData(String data, String key){
        SharedPreferences.Editor prefEditor = preferences.edit();
        try {
            data = encrypt(data,AESKey,IV);
            prefEditor.putString(key,data);
            prefEditor.apply();
        } catch (InvalidKeyException e) {
            e.printStackTrace();
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
        } catch (NoSuchPaddingException e) {
            e.printStackTrace();
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        } catch (InvalidAlgorithmParameterException e) {
            e.printStackTrace();
        } catch (IllegalBlockSizeException e) {
            e.printStackTrace();
        } catch (BadPaddingException e) {
            e.printStackTrace();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private static String secLoadUserData(String key){
        String data = preferences.getString(key,"");
        try {
            data = decrypt(data,AESKey,IV);
        } catch (InvalidKeyException e) {
            e.printStackTrace();
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
        } catch (NoSuchPaddingException e) {
            e.printStackTrace();
        } catch (InvalidAlgorithmParameterException e) {
            e.printStackTrace();
        } catch (IllegalBlockSizeException e) {
            e.printStackTrace();
        } catch (BadPaddingException e) {
            e.printStackTrace();
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        } catch (Exception e) {
            e.printStackTrace();
        }
        return data;
    }

    public static void makeAlertDialog(Context context, String title, String alertStr){
        makeAlertDialog(context, title, alertStr, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                dialog.dismiss();
            }
        });
    }

    public static void makeAlertDialog(Context context, String title, String alertStr, DialogInterface.OnClickListener listener){
        makeAlertDialog(context,title,alertStr,"OK",false,listener);
    }

    public static void makeAlertDialog(Context context, String title, String alertStr, String positiveStr,boolean haveNagtiveButton, DialogInterface.OnClickListener listener){
        makeAlertDialog(context, title, alertStr, positiveStr,haveNagtiveButton, listener, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                dialog.dismiss();
            }
        });
    }

    public static void makeAlertDialog(Context context, String title, String alertStr, String positiveStr,boolean haveNagtiveButton, DialogInterface.OnClickListener positiveListener, DialogInterface.OnClickListener NagetiveListener){
        AlertDialog.Builder builder = new AlertDialog.Builder(context);
        builder.setMessage(alertStr);
        builder.setTitle(title);
        builder.setPositiveButton(positiveStr,positiveListener);
        if (haveNagtiveButton){
            builder.setNegativeButton("OK", NagetiveListener);
        }
        builder.setCancelable(false);
        builder.create().show();
    }

    public static void getAppInfo(Context context) {
        try {
            GUID = getGUID(context);
            String sha256GUID = sha256(GUID);
            AESKey = sha256GUID.substring(8,40).toUpperCase();
            IV = sha256GUID.substring(40,56).toUpperCase();
            PackageManager packageManager = context.getPackageManager();
            ApplicationInfo applicationInfo = packageManager.getApplicationInfo(context.getPackageName(), 0);
            appName = (String) packageManager.getApplicationLabel(applicationInfo);
            PackageInfo packageInfo = packageManager.getPackageInfo(applicationInfo.packageName, 0);
            appVersion = packageInfo.versionName;
            packageName = packageInfo.packageName;
            phoneModel = android.os.Build.MODEL;
            phoneBrand = android.os.Build.BRAND;
            OSVersion = android.os.Build.VERSION.RELEASE;
        } catch (PackageManager.NameNotFoundException e) {
            e.printStackTrace();
        }
    }

    public static String getRandUUID(Context context){
        SharedPreferences preference = context.getSharedPreferences(UserPref,context.MODE_PRIVATE);
        String identity = preference.getString(GUIDKEY, null);
        if (identity == null) {
            identity = java.util.UUID.randomUUID().toString().toUpperCase();
            preference.edit().putString(GUIDKEY, identity).apply();
        }
        return identity;
    }

    public static String getGUID(Context context){
        String uniqueId = "";
        final TelephonyManager tm = (TelephonyManager) context.getSystemService(Context.TELEPHONY_SERVICE);
        final String tmDevice, tmSerial, tmPhone, androidId;
        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.READ_PHONE_STATE) == PackageManager.PERMISSION_GRANTED) {
            tmDevice = "" + tm.getDeviceId();
            tmSerial = "" + tm.getSimSerialNumber();
            androidId = "" + android.provider.Settings.Secure.getString(context.getContentResolver(), android.provider.Settings.Secure.ANDROID_ID);

            UUID deviceUuid = new UUID(androidId.hashCode(), ((long)tmDevice.hashCode() << 32) | tmSerial.hashCode());
            uniqueId = deviceUuid.toString();
        }
        Log.d(TAG, "getGUID: "+uniqueId);
        return uniqueId;
    }

    public static String sha256(String strSrc) {
        MessageDigest md = null;
        String strDes = null;
        byte[] bt = strSrc.getBytes();
        try {
            String encName = "SHA-256";
            md = MessageDigest.getInstance(encName);
            md.update(bt);
            strDes = bytes2Hex(md.digest()); // to HexString
        } catch (NoSuchAlgorithmException e) {
            return null;
        }
        return strDes;
    }

    public static String bytes2Hex(byte[] bts) {
        String des = "";
        String tmp = null;
        for (int i = 0; i < bts.length; i++) {
            tmp = (Integer.toHexString(bts[i] & 0xFF));
            if (tmp.length() == 1) {
                des += "0";
            }
            des += tmp;
        }
        return des;
    }

    private static String encryptAES(String content, String key, String iv)
            throws InvalidKeyException, NoSuchAlgorithmException,
            NoSuchPaddingException, UnsupportedEncodingException,
            InvalidAlgorithmParameterException, IllegalBlockSizeException, BadPaddingException {

        byte[] byteContent = content.getBytes();

        byte[] enCodeFormat = key.getBytes();
        SecretKeySpec secretKeySpec = new SecretKeySpec(enCodeFormat, "AES");

        byte[] initParam = iv.getBytes();
        IvParameterSpec ivParameterSpec = new IvParameterSpec(initParam);

        Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
        cipher.init(Cipher.ENCRYPT_MODE, secretKeySpec, ivParameterSpec);

        byte[] encryptedBytes = cipher.doFinal(byteContent);

        return new String(encryptedBytes);
    }

    private static String decryptAES(String content, String key, String iv)
            throws InvalidKeyException, NoSuchAlgorithmException,
            NoSuchPaddingException, InvalidAlgorithmParameterException,
            IllegalBlockSizeException, BadPaddingException, UnsupportedEncodingException {

        byte[] encryptedBytes = content.getBytes();

        byte[] enCodeFormat = key.getBytes();
        SecretKeySpec secretKey = new SecretKeySpec(enCodeFormat, "AES");

        byte[] initParam = iv.getBytes();
        IvParameterSpec ivParameterSpec = new IvParameterSpec(initParam);

        Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
        cipher.init(Cipher.DECRYPT_MODE, secretKey, ivParameterSpec);

        byte[] result = cipher.doFinal(encryptedBytes);

        return new String(result);
    }

    public static String encrypt(String encData ,String key,String ivStr) throws Exception {

        if(key == null) {
            return null;
        }
        if(key.length() != 32) {
            return null;
        }
        Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
        byte[] raw = key.getBytes();
        SecretKeySpec skeySpec = new SecretKeySpec(raw, "AES");
        IvParameterSpec iv = new IvParameterSpec(ivStr.getBytes());
        cipher.init(Cipher.ENCRYPT_MODE, skeySpec, iv);
        byte[] encrypted = cipher.doFinal(encData.getBytes("utf-8"));

        return Base64.encodeToString(encrypted,Base64.NO_WRAP);
    }

    public static String decrypt(String sSrc,String key,String ivs) throws Exception {
        try {
            byte[] raw = key.getBytes("UTF8");
            SecretKeySpec skeySpec = new SecretKeySpec(raw, "AES");
            Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
            IvParameterSpec iv = new IvParameterSpec(ivs.getBytes());
            cipher.init(Cipher.DECRYPT_MODE, skeySpec, iv);
            byte[] encrypted1 = Base64.decode(sSrc,Base64.NO_WRAP);
            byte[] original = cipher.doFinal(encrypted1);
            String originalString = new String(original, "UTF8");
            return originalString;
        } catch (Exception ex) {
            return null;
        }
    }

    private class UnSafeHostVerifier implements HostnameVerifier {

        @Override
        public boolean verify(String s, SSLSession sslSession) {
            return true;
        }
    }
}
