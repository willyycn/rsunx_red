/**
 * Created by willyy on 2017/3/1.
 */
let express = require('express');
let crypto = require('crypto');
let router = express.Router();
let log = require('../core/log')(module);
let rsun = require('../core/rsunx');
let redis = require('../core/kv_cli');
let aes = require('../core/aes');
router.use(function (req, res, next) {
    log.info('request from : '+ req.originalUrl+ ' Method: '+ req.method + ' Time: '+ Date.now());
    console.log("session id: "+req.session.id);
    next();
});

function uuid(len, radix) {
    let chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'.split('');
    let uuid = [], i;
    radix = radix || chars.length;

    if (len) {
        for (i = 0; i < len; i++) uuid[i] = chars[0 | Math.random()*radix];
    } else {
        let r;
        uuid[8] = uuid[13] = uuid[18] = uuid[23] = '-';
        uuid[14] = '4';
        for (i = 0; i < 36; i++) {
            if (!uuid[i]) {
                r = 0 | Math.random()*16;
                uuid[i] = chars[(i == 19) ? (r & 0x3) | 0x8 : r];
            }
        }
    }
    return uuid.join('');
}

//1~3
let validTime = 7*24*3600*1000;
let validPeriod = 3600*24*7;

/**
 * 通过token来判断是否发送挑战
 */
function getPhoneFromToken(token) {
    return JSON.parse(token).phone;
}
function getExpireFromToken(token) {
    return JSON.parse(token).expire;
}
function getTokenIDFromToken(token) {
    return JSON.parse(token).tokenid;
}
function getCUIDFromToken(token) {
    return JSON.parse(token).cuid;
}

/**
 * 获取交互秘钥公钥
 */
router.get('/exc_key', function (req,res) {
    let ctrl = req.query.ctrl;
    if (ctrl==0){
        redis.getRedis("srv0_pubkeySign",function (err, pubkeySign) {
            if (!err){
                if (!pubkeySign){
                    rsun.new_pair(ctrl, function (public_key,private_key,public_key_signature,err) {
                        if (!err){
                            if (redis.setRedis("srv_privateKey",private_key,validPeriod/7)){
                                if (redis.setRedis("srv_publicKey",public_key,validPeriod/7)){
                                    if (redis.setRedis("srv0_pubkeySign",public_key_signature,validPeriod/7)){
                                        res.json({
                                            status:0,
                                            publicKey: public_key,
                                            pubkeySign: public_key_signature
                                        });
                                    }
                                    else{
                                        res.json({ status:1,error: "internal err1"});
                                    }
                                }
                                else{
                                    res.json({ status:1,error: "internal err2"});
                                }
                            }
                            else{
                                res.json({ status:1,error: "internal err3"});
                            }
                        }
                        else{
                            res.json({
                                status:1,
                                error: err
                            });
                        }
                    })
                }
                else{
                    redis.getRedis("srv_publicKey", function (err, publicKey) {
                        res.json({
                            status:0,
                            publicKey: publicKey,
                            pubkeySign: pubkeySign
                        });
                    })
                }
            }
            else{
                res.json({ status:1,error:err});
            }
        })
    }
    else if (ctrl==1){
        redis.getRedis("srv1_pubkeySign",function (err, pubkeySign) {
            if (!err){
                if (!pubkeySign){
                    rsun.new_pair(ctrl, function (public_key,private_key,public_key_signature,err) {
                        if (!err){
                            if (redis.setRedis("srv_privateKey",private_key,validPeriod/7)){
                                if (redis.setRedis("srv_publicKey",public_key,validPeriod/7)){
                                    if (redis.setRedis("srv1_pubkeySign",public_key_signature,validPeriod/7)){
                                        res.json({
                                            status:0,
                                            publicKey: public_key,
                                            pubkeySign: public_key_signature
                                        });
                                    }
                                    else{
                                        res.json({ status:1,error: "internal err1"});
                                    }
                                }
                                else{
                                    res.json({ status:1,error: "internal err2"});
                                }
                            }
                            else{
                                res.json({ status:1,error: "internal err3"});
                            }
                        }
                        else{
                            res.json({
                                status:1,
                                error: err
                            });
                        }
                    })
                }
                else{
                    redis.getRedis("srv_publicKey", function (err, publicKey) {
                        res.json({
                            status:0,
                            publicKey: publicKey,
                            pubkeySign: pubkeySign
                        });
                    })
                }
            }
            else{
                res.json({ status:1, error:err});
            }
        })
    }
});

/**
 * 同步共享秘钥
 */
router.post('/syn_key', function (req,res) {
    let ctext = req.body.ctext;
    let sessionid = req.session.id;
    redis.getRedis("srv_privateKey", function (err, privateKey) {
        if (!err){
            if (!privateKey){
                res.json({
                    status:2,
                    error:"key expired"
                })
            }
            rsun.cipher(0,ctext,privateKey,function (text, status, error) {
                if (status == 0){
                    const sharekey = text;
                    res.json({
                        status:0,
                        valid:redis.setRedis(sessionid+"sharedKey",sharekey,validPeriod/7)
                    });
                }
                else{
                    res.json({
                        status:2,
                        error:error
                    })
                }
            })
        }
        else {
            res.json({
                status:1,
                error:err
            })
        }
    })
});

/**
 * 添加黑名单
 */
router.post('/bl_add', function (req, res) {
    let phone = req.body.phone;
    let token = req.body.token;
    let tokeStr = JSON.stringify(token);
    redis.sremRedis(phone+"tokens",tokeStr,function (err, value) {
        if (!err){
            if (value==1){
                let tokenid = getTokenIDFromToken(token);
                redis.saddRedis(phone+"blacklist",tokenid, validTime,function (err, relpy) {
                    if (relpy===1){
                        res.json({
                            status:0,
                            blacklist:tokenid
                        });
                    }
                    else{
                        if(err){
                            res.json({
                                status:1,
                                error:err
                            });
                        }
                        else{
                            res.json({
                                status:1,
                                error:"已是黑名单ID"
                            });
                        }
                    }
                });
            }
            else{
                res.json({
                    status:1,
                    error:"Token已删除"
                });
            }
        }
        else{
            res.json({
                status:1,
                error:err
            });
        }
    })

});

/**
 * 搜索黑名单
 */
router.post('/bl_search', function (req, res) {
    let phone = req.body.phone;
    redis.smembersRedis(phone+"blacklist",function (err, keys) {
        if (!err){
            res.json({
                status:0,
                blacklist:keys
            });
        }
        else{
            res.json({
                status:1,
                error:err
            });
        }

    });
});

/**
 * phone名下tokenid
 */
router.post('/tk_search', function (req, res) {
    let phone = req.body.phone;
    redis.smembersRedis(phone+"tokens",function (err, keys) {
        if (!err){
            res.json({
                status:0,
                tokenid:keys
            });
        }
        else{
            res.json({
                status:1,
                error:err
            });
        }

    });
});

/**
 * 删除blacklist里对应的tokenid
 */
router.post('/bl_rem', function (req, res) {
    let tokenid = req.body.tokenid;
    let phone = req.body.phone;
    redis.sremRedis(phone+"blacklist",tokenid,function (err, value) {
        if (!err){
            res.json({
                status:0,
                value:value
            });
        }
        else{
            res.json({
                status:1,
                error:err
            });
        }

    });
});

/**
 * 通过手机号来做二次验证用的验证码服务
 */
router.get('/authCode',function (req,res) {
    let phone = req.query.phone;
    let sessionid = req.session.id;
    redis.getRedis(sessionid+"sharedKey", function (err, key) {
        if (!err){
            phone = aes.aesDecrypt(phone,key);
            //todo: 这里需要集成短信验证码等第三方服务, 将发送的手机号+"auth"和验证码以kv形式存于kv数据库".
            let authCode = uuid(4,10);
            redis.setRedis(phone + "auth",authCode,60);
            res.json({
                status:0,
                code:aes.aesEncrypt(authCode,key)
            })
        }
        else{
            res.json({error:err,status:1});
        }
    });
});

/**
 * 删除token
 */
router.post('/logoff',function (req,res) {
    let token = req.body.token;
    let sign = req.body.sign;
    let sessionid = req.session.id;
    redis.getRedis(sessionid+"sharedKey", function (err, key) {
        if (!err)
        {
            token = aes.aesDecrypt(token,key);
            sign = aes.aesDecrypt(sign,key);

            /*从kv中取challenge*/
            let phone = getPhoneFromToken(token);
            let tokenid = getTokenIDFromToken(token);
            //不能为黑名单ID
            redis.sismemberRedis(phone+"blacklist", tokenid, function (err, value) {
                if (!err){
                    if (value == 0)
                    {
                        redis.getRedis(tokenid, function (err, reply) {
                            if (err){
                                res.json({
                                    status:aes.aesEncrypt("1",key),
                                    error: aes.aesEncrypt(err,key)
                                })
                            }
                            else{
                                redis.delRedis(tokenid,function (err, value) {
                                    rsun.verify(token, sign, reply, null, function(v, e){
                                        if (v==1){
                                            let tokeStr = JSON.stringify(token);
                                            redis.sremRedis(phone+"tokens", tokeStr, function (err, value) {
                                                if (!err){
                                                    if (value == 1)
                                                    {
                                                        let cv = v.toString();
                                                        res.json({
                                                            status: aes.aesEncrypt("0",key),
                                                            verify: aes.aesEncrypt(cv,key),
                                                            error: aes.aesEncrypt(e,key)
                                                        })
                                                    }
                                                    else{
                                                        res.json({
                                                            status:aes.aesEncrypt("0",key),
                                                            error: aes.aesEncrypt("已删除TOKEN",key)
                                                        });
                                                    }
                                                }
                                                else{
                                                    res.json({
                                                        status:aes.aesEncrypt("1",key),
                                                        error: aes.aesEncrypt(err,key)
                                                    });
                                                }
                                            });
                                        }
                                    });
                                });
                            }
                        });
                    }
                    else{
                        res.json({
                            status:aes.aesEncrypt("2",key),
                            error: aes.aesEncrypt("黑名单ID",key)
                        });
                    }
                }
                else{
                    res.json({
                        status:aes.aesEncrypt("1",key),
                        error: aes.aesEncrypt(err,key)
                    });
                }
            });
        }
        else {
            res.json({
                status:aes.aesEncrypt("1",key),
                error: aes.aesEncrypt(err,key)
            });
        }
    });
});

/**
 * 获取挑战
 */
router.get('/challenge',function (req,res) {
    let token = req.query.token;
    let sessionid = req.session.id;
    redis.getRedis(sessionid+"sharedKey", function (err, key) {
        if (!err && key){
            token = aes.aesDecrypt(token,key);
            //检查此token是否在黑名单内
            try{
                let tokenObj = JSON.parse(token);
                let tokenid = tokenObj.tokenid;
                let phone = tokenObj.phone;
                redis.sismemberRedis(phone+"blacklist",tokenid,function (err, value) {
                    if (value===1){
                        res.json({
                            status:2,
                            error:"黑名单ID"
                        });
                    }
                    else{
                        let expireDate = tokenObj.expire;
                        let eDate = parseInt(expireDate);
                        let date = new Date().getTime();
                        if (date>eDate){
                            res.json({
                                status:2,
                                error:"过期"
                            });
                        }
                        else if(date<=eDate&&date>eDate-2){
                            rsun.getRand(function(challenge, error){
                                /*使用kv数据库保存token和challenge*/
                                redis.setRedis(tokenid,challenge);
                                res.json({
                                    status:0,
                                    rand:aes.aesEncrypt(challenge,key),
                                    error:"即将过期"
                                });
                            });
                        }
                        else{
                            rsun.getRand(function(challenge, error){
                                /*使用kv数据库保存token和challenge*/
                                redis.setRedis(tokenid,challenge);
                                res.json({
                                    status:0,
                                    rand:aes.aesEncrypt(challenge,key),
                                    error:error
                                });
                            });
                        }
                    }
                })
            }
            catch (objError) {
                if (objError instanceof SyntaxError) {
                    res.json({error:objError.name,status:1});
                } else {
                    res.json({error:objError.message,status:1});
                }
            }
        }
        else{
            res.json({error:err,status:1});
        }
    })
});

/**
 * 验签
 */
router.post('/verify',function (req,res) {
    let token = req.body.token;
    let sign = req.body.sign;
    let passwd = req.body.passwd;
    let sessionid = req.session.id;
    redis.getRedis(sessionid+"sharedKey", function (err, key) {
        if (!err)
        {
            token = aes.aesDecrypt(token,key);
            sign = aes.aesDecrypt(sign,key);
            passwd = aes.aesDecrypt(passwd,key);

            /*从kv中取challenge*/
            let phone = getPhoneFromToken(token);
            let tokenid = getTokenIDFromToken(token);
            let cuid = getCUIDFromToken(token);
            //tokenid必须在phone+"tokenid"里面
            redis.sismemberRedis(phone+"tokens", token, function (err, value) {
                if (!err){
                    if (value == 1)
                    {
                        //tokenid不能在phone+"blacklist"里面
                        redis.sismemberRedis(phone+"blacklist", tokenid, function (err, value) {
                            if (!err){
                                if (value == 0)
                                {
                                    redis.getRedis(tokenid, function (err, reply) {
                                        if (err){
                                            res.json({
                                                status:aes.aesEncrypt("1",key),
                                                error: aes.aesEncrypt(err,key)
                                            })
                                        }
                                        else{
                                            redis.delRedis(tokenid,function (err, value) {
                                                rsun.verify(token, sign, reply, passwd, function(v, e){
                                                    let cv = v.toString();
                                                    res.json({
                                                        status: aes.aesEncrypt("0",key),
                                                        verify: aes.aesEncrypt(cv,key),
                                                        error: aes.aesEncrypt(e,key)
                                                    })
                                                });
                                            });
                                        }
                                    });
                                }
                                else{
                                    res.json({
                                        status:aes.aesEncrypt("2",key),
                                        error: aes.aesEncrypt("黑名单ID",key)
                                    });
                                }
                            }
                            else{
                                res.json({
                                    status:aes.aesEncrypt("1",key),
                                    error: aes.aesEncrypt(err,key)
                                });
                            }
                        });
                    }
                    else{
                        res.json({
                            status:aes.aesEncrypt("1",key),
                            error: aes.aesEncrypt("过期TOKEN",key)
                        });
                    }
                }
                else{
                    res.json({
                        status:aes.aesEncrypt("1",key),
                        error: aes.aesEncrypt(err,key)
                    });
                }
            });
        }
        else {
            res.json({
                status:aes.aesEncrypt("1",key),
                error: aes.aesEncrypt(err,key)
            });
        }
    });
});

/**
 * 用户注册
 */
router.post('/register', function (req, res) {
    let seed = req.body.seed;
    let passwd = req.body.passwd;
    let code = req.body.authCode;
    let sessionid = req.session.id;
    redis.getRedis(sessionid+"sharedKey", function (err, key) {
        if (!err){
            seed = aes.aesDecrypt(seed,key);
            rsun.getRand(function(rand, error){
                if (!error){
                    const sha1 = crypto.createHash('SHA1');
                    rand = sha1.update(rand).digest("hex");
                    let tokenid = rand.toLocaleLowerCase();
                    let expireTime = new Date().getTime();
                    let expire = expireTime + validTime;
                    try{
                        let token = JSON.parse(seed);
                        let phone = token.phone;
                        token.tokenid = tokenid;
                        token.expire = expire;
                        let tokenStr = JSON.stringify(token);
                        redis.saddRedis(phone+"tokens",tokenStr,validTime,function (err, relpy) {
                            if (relpy===1){
                                passwd = aes.aesDecrypt(passwd,key);
                                code = aes.aesDecrypt(code,key);
                                redis.getRedis(phone+"auth", function (err, reply) {
                                    if (err){
                                        res.json({
                                            status:1,
                                            error: err
                                        })
                                    }
                                    else{
                                        if (code === reply){
                                            redis.delRedis(phone+"auth", function (err, value) {
                                                //低安全级别Key
                                                rsun.getKey(tokenStr, null, function(key_low, e){
                                                    if (e===null||e===undefined){
                                                        //高安全级别
                                                        rsun.getKey(tokenStr,passwd,function (key_high, e) {
                                                            if (e===null||e===undefined){
                                                                res.json({
                                                                    status:0,
                                                                    low:aes.aesEncrypt(key_low,key),
                                                                    high:aes.aesEncrypt(key_high,key),
                                                                    token:aes.aesEncrypt(tokenStr,key)
                                                                });
                                                            }
                                                            else{
                                                                res.json({
                                                                    status:1,
                                                                    error:e
                                                                });
                                                            }
                                                        })
                                                    }
                                                    else{
                                                        res.json({
                                                            status:1,
                                                            error:e
                                                        });
                                                    }
                                                });
                                            });
                                        }
                                        else{
                                            res.json({
                                                status:1,
                                                error: "authcode is invalid"
                                            });
                                        }
                                    }
                                });
                            }
                            else if(err){
                                res.json({
                                    status:1,
                                    error:err
                                });
                            }
                            else{
                                res.json({
                                    status:1,
                                    error:"重复tokenid"
                                });
                            }
                        });
                    }
                    catch (objError) {
                        if (objError instanceof SyntaxError) {
                            res.json({error:objError.name,status:1});
                        } else {
                            res.json({error:objError.message,status:1});
                        }
                    }
                }
            });
        }
        else
        {
            res.json({error:err,status:1});
        }
    });
});

module.exports = router;