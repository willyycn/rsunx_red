/**
 * Created by willyy on 2017/3/23.
 */
let redis = require('redis'),
    client = redis.createClient(6379,'127.0.0.1',{})
let config = require('../config');
let log = require('../core/log')(module);
client.on("error", function (err) {
    log.info("redis Error " + err);
});

exports.setRedis = function (stringKey,stringValue) {
    client.set(stringKey,stringValue);
    client.expire(stringKey,config.get("kvLife:tokenLife"))
};
exports.hsetRedis = function (hashKey,stringValue) {
    client.hset(hashKey,stringValue);
};
exports.getRedis = function (stringKey,callBack) {
    client.get(stringKey, function (err, reply) {
        callBack(err,reply);
    });
};
exports.hgetRedis = function (hashKey,callBack) {
    client.hget(hashKey, function (err, reply) {
        callBack(err,reply);
    });
};
exports.quitRedis = function () {
    client.quit();
};