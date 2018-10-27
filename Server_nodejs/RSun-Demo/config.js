/**
 * Created by willyy on 2017/2/22.
 */
let nconf = require('nconf');

nconf.argv()
    .env()
    .file({
        file: process.cwd()+"/config.json"
    });

module.exports = nconf;