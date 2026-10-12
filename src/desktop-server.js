'use strict';
const http=require('node:http'),crypto=require('node:crypto'),path=require('node:path');
const {createServer}=require('./server'),Service=require('./service'),{History}=require('./history');
async function start(dir){
 const service=new Service(dir);await service.init();const history=new History(path.join(dir,'history')).startProvider(()=>service.overview());
 // Allocate an ephemeral loopback port before making the shared HTTP handler.
 const server=http.createServer();await new Promise((resolve,reject)=>{server.once('error',reject);server.listen(0,'127.0.0.1',resolve);});
 const origin='http://127.0.0.1:'+server.address().port,token=crypto.randomBytes(32).toString('hex'),cookie='anker_desktop';
 const handler=createServer({origins:[origin]},service,history).listeners('request')[0];
 server.on('request',(req,res)=>{
  const cookies=String(req.headers.cookie||'').split(';').map(x=>x.trim()),authorized=cookies.includes(cookie+'='+token);
  // The first native request exchanges an in-memory key for an HttpOnly cookie.
  const bootstrap=req.method==='GET'&&req.url==='/'&&req.headers['x-anker-desktop-key']===token;
  if(!authorized&&!bootstrap){res.writeHead(403,{'Content-Type':'text/plain','Cache-Control':'no-store'});return res.end('Desktop session required');}
  if(bootstrap)res.setHeader('Set-Cookie',`${cookie}=${token}; HttpOnly; SameSite=Strict; Path=/`);
  handler(req,res);
 });
 let closing=false;async function close(){if(closing)return;closing=true;clearInterval(history.timer);server.close();await service.close();server.closeAllConnections();}
 return {origin,token,close};
}
if(require.main===module){start(process.env.ANKER_DATA_DIR).then(app=>{process.stdout.write(JSON.stringify({ready:true,origin:app.origin,token:app.token})+'\n');const stop=()=>app.close().then(()=>process.exit(0));process.on('SIGTERM',stop);process.on('SIGINT',stop);process.stdin.resume();process.stdin.on('end',stop);}).catch(()=>{process.stderr.write('Unable to initialize local Anker service\n');process.exit(1);});}
module.exports={start};
