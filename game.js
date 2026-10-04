const canvas=document.getElementById('game');
const ctx=canvas.getContext('2d');
ctx.imageSmoothingEnabled=false;

let W=0,H=0,dpr=1;
function resize(){
  dpr=Math.min(window.devicePixelRatio||1,2);
  W=window.innerWidth; H=window.innerHeight;
  canvas.width=Math.floor(W*dpr); canvas.height=Math.floor(H*dpr);
  ctx.setTransform(dpr,0,0,dpr,0,0);
}
window.addEventListener('resize',resize); resize();

const heroes={
  achim:{name:'Achim',hair:'#777',shirt:'#20242a',skin:'#d69a73',accent:'#4b8bd8',speed:300,jump:900},
  angie:{name:'Angie',hair:'#9b174f',shirt:'#7d245f',skin:'#d99a79',accent:'#ef6f9e',speed:315,jump:900},
  leni:{name:'Leni',hair:'#a81d62',shirt:'#6d3ca8',skin:'#e1a17f',accent:'#9b6bea',speed:300,jump:1020},
  connor:{name:'Connor',hair:'#8b5a2b',shirt:'#1766a8',skin:'#d99a78',accent:'#37a866',speed:330,jump:900}
};

let hero='achim',running=false;
let player={x:180,y:520,vx:0,vy:0,w:38,h:68,onGround:false,face:1};
let camera=0,coins=0,lives=3,checkpoint=180,nalaActive=false,won=false;
let keys={left:false,right:false,jump:false};
let jumpPressed=false,last=0;

const worldWidth=6200;
const groundY=570;
const platforms=[
  {x:0,y:groundY,w:6200,h:70},
  {x:620,y:455,w:250,h:28},
  {x:1010,y:385,w:220,h:28},
  {x:1390,y:470,w:260,h:28},
  {x:1780,y:360,w:230,h:28},
  {x:2140,y:450,w:250,h:28},
  {x:2530,y:350,w:270,h:28},
  {x:3000,y:455,w:250,h:28},
  {x:3350,y:330,w:260,h:28},
  {x:3710,y:430,w:260,h:28},
  {x:4090,y:350,w:280,h:28},
  {x:4510,y:470,w:280,h:28},
  {x:4910,y:375,w:280,h:28},
  {x:5320,y:450,w:300,h:28}
];

const coinsList=[];
for(let x=430;x<5700;x+=210) coinsList.push({x,y:455-(Math.sin(x)*0.5+0.5)*80,taken:false});
const enemies=[
  {x:1180,y:535,type:'ball',alive:true},
  {x:1940,y:325,type:'ball',alive:true},
  {x:3070,y:420,type:'ball',alive:true},
  {x:4250,y:315,type:'ball',alive:true},
  {x:5050,y:535,type:'cat',alive:true}
];
const checkpointFlags=[{x:1600,hit:false},{x:3300,hit:false},{x:4700,hit:false}];

function rect(x,y,w,h,fill,stroke){
  ctx.fillStyle=fill;ctx.fillRect(Math.round(x),Math.round(y),Math.round(w),Math.round(h));
  if(stroke){ctx.strokeStyle=stroke;ctx.lineWidth=3;ctx.strokeRect(Math.round(x),Math.round(y),Math.round(w),Math.round(h));}
}
function text(t,x,y,size=18,fill='#fff',align='left'){
  ctx.font='900 '+size+'px monospace';ctx.fillStyle=fill;ctx.textAlign=align;ctx.fillText(t,x,y);
}

function drawSky(){
  const grad=ctx.createLinearGradient(0,0,0,H);
  grad.addColorStop(0,'#58b9ef');grad.addColorStop(1,'#d5f2ff');
  ctx.fillStyle=grad;ctx.fillRect(0,0,W,H);
  ctx.fillStyle='#fff';
  for(let i=0;i<7;i++){
    const cx=((i*310-camera*.12)% (W+300))-100, cy=70+(i%3)*42;
    ctx.fillRect(cx,cy,70,18);ctx.fillRect(cx+18,cy-14,45,28);ctx.fillRect(cx+52,cy-7,48,25);
  }
}

function drawHills(){
  ctx.save();ctx.translate(-camera*.18,0);
  for(let i=-2;i<18;i++){
    const x=i*430;
    ctx.fillStyle=i%2?'#5ba46a':'#4c9560';
    ctx.beginPath();ctx.moveTo(x,groundY);ctx.lineTo(x+210,220+(i%3)*30);ctx.lineTo(x+430,groundY);ctx.fill();
  }
  ctx.restore();
}

function drawCity(){
  ctx.save();ctx.translate(-camera*.42,0);
  for(let i=-2;i<22;i++){
    const x=i*310, bh=130+(Math.abs(i*71)%150);
    rect(x,groundY-bh,220,bh,['#e5a26f','#d87979','#8e9fd1','#e9c36c'][Math.abs(i)%4]);
    for(let r=0;r<3;r++)for(let c=0;c<3;c++)rect(x+28+c*60,groundY-bh+30+r*48,24,30,'#bde7f5');
    rect(x+82,groundY-70,55,70,'#8a5b4a');
  }
  ctx.restore();
}

function drawTree(x,y,s=1){
  ctx.save();ctx.translate(x,y);ctx.scale(s,s);
  rect(-12,0,24,90,'#6b4026');
  ctx.fillStyle='#258b4a';ctx.beginPath();ctx.arc(0,-15,58,0,Math.PI*2);ctx.fill();
  ctx.fillStyle='#36a95b';ctx.beginPath();ctx.arc(-35,-8,38,0,Math.PI*2);ctx.fill();ctx.beginPath();ctx.arc(34,-4,40,0,Math.PI*2);ctx.fill();
  ctx.restore();
}

function drawHouse(){
  const x=5050;
  rect(x,groundY-220,420,220,'#f1dfbd','#5b493d');
  ctx.fillStyle='#4b5968';ctx.beginPath();ctx.moveTo(x-35,groundY-220);ctx.lineTo(x+210,groundY-385);ctx.lineTo(x+465,groundY-220);ctx.fill();
  rect(x+175,groundY-115,72,115,'#704d39','#332b2a');
  rect(x+35,groundY-170,95,72,'#72b8d6','#453d39');
  rect(x+285,groundY-170,95,72,'#72b8d6','#453d39');
  rect(x+177,groundY-285,66,52,'#72b8d6','#453d39');
  text('16',x+55,groundY-35,20,'#333');
  text('FAMILIENHAUS',x+210,groundY-335,20,'#fff','center');
}

function drawNalaHut(){
  const x=2350;
  rect(x,groundY-155,280,155,'#e48b39','#623c27');
  ctx.fillStyle='#7d3f26';ctx.beginPath();ctx.moveTo(x-25,groundY-155);ctx.lineTo(x+140,groundY-270);ctx.lineTo(x+305,groundY-155);ctx.fill();
  rect(x+105,groundY-85,70,85,'#5b3b2d');
  text('NALA',x+140,groundY-190,24,'#fff','center');
  text('🐾',x+140,groundY-120,34,'#fff','center');
}

function drawPlatforms(){
  for(const p of platforms){
    rect(p.x,p.y,p.w,p.h,'#70452d','#3a291f');
    rect(p.x,p.y,p.w,9,'#4fb34d');
    for(let x=p.x+18;x<p.x+p.w;x+=42) rect(x,p.y+18,18,8,'#9b613d');
  }
}

function drawCoins(){
  for(const c of coinsList)if(!c.taken){
    ctx.fillStyle='#ffd43b';ctx.beginPath();ctx.arc(c.x,c.y,13,0,Math.PI*2);ctx.fill();
    ctx.strokeStyle='#b87b00';ctx.lineWidth=3;ctx.stroke();
    rect(c.x-2,c.y-8,4,16,'#fff2a1');
  }
}

function drawEnemy(e){
  if(!e.alive)return;
  if(e.type==='ball'){
    ctx.fillStyle='#fff';ctx.beginPath();ctx.arc(e.x,e.y,20,0,Math.PI*2);ctx.fill();
    ctx.strokeStyle='#43a65c';ctx.lineWidth=4;ctx.stroke();
    ctx.strokeStyle='#e34b4b';ctx.lineWidth=3;ctx.beginPath();ctx.arc(e.x-3,e.y,13,-1.2,1.2);ctx.stroke();
  }else{
    ctx.fillStyle='#343434';ctx.fillRect(e.x-24,e.y-30,48,30);
    ctx.fillStyle='#aaa';ctx.fillRect(e.x-18,e.y-45,36,20);
    ctx.fillStyle='#111';ctx.fillRect(e.x-11,e.y-38,6,6);ctx.fillRect(e.x+5,e.y-38,6,6);
  }
}

function drawNala(){
  if(!nalaActive)return;
  const x=player.x-65,y=player.y-10;
  ctx.fillStyle='#513525';ctx.fillRect(x-30,y-24,55,30);
  ctx.fillStyle='#c88955';ctx.fillRect(x+18,y-40,28,30);
  ctx.fillStyle='#161616';ctx.fillRect(x+35,y-38,5,5);
  ctx.fillStyle='#eee';ctx.fillRect(x+31,y-32,12,8);
  ctx.fillStyle='#513525';ctx.fillRect(x-23,y+5,8,18);ctx.fillRect(x+5,y+5,8,18);
  text('NALA',x,y-52,12,'#ffd84a');
}

function drawHero(){
  const h=heroes[hero],x=player.x,y=player.y;
  const bob=player.onGround?Math.sin(performance.now()/90)*2:0;
  ctx.save();ctx.translate(x,y+bob);
  // shadow
  ctx.fillStyle='rgba(0,0,0,.25)';ctx.fillRect(-25,2,50,7);
  // legs/shoes
  rect(-18,-2,15,23,'#263447');rect(4,-2,15,23,'#263447');
  rect(-21,18,21,8,'#f4f4f4');rect(2,18,21,8,'#f4f4f4');
  // body
  rect(-22,-48,44,48,h.shirt,'#171717');
  // head
  ctx.fillStyle=h.skin;ctx.fillRect(-20,-82,40,34);
  // hair
  ctx.fillStyle=h.hair;
  if(hero==='achim'){ctx.fillRect(-20,-88,40,15);ctx.fillRect(-27,-76,8,24);ctx.fillRect(19,-78,8,20);}
  else {ctx.fillRect(-23,-91,46,17);ctx.fillRect(-27,-80,10,30);ctx.fillRect(17,-80,10,30);}
  // eyes
  ctx.fillStyle='#17283b';ctx.fillRect(-11,-69,5,5);ctx.fillRect(6,-69,5,5);
  // arms
  rect(-31,-45,9,28,h.shirt);rect(22,-45,9,28,h.shirt);
  ctx.restore();
}

function drawFlags(){
  for(const f of checkpointFlags){
    rect(f.x,groundY-120,6,120,'#513b2c');
    ctx.fillStyle=f.hit?'#42c66b':'#d6b13c';
    ctx.beginPath();ctx.moveTo(f.x+6,groundY-118);ctx.lineTo(f.x+58,groundY-100);ctx.lineTo(f.x+6,groundY-82);ctx.fill();
  }
}

function render(){
  drawSky();drawHills();drawCity();
  ctx.save();ctx.translate(-camera,0);
  for(let x=250;x<6100;x+=360)drawTree(x,groundY-8,0.75+(x%3)*.1);
  drawHouse();drawNalaHut();drawPlatforms();drawFlags();drawCoins();
  for(const e of enemies)drawEnemy(e);
  drawNala();drawHero();
  if(nalaActive)text('NALA IST DABEI!',player.x+45,player.y-82,14,'#ffd84a');
  ctx.restore();
}

function overlap(a,b){
  return a.x+a.w>b.x && a.x<b.x+b.w && a.y>b.y && a.y-a.h<b.y+b.h;
}

function respawn(){
  player.x=checkpoint;player.y=groundY;player.vy=0;
  lives--;
  if(lives<=0){lives=3;checkpoint=180;player.x=180;}
  updateHud();
}

function updateHud(){
  const s=document.getElementById('score'),l=document.getElementById('lives');
  if(s)s.textContent='🪙 '+coins;
  if(l)l.textContent='❤️ '+lives;
}

function update(dt){
  const h=heroes[hero];
  const dir=(keys.right?1:0)-(keys.left?1:0);
  player.vx=dir*h.speed;
  player.x+=player.vx*dt;
  if(dir)player.face=dir;
  player.vy+=2200*dt;
  const oldY=player.y;
  player.y+=player.vy*dt;
  player.onGround=false;

  for(const p of platforms){
    const horizontal=player.x+18>p.x&&player.x-18<p.x+p.w;
    if(horizontal && oldY<=p.y && player.y>=p.y && player.vy>=0){
      player.y=p.y;player.vy=0;player.onGround=true;
    }
  }

  if(jumpPressed&&player.onGround){
    player.vy=-h.jump;player.onGround=false;
  }
  jumpPressed=false;

  for(const c of coinsList){
    if(!c.taken&&Math.abs(c.x-player.x)<28&&Math.abs(c.y-(player.y-35))<35){
      c.taken=true;coins++;updateHud();
    }
  }

  for(const e of enemies){
    if(!e.alive)continue;
    if(e.type==='ball')e.x+=Math.sin(performance.now()/300+e.x)*18*dt;
    if(overlap({x:player.x-18,y:player.y,w:36,h:68},{x:e.x-20,y:e.y-40,w:40,h:40})){
      if(player.vy>250){
        e.alive=false;player.vy=-620;coins+=5;updateHud();
      }else if(nalaActive&&e.type==='ball'){
        e.alive=false;coins+=5;updateHud();
      }else respawn();
    }
  }

  if(!nalaActive&&player.x>=2650)nalaActive=true;
  if(nalaActive){
    for(const e of enemies)if(e.alive&&e.type==='ball'&&Math.abs(e.x-player.x)<170){
      e.alive=false;coins+=5;updateHud();
    }
  }

  for(const f of checkpointFlags){
    if(!f.hit&&player.x>f.x){f.hit=true;checkpoint=f.x+30;}
  }

  if(player.y>H+180||player.x<0)respawn();
  if(player.x>5500&&!won){
    won=true;running=false;
    setTimeout(()=>alert('🏠 SUPERFAMILIE! Level 1 geschafft – das Familienhaus ist erreicht!'),50);
  }

  camera=Math.max(0,Math.min(player.x-W*.35,worldWidth-W));
}

function loop(t){
  const dt=Math.min(.033,(t-last||16)/1000);last=t;
  if(running)update(dt);
  ctx.clearRect(0,0,W,H);render();
  requestAnimationFrame(loop);
}
requestAnimationFrame(loop);

document.querySelectorAll('.heroes button').forEach(b=>{
  b.onclick=()=>{
    document.querySelectorAll('.heroes button').forEach(z=>z.classList.remove('selected'));
    b.classList.add('selected');hero=b.dataset.hero;
  };
});
const first=document.querySelector('.heroes button');if(first)first.classList.add('selected');

const start=document.getElementById('start');
if(start)start.onclick=()=>{
  player={x:180,y:groundY,vx:0,vy:0,w:38,h:68,onGround:true,face:1};
  camera=0;coins=0;lives=3;checkpoint=180;nalaActive=false;won=false;
  coinsList.forEach(c=>c.taken=false);enemies.forEach(e=>e.alive=true);checkpointFlags.forEach(f=>f.hit=false);
  updateHud();running=true;document.getElementById('menu').classList.add('hidden');
};
const menuBtn=document.getElementById('menuBtn');
if(menuBtn)menuBtn.onclick=()=>{running=false;document.getElementById('menu').classList.remove('hidden');};

function bind(id,name){
  const b=document.getElementById(id);if(!b)return;
  const down=e=>{e.preventDefault();keys[name]=true;b.classList.add('press');if(name==='jump')jumpPressed=true;};
  const up=e=>{e.preventDefault();keys[name]=false;b.classList.remove('press');};
  b.addEventListener('pointerdown',down);b.addEventListener('pointerup',up);
  b.addEventListener('pointercancel',up);b.addEventListener('pointerleave',up);
}
bind('left','left');bind('right','right');bind('jump','jump');

window.addEventListener('keydown',e=>{
  if(e.key==='ArrowLeft'||e.key==='a')keys.left=true;
  if(e.key==='ArrowRight'||e.key==='d')keys.right=true;
  if(e.key==='ArrowUp'||e.key===' '||e.key==='w'){if(!keys.jump)jumpPressed=true;keys.jump=true;e.preventDefault();}
});
window.addEventListener('keyup',e=>{
  if(e.key==='ArrowLeft'||e.key==='a')keys.left=false;
  if(e.key==='ArrowRight'||e.key==='d')keys.right=false;
  if(e.key==='ArrowUp'||e.key===' '||e.key==='w')keys.jump=false;
});
