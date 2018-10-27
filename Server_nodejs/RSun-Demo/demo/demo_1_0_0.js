/**
 * Created by willyy on 2017/3/1.
 */
let express = require('express');
let router = express.Router();
let log = require('../core/log')(module);
let rsun = require('../core/rsun');
// let redis = require('../core/kv_cli');
router.use(function (req, res, next) {
    log.info('request from : '+ req.originalUrl+ ' Method: '+ req.method + ' Time: '+ Date.now());
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

let tokenID = parseInt(uuid(8,10));
let validMonth = 1;
/**
 * 通过客户端发送来的seed, 为客户端生成登陆Token
 */
router.get('/getLoginToken',function (req, res) {
    let seed = req.query.seed;
    if (seed){
        tokenID = tokenID+1;
        let expireTime = new Date().toLocaleDateString();
        let expireMonth = parseInt(expireTime.split("/")[0]) + validMonth;
        let expireDate = expireMonth + "/" + expireTime.split("/")[1] + "/" + expireTime.split("/")[2];
        let expire = new Date(expireDate).getTime();
        let token = seed + "_" + tokenID + "_" + expire;
        res.json(
            {
                token:token
            }
        )
    }
    else {
        res.json(
            {
                error:"seed is empty"
            }
        )
    }
});

/**
 * 通过手机号来做二次验证用的验证码服务, 为此demo简化, 统一默认发送的是123123
 */
router.get('/authCode',function (req,res) {
    let phone = req.query.phone;
    /*
    //todo: 这里需要集成短信验证码等第三方服务, 将发送的手机号和验证码以kv形式存于kv数据库, 为了简化demo, 我们默认向手机发送的验证码是"123123".
    redis.setRedis(phone,authCode);
    */
    res.json({
        codeSend:true
    })
});

/**
 * 通过token来判断是否发送挑战
 */
function getPhoneFromToken(token) {
    return token.split("_")[1];
}
function getExpireFromToken(token) {
    return token.split("_")[(token.split("_").length-1)];
}
let kvChallenge;

router.get('/challenge',function (req,res) {
    let token = req.query.token;
    //todo:实际开发时要检查此token是否在黑名单内(黑名单可以使用kv server)
    let expireDate = getExpireFromToken(token);
    let eDate = parseInt(expireDate);
    let date = new Date().getTime();
    if (date>eDate){
        res.json({
            error:"过期"
        });
    }
    else if(date===eDate){
        res.json({
            error:"即将过期"
        });
    }
    else{
        rsun.getRand(function(challenge, error){
            /*todo: 实际开发时应该使用kv数据库保存token和challenge, 为了简化demo, 此过程简化, 只使用一个全局变量kvChallenge来模拟存储在kv数据库内对应的challenge
                redis.setRedis(token,challenge);
            */
            kvChallenge = challenge;
            res.json({
                rand:challenge,
                error:error
            });
        });
    }
});

/**
 * 验签
 */
router.post('/verify',function (req,res) {
    let token = req.body.token;
    let sign = req.body.sign;
    let passwd = req.body.passwd;
    /*todo: 实际应该使用kv数据库保存token和challenge, 为了简化demo, 此过程简化, 使用一个全局变量kvChallenge来模拟存储在kv数据库内对应的challenge
    redis.getRedis(token, function (err, reply) {
        if (err){
            res.json({
                error: err
            })
        }
        else{
            rsun.verify(token, sign, reply, passwd, function(v, e){
                res.json({
                    verify: v,
                    error: e
                })
            });
        }
    });
    */
    let msg = kvChallenge;
    rsun.verify(token, sign, msg, passwd, function(v, e){
        res.json({
            verify: v,
            error: e
        })
    })
});

/**
 * 注册用户业务的逻辑
 */
router.post('/registerUser', function(req, res){
    let token = req.body.token;
    let passwd = req.body.passwd;
    let authCode = req.body.authCode;
    let phone = req.body.phone;
    /*
    //todo: 我们需要首先分解token, 将手机号从token取出, 然后在kv数据库中, 通过手机号将authcode取出, 之后和传过来的authcode对比一下.为了简化demo, 我们统一默认传上来正确的验证码:"123123"
        let phone = getPhoneFromToken(token);
        redis.getRedis(phone, function (err, reply) {
        if (err){
            res.json({
                error: err
            })
        }
        else{
            if(autCode === reply){

            }
            else{
                res.json({
                    error: "authcode is invalid"
                });
            }
        });
     */
    if (authCode === "123123"){
        //低安全级别Key
        rsun.getKey(token, null, function(key_low, e){
            if (e===null||e===undefined){
                //高安全级别
                phone = phone +"_"+ token.split("_")[2];
                rsun.getKey(phone,passwd,function (key_high, e) {
                    if (e===null||e===undefined){
                        res.json({
                            low:key_low,
                            high:key_high
                        });
                    }
                    else{
                        res.json({
                            error:e
                        });
                    }
                })
            }
            else{
                res.json({
                    error:e
                });
            }
        });
    }
    else{
        res.json({
            error: "authcode is invalid"
        });
    }
});

module.exports = router;