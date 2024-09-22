import {mat4, vec4} from 'gl-matrix';
import Drawable from './Drawable';
import Camera from '../../Camera';
import {gl} from '../../globals';
import ShaderProgram from './ShaderProgram';

// In this file, `gl` is accessible because it is imported above
class OpenGLRenderer {
  constructor(public canvas: HTMLCanvasElement) {
  }

  setClearColor(r: number, g: number, b: number, a: number) {
    gl.clearColor(r, g, b, a);
  }

  setSize(width: number, height: number) {
    this.canvas.width = width;
    this.canvas.height = height;
  }

  clear() {
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
  }

  render(camera: Camera, prog: ShaderProgram, drawables: Array<Drawable>, geo_color: vec4, time_prog: number) {
    let model = mat4.create();
    let viewProj = mat4.create();
    let color = geo_color;
    let time = time_prog;

    mat4.identity(model);
    mat4.multiply(viewProj, camera.projectionMatrix, camera.viewMatrix);
    prog.setModelMatrix(model);
    prog.setViewProjMatrix(viewProj);
    prog.setGeometryColor(color);
    prog.setTime(time);

    for (let drawable of drawables) {
      prog.draw(drawable);
    }
  }

  // render function for worley shader
  renderWorley(camera: Camera, prog: ShaderProgram, drawables: Array<Drawable>, geo_color: vec4, time_prog: number, seed: number) {
    let model = mat4.create();
    let viewProj = mat4.create();
    let color = geo_color;
    let time = time_prog;

    mat4.identity(model);
    mat4.multiply(viewProj, camera.projectionMatrix, camera.viewMatrix);
    prog.setModelMatrix(model);
    prog.setViewProjMatrix(viewProj);
    prog.setGeometryColor(color);
    prog.setTime(time);
    prog.setSeed(seed);

    for (let drawable of drawables) {
      prog.draw(drawable);
    }
  }

  // render function for fireball shader
  renderFireball(camera: Camera, prog: ShaderProgram, drawables: Array<Drawable>, geo_color: vec4, time_prog: number, seed: number, bkg_color: vec4, fire_params: vec4) {
    let model = mat4.create();
    let viewProj = mat4.create();
    let color = geo_color;
    let time = time_prog;

    mat4.identity(model);
    mat4.multiply(viewProj, camera.projectionMatrix, camera.viewMatrix);
    prog.setModelMatrix(model);
    prog.setViewProjMatrix(viewProj);
    prog.setGeometryColor(color);
    prog.setTime(time);
    prog.setSeed(seed);
    prog.setCamPos(vec4.fromValues(camera.controls.eye[0], camera.controls.eye[1], camera.controls.eye[2], 1.0));
    prog.setBkgColor(bkg_color);
    prog.setFireParams(fire_params);

    for (let drawable of drawables) {
      prog.draw(drawable);
    }
  }

};

export default OpenGLRenderer;
