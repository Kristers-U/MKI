<template>
  <div class="scene-root">
    <canvas ref="canvas"></canvas>
    <button class="uibtn" @click="cameraPosReset()">Atiestatīt kameru</button>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, watch } from 'vue';
import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import gridVert from './shaders/vertex.glsl?raw';
import gridFrag from './shaders/fragment.glsl?raw';

const canvas = ref(null);
const props = defineProps({
  H: Number,
  B: Number,
  D: Number,
  t: Number,
  visible: Boolean
});



let renderer, scene, camera, controls;
let animationId;

const fov = 45;
const near = 0.1;
const far = 1000;

// ---------- helpers ---------
function cameraPosReset() {
  controls.reset();

}

function resizeRendererToDisplaySize(renderer) {
  const canvas = renderer.domElement;
  const width = canvas.clientWidth;
  const height = canvas.clientHeight;
  const needResize = canvas.width !== width || canvas.height !== height;

  if (needResize) {
    renderer.setSize(width, height, false);
  }
  return needResize;
}

function render() {
  if (resizeRendererToDisplaySize(renderer)) {
    const canvas = renderer.domElement;
    camera.aspect = canvas.clientWidth / canvas.clientHeight;
    camera.updateProjectionMatrix();
  }

  //plane.position.x = Math.floor(camera.position.x);
  //plane.position.z = Math.floor(camera.position.z);


  renderer.render(scene, camera);
  animationId = requestAnimationFrame(render);
}

function updateCamera() {
  camera.updateProjectionMatrix();
}

// ---------- lifecycle ----------
onMounted(() => {
  // renderer
  renderer = new THREE.WebGLRenderer({
    canvas: canvas.value,
    antialias: true,
    //logarithmicDepthBuffer: true
  });

  // scene
  scene = new THREE.Scene();
  scene.background = new THREE.Color('black');

  // camera
  const { clientWidth, clientHeight } = canvas.value;
  camera = new THREE.PerspectiveCamera(
    fov,
    clientWidth / clientHeight,
    near,
    far
  );
  camera.position.set(0, 10, 20);

  // controls
  controls = new OrbitControls(camera, renderer.domElement);
  controls.target.set(0, 5, 0);
  controls.maxPolarAngle = Math.PI / 2;
  controls.update();




  const gridMaterial = new THREE.ShaderMaterial({
    transparent: true,
    depthTest: true,//false => pillar becomes "transparent" (grid overwrites pillar)
    depthWrite: true,
    side: THREE.DoubleSide, //Both front and back faces are rendered.
    uniforms: { //uniform => value thats passed to fragment shader
      uColor: { value: new THREE.Color(0x444444) }, //color
      uThickness: { value: 1.0 }, //line thickness
    },
    vertexShader: gridVert, //vertex import
    fragmentShader: gridFrag, //fragment import
  });

  const plane = new THREE.Mesh( new THREE.PlaneGeometry(1000, 1000), gridMaterial);

  plane.rotation.x = -Math.PI / 2; //rotation
  plane.position.y = -0.001;
  scene.add(plane);


  render();
});

onUnmounted(() => {
  cancelAnimationFrame(animationId);
  controls?.dispose();
  renderer?.dispose();
});


watch([() => props.H, () => props.B, () => props.D, () => props.t], 
  ([newH, newB, newD, newT]) => {
    if (!scene) return;

    // Removes previous column mesh
    const oldColumn = scene.getObjectByName('column');
    if (oldColumn) {
      oldColumn.geometry.dispose();
      oldColumn.material.dispose();
      scene.remove(oldColumn);
    }


    // Creates new column with updated dimensions
    const column = new THREE.Mesh(
      new THREE.BoxGeometry(newB, newH, newD),
      new THREE.MeshBasicMaterial({ color: 0x8AC })
    );
    column.name = 'column';
    column.position.set(0, newH / 2, 0);
    scene.add(column);
});




watch(() => props.visible, (isVisible) => {
  if (isVisible) {
    requestAnimationFrame(() => {
      const w = canvas.value.clientWidth;
      const h = canvas.value.clientHeight;
      renderer.setSize(w, h, false);
      camera.aspect = w / h;
      camera.updateProjectionMatrix();
    });
  }
});
</script>
<style scoped>

canvas {
  width: 100%;
  height: 100%;
  display: block;
}
canvas   { background: rgba(0, 0, 255, 0.1); }
.scene-root {
  width: 100%;
  height: 100%;
}
.scene-root { background: rgba(255, 255, 0, 0.1); }
.uibtn {
  position: absolute;
  padding: 2%;
  top: 20px;
  left: 20px;
  z-index: 10; /* above the canvas */
}
button {
  border: 2px solid white;
  color: white;
  background-color: rgb(10, 10, 10);
  margin: 5px;
  padding: 5% 15%;
  border-radius: 10px;
}
</style>