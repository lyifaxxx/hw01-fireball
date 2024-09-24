import {vec3, vec4} from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import Cube from './geometry/Cube';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 5,
  'Load Scene': loadScene, // A function pointer, essentially
  color: [237, 130, 40], // default color
  background_color: [0.0, 0.2, 0.2],
  alpha: 1.0,
  shader: 'fireball',
  worley: 5,
  'tesselation': 0.8,
  'speed': 1.0,
  'bumpness': 0.1,
  'brightness': 1.0,
};

let icosphere: Icosphere;
let square: Square;
let cube: Cube;
let prevTesselations: number = 5;

// functions to set the preset params
function setFireballPreset_red()
{
  controls.color = [237,40,40];
  controls['tesselation'] = 0.66;
  controls['speed'] = 4.9;
  controls['bumpness'] = 0.0;
  controls['brightness'] = 2.28;
}

function setFireballPreset_orange()
{
  controls.color = [237, 130, 40];
  controls['tesselation'] = 0.8;
  controls['speed'] = 1.0;
  controls['bumpness'] = 0.1;
  controls['brightness'] = 1.0;
}

function setFireballPreset_blue()
{
  controls.color = [46, 122, 227];
  controls['tesselation'] = 0.66;
  controls['speed'] = 0.9;
  controls['bumpness'] = 0.22;
  controls['brightness'] = 1.34;
}

function setFireballPreset_green()
{
  controls.color = [11, 50, 6];
  controls['tesselation'] = 0.66;
  controls['speed'] = 0.4;
  controls['bumpness'] = 0.15;
  controls['brightness'] = 1.45;
}

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
  cube = new Cube(vec3.fromValues(0, 0, 0));
  cube.create();
}

function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  const gui = new DAT.GUI();
  gui.add(controls, 'tesselation', 0, 8).step(1);
  gui.add(controls, 'Load Scene');
  //gui to toogle u_Color
  gui.addColor(controls, 'color');
  gui.add(controls, 'alpha', 0.0, 1.0).step(0.1);
  //gui to toogle background color
  gui.addColor(controls, 'background_color');
  // gui to change different shaders
  gui.add(controls, 'shader', ['lambert', 'worley', 'fireball']);

  // add additional gui elements for different shaders
  if(controls.shader == 'worley')
  {
    gui.add(controls, 'worley', 0.0, 50.0).step(1);
  }

  // add fireball gui elements
  if(controls.shader == 'fireball')
  {
    // create folder for fireball params and fireball param presets
    const fireballFolder = gui.addFolder('Fireball Params');
    fireballFolder.add(controls, 'tesselation', 0.0, 1.0).step(0.01).listen();
    fireballFolder.add(controls, 'speed', 0.0, 5.0).step(0.1).listen();
    fireballFolder.add(controls, 'bumpness', 0.0, 1.0).step(0.01).listen();
    fireballFolder.add(controls, 'brightness', 0.0, 5.0).step(0.01).listen();

    const fireballPresetFolder = fireballFolder.addFolder('Fireball Presets');
    fireballPresetFolder.add({preset: setFireballPreset_red}, 'preset').name('Authentic Fireball');
    fireballPresetFolder.add({preset: setFireballPreset_orange}, 'preset').name('Warm Orange');
    fireballPresetFolder.add({preset: setFireballPreset_blue}, 'preset').name('Ice Wizard');
    fireballPresetFolder.add({preset: setFireballPreset_green}, 'preset').name('Wild Fire');

    fireballFolder.open();
    fireballPresetFolder.open();
  }

  


  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  gl.enable(gl.DEPTH_TEST);

  const lambert = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-frag.glsl')),
  ]);

  const worley = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/custom-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/worley-frag.glsl')),
  ]);

  const fireball = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/fireball-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/fireball-frag.glsl')),
  ]);


  // This function will be called every frame
  function tick() {
    camera.update();
    //console.log('camera position:', camera.position);
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    const bkg_color = vec4.fromValues(controls.background_color[0] / 255, controls.background_color[1] / 255, controls.background_color[2] / 255, 1.0);
    renderer.setClearColor(bkg_color[0], bkg_color[1], bkg_color[2], bkg_color[3]);
    renderer.clear();
    //set color to shader
    const color = vec4.fromValues(controls.color[0] / 255, controls.color[1] / 255, controls.color[2] / 255, controls.alpha);
    lambert.setGeometryColor(color);
    worley.setGeometryColor(color);
    fireball.setGeometryColor(color);
    //console.log('Updated color in shader:', color);
    if(controls.tesselations != prevTesselations)
    {
      prevTesselations = controls.tesselations;
      icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      icosphere.create();
    }
    // get time
    const time = performance.now() / 1000.0;
    //console.log('Time:', time);

    // get fireball params
    const fire_params = vec4.fromValues(
      controls["tesselation"], 
      controls["speed"], 
      controls["bumpness"], 
      controls["brightness"]);

    // ----------------- render -----------------   //
    if(controls.shader == 'lambert')
    {
      renderer.render(camera, lambert, [
        icosphere,
        // square,
        // cube,
      ], color, time);
    }
    else if(controls.shader == 'worley')
    {
      renderer.renderWorley(camera, worley, [
        //icosphere,
        // square,
         cube,
      ], color, time, controls.worley);
    }
    else if(controls.shader == 'fireball')
    {
      renderer.renderFireball(camera, fireball, [
        icosphere,
        // square,
        // cube,
      ], 
      color, // color from gui
      time, 
      3, // seed
      bkg_color,
      fire_params
    );
      //console.log('camera position:', camera.controls.eye);
    }

    // ----------------- render end -----------------   //
    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
