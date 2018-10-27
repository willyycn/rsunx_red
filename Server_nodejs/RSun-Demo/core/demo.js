/**
 * Created by willyy on 2017/2/22.
 */
let express = require('express');
let cookieParser = require('cookie-parser');
let bodyParser = require('body-parser');
let methodOverride = require('method-override');

let config = require("../config");
let Log = require('./log')(module);

//set api routes
let ver = config.get('demo:ver');
let api = require('../demo/' + ver);

let demo = express();
demo.use(bodyParser.json());
demo.use(bodyParser.urlencoded({ extended: false }));
demo.use(cookieParser());
demo.use(methodOverride());
demo.use('/demo',api);

// catch 404 and forward to error handler
demo.use(function(req, res, next) {
    let err = new Error('Not Found');
  err.message = "api: "+req.originalUrl + " method: "+req.method+" is not found; ";
  err.status = 404;
  next(err);
});

//set env
demo.set('env',config.get('debug'));

// error handler
demo.use(function(err, req, res, next) {
  // set locals, only providing error in development
    Log.info('api err: ' + err);
    res.status(err.status);
    if (demo.get('env') === 1){
        res.json({
            message:err.message,
            stack:err
        });
    }
    else {
        res.json({
            e:"error"
        });
    }
});

module.exports = demo;
