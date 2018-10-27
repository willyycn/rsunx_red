/**
 * Created by willyy on 2017/2/22.
 * 此脚本展示了如何集成rsun api. 在内网情况下, 业务服务器和R-Sun-Server不必使用双向认证,
 * 但是在其他环境下, 建议业务服务器和R-Sun-Server要建立双向认证, 具体如何建立双向认证可以查看相关文档.
 */
let config = require('../config'),
    app_url = config.get('rsun_srv'),
    app_port = config.get('rsun_port');
let http = require('http');
let qs = require("querystring");
let rsun_path = "/hades?cmd=";
let api_pwd = "38148a57d6c7f32c";

/**
 * 获取系统随机数
 * @param callback (rand,error)
 */
exports.getRand = function(callback){
    let options = {
        host: app_url,
        port: app_port,
        path: rsun_path+'c',
        method: 'GET'
    }

    let req = http.request(options,function(res){
       res.on('data', function(d){
           let obj = JSON.parse(d);
           let rand = obj.rand;
           callback(rand);
       });
    });
    req.on('error',function(e){
        callback("",e);
    });
    req.end();
}

/**
 * 获取系统参数数
 * @param callback (param,error)
 */
exports.getParam = function(callback){
    let options = {
        host: app_url,
        port: app_port,
        path: rsun_path+'p',
        method: 'GET'
    }

    let req = http.request(options,function(res){
        res.on('data', function(d){
            let obj = JSON.parse(d);
            let para = obj.para;
            callback(para);
        });
    });
    req.on('error',function(e){
        callback("",e);
    });
    req.end();
}

/**
 * 根据token生成私钥
 * @param token
 * @param passwd
 * @param callback (私钥, error)
 */
exports.getKey = function(token, passwd, callback){
    let form = {
        token : token,
        passwd : passwd,
        api_pwd : api_pwd
    };
    let bodyString = qs.stringify(form);
    let headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Cache-Control': 'no-cache'
    };
    let options = {
        host: app_url,
        port: app_port,
        path: rsun_path+'r',
        method: 'POST',
        headers:  headers,
        form: form
    };

    let req = http.request(options, function(res) {
        res.on('data', function(d) {
            let obj = JSON.parse(d);
            callback(obj.private, obj.err);
        });
    });
    req.write(bodyString);
    req.on('error', function(e) {
        callback("", e);
    });
    req.end();
}

/**
 * 根据信息验签
 * @param token
 * @param sign
 * @param challenge
 * @param passwd
 * @param callback (verify, error)
 */
exports.verify = function(token, sign, challenge, passwd, callback){
    let body = {
        token : token,
        signature : sign,
        challenge : challenge,
        passwd : passwd,
        api_pwd : api_pwd
    };
    let bodyString = qs.stringify(body);
    let headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Cache-Control': 'no-cache'
    };
    let options = {
        host: app_url,
        port: app_port,
        path: rsun_path+'f',
        method: 'POST',
        headers:  headers,
        form: body
    };

    let req = http.request(options, function(res) {
        res.on('data', function(d) {
            let obj = JSON.parse(d);
            callback(obj.verify,obj.err);
        });
    });
    req.write(bodyString);
    req.on('error', function(e) {
        callback("", e);
    });
    req.end();
}

/**
 * 获取交换秘钥对封装
 * @param ctrl
 * @param callback (pubkey,privatekey,pubkey_sign, error)
 */
exports.new_pair = function(ctrl, callback){
    let body = {
        level : ctrl,
        api_pwd : api_pwd
    };
    let bodyString = qs.stringify(body);
    let headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Cache-Control': 'no-cache'
    };
    let options = {
        host: app_url,
        port: app_port,
        path: rsun_path+'n',
        method: 'POST',
        headers:  headers,
        form: body
    };

    let req = http.request(options, function(res) {
        let data = '';
        res.on('data', function(d) {
            console.log(d.length);
            data+=d;
        });
        res.on('end', function () {
            let obj = JSON.parse(data);
            callback(obj.public_key,obj.private_key,obj.public_key_signature,null);
        });
    });
    req.write(bodyString);
    req.on('error', function(e) {
        callback("","","", e);
    });
    req.end();
}

/**
 * 加解密封装
 * @param ctrl
 * @param input
 * @param key
 * @param callback
 */
exports.cipher = function(ctrl,input,key, callback){
    let body = {
        mode : ctrl,
        text:input,
        key:key,
        api_pwd : api_pwd
    };
    let bodyString = qs.stringify(body);
    let headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Cache-Control': 'no-cache'
    };
    let options = {
        host: app_url,
        port: app_port,
        path: rsun_path+'e',
        method: 'POST',
        headers:  headers,
        form: body
    };

    let req = http.request(options, function(res) {
        let data = '';
        res.on('data', function(d) {
            data+=d;
        });
        res.on('end', function () {
            let obj = JSON.parse(data);
            if (ctrl==0){
                callback(obj.plain_str,obj.status,null);
            }
            else if (ctrl == 1){
                callback(obj.cipher_str,obj.status,null);
            }
            else{
                callback("","","wrong ctrl input");
            }
        });
    });
    req.write(bodyString);
    req.on('error', function(e) {
        callback("","", e);
    });
    req.end();
}
