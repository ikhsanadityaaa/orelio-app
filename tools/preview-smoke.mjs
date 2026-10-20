import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { Script, createContext, runInContext } from 'node:vm';

const html=readFileSync('index.html','utf8');
const match=html.match(/<script>([\s\S]*?)<\/script>/);
assert.ok(match,'inline browser script exists');
const nodes=new Map();
function node(id) {
 if(!nodes.has(id)){
  const el={id,style:{},dataset:{},innerHTML:'',value:'',checked:false,
   clientWidth:300,clientHeight:375,
   children:[],
   appendChild(child){this.children.push(child);return child},
   querySelector(selector){return selector==='.orelio-border-preview'
      ?this.children.find(x=>x.className==='orelio-border-preview'):null},
   querySelectorAll(){return []},
   setAttribute(k,v){this[k]=v},
   addEventListener(){},
   classList:{add(){},remove(){},toggle(){}}
  };
  nodes.set(id,el);
 }
 return nodes.get(id);
}
const document={
 getElementById:node,
 createElement(){return {style:{},className:'',dataset:{}}},
 querySelectorAll(){return []}
};
const window={addEventListener(){},location:{search:''}};
const sandbox=createContext({document,window,console,URLSearchParams,Math,Set,Map,
 setTimeout(){return 0},clearTimeout(){}});
new Script(match[1],{filename:'orelio-preview-inline.js'}).runInContext(sandbox,{timeout:10000});
const api=runInContext('({renderLightPreview,currentLightPosition,collagePixelRect,fibonacciOverlay,syncOverlay,renderCollage,addContinuationPage})',sandbox);

const near=(a,b)=>Math.abs(a-b)<0.0001;
const [r1,r2]=[
 api.collagePixelRect([0,0,.5,1],300,375,5,true),
 api.collagePixelRect([.5,0,.5,1],300,375,5,true)
];
assert.ok(near(r1.left,15),'left outside border is 5% of shortest side');
assert.ok(near(r2.left-(r1.left+r1.width),15),'internal proportional gap is same width');
const [q1,q2]=[
 api.collagePixelRect([0,0,.5,1],300,375,5,false),
 api.collagePixelRect([.5,0,.5,1],300,375,5,false)
];
assert.ok(near(q2.left-(q1.left+q1.width),30),'non-proportional internal seam doubles');

const fibonacci=api.fibonacciOverlay(400,250);
assert.ok((fibonacci.match(/<rect /g)||[]).length===6,'Fibonacci has bounding rectangle and five integer squares');
assert.ok((fibonacci.match(/<path /g)||[]).length===4,'Fibonacci has four quarter arcs');

runInContext("panel='light';sliders['Light Strength']=25;activeLight=0;lightPositions[0]={x:.2,y:.7}",sandbox);
api.renderLightPreview();
const wash=node('wash');
assert.match(wash.style.backgroundImage,/radial-gradient\(circle [\d.]+px at 20% 70%/,'radial light is circular and centered on drag location');
runInContext("sliders['Light Strength']=96",sandbox);
api.renderLightPreview();
assert.match(wash.style.backgroundImage,/at 20% 70%/,'strength slider cannot reset light center');
assert.ok(near(api.currentLightPosition().x,.2),'light X persisted');

runInContext("borderState.enabled=true;borderState.placement='inside';borderState.color='white';borderState.width=5;guideState.kind='off'",sandbox);
api.syncOverlay();
let inside=node('photoWindow').children.find(el=>el.className==='orelio-border-preview');
assert.ok(inside&&inside.style.boxShadow.includes('inset'),'inside border visible as above-image overlay');
runInContext("borderState.placement='outside'",sandbox);
api.syncOverlay();
assert.ok(inside.style.boxShadow.startsWith('0 0 0 '),'outside border drawn outward');
assert.equal(node('photoWindow').style.overflow,'visible','outside border not clipped');

runInContext("collageRatio='9:16';proportionalSpacing=true",sandbox);
api.renderCollage();
assert.equal(node('collageRatio').value,'9:16');
assert.ok(near(Number.parseFloat(node('canvas').style.height),275*16/9),'ratio updates entire page canvas');
api.addContinuationPage();
assert.equal(runInContext('pages.length',sandbox),2,'new continuation page inserted');
assert.equal(runInContext('page',sandbox),1,'new page selected after insertion');
assert.equal(node('collageRatio').value,'9:16','new page inherits project ratio');
assert.ok(node('canvas').innerHTML.includes('class="slot"'),'new page renders editable slots');
console.log('PASS: browser JS syntax, Fibonacci, stable round Lighting, visible borders, ratio, gap symmetry, sequential pages');
