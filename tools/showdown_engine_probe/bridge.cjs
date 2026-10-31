'use strict';
const readline = require('node:readline');
const {Probe} = require('./engine.cjs');
const probe = new Probe();
const input = readline.createInterface({input:process.stdin,crlfDelay:Infinity});
input.on('line',line => {
  let message;
  try {
    if (Buffer.byteLength(line) > 8 * 1024 * 1024) throw Error('Oversized local probe message');
    message = JSON.parse(line);
    if (!Number.isSafeInteger(message.rpc_id)) throw Error('Missing RPC ID');
    const result = probe.execute(message);
    process.stdout.write(JSON.stringify({rpc_id:message.rpc_id,ok:true,result})+'\n');
    if (message.op === 'shutdown') input.close();
  } catch(e) {process.stdout.write(JSON.stringify({rpc_id:message?.rpc_id ?? -1,ok:false,error:String(e.message)})+'\n');}
});
input.on('close',() => {probe.close();process.exitCode=0;});
