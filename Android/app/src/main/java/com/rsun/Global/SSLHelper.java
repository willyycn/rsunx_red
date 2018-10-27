package com.rsun.Global;

import android.content.Context;

import java.io.IOException;
import java.io.InputStream;
import java.security.KeyManagementException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.UnrecoverableKeyException;
import java.security.cert.CertificateException;

import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSocketFactory;
import javax.net.ssl.TrustManagerFactory;

/**
 * Created by willyy on 2018/4/7.
 */
public class SSLHelper {
    private final static String CLIENT_PRI_KEY = "demo.pfx";
    private final static String SERVER_CRT_BKS = "demo.bks";
    private final static String CLIENT_PFX_PASSWD = "123456";
    private final static String SERVER_BKS_PASSWD = "123456";
    private final static String CLIENT_STRORE_TYPE = "PKCS12";
    private final static String SERVER_STRORE_TYPE = "BKS";
    private final static String PROTOCOL_TYPE = "TLS";
    private final static String CERTIFICATE_STANDARD = "X509";

    public static SSLSocketFactory getSSLCertifcation(Context context){
        SSLSocketFactory sslSocketFactory = null;
        try{
            // 服务器端需要验证的客户端证书，其实就是客户端的p12
            KeyStore keyStore = KeyStore.getInstance(CLIENT_STRORE_TYPE);
            // 客户端信任的服务器端证书
            KeyStore certStore = KeyStore.getInstance(SERVER_STRORE_TYPE);

            //读取证书
            InputStream ksIn = context.getAssets().open(CLIENT_PRI_KEY);
            InputStream csIn = context.getAssets().open(SERVER_CRT_BKS);

            //加载证书
            keyStore.load(ksIn, CLIENT_PFX_PASSWD.toCharArray());
            certStore.load(csIn, SERVER_BKS_PASSWD.toCharArray());
            ksIn.close();
            csIn.close();

            //初始化SSLContext
            SSLContext sslContext = SSLContext.getInstance(PROTOCOL_TYPE);
            TrustManagerFactory trustManagerFactory = TrustManagerFactory.getInstance(CERTIFICATE_STANDARD);
            KeyManagerFactory keyManagerFactory = KeyManagerFactory.getInstance(CERTIFICATE_STANDARD);
            trustManagerFactory.init(certStore);
            keyManagerFactory.init(keyStore, CLIENT_PFX_PASSWD.toCharArray());
            sslContext.init(keyManagerFactory.getKeyManagers(), trustManagerFactory.getTrustManagers(), null);

            sslSocketFactory = sslContext.getSocketFactory();
        } catch (KeyStoreException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        } catch (CertificateException e) {
            e.printStackTrace();
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
        } catch (UnrecoverableKeyException e) {
            e.printStackTrace();
        } catch (KeyManagementException e) {
            e.printStackTrace();
        }
        return sslSocketFactory;
    }

}
