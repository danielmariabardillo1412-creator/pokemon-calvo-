'use strict';
// Local experimental runtime. The native engine is the sole battle authority.
const readline=require('node:readline');
const {NativeEngine}=require('./native_engine.cjs');
const engine=new NativeEngine();
const input=readline.createInterface({input:process.stdin,crlfDelay:Infinity});
input.on('line',line=>{
  let message;
  try {
    if(Buffer.byteLength(line)>8*1024*1024)throw Error('Oversized request');
    message=JSON.parse(line);
    if(!Number.isSafeInteger(message.rpc_id))throw Error('Missing RPC ID');
    const result=engine.execute(message);
    process.stdout.write(JSON.stringify({rpc_id:message.rpc_id,ok:true,result})+'\n');
    if(message.op==='shutdown')input.close();
  }catch(e){process.stdout.write(JSON.stringify({rpc_id:message?.rpc_id??-1,ok:false,error:e.message})+'\n');}
});
input.on('close',()=>{engine.close();process.exitCode=0;});
