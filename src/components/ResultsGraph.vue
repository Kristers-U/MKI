<template>
  <div class="scene-root">
    <canvas ref="canvas"></canvas>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue';
import * as THREE from 'three';
import { nextTick } from 'vue';
const canvas = ref(null);
// REAL axis ranges (engineering units)

const Y_REAL_MIN = 0; //not important anymore
const Y_REAL_MAX = ref(5000); // kN (choose design max)

let axesGroup;
let curveGroup;

const props = defineProps({
  H: Number,
  B: Number,
  D: Number,
  t: Number,
  K: Number,
  E: Number,
  prepareGraphWindow: Boolean
});

// ---------------- Computed ----------------
const Iy = computed(() => {
  if (props.B <= 0 || props.D <= 0 || props.t <= 0) return 0;
  return (props.B * Math.pow(props.D, 3)) / 12
       - ((props.B - props.t) * Math.pow(props.D - 2 * props.t, 3)) / 12;
});

// ---------------- Scene Setup ----------------
let renderer, scene, camera;
let curveLine = null;

const X_AxisLength = 10;
const Y_AxisLength = 10;
const paddingRatio = 0.1;

function initScene() {
  const canvas_width = canvas.value.clientWidth || 300;
  const canvas_height = canvas.value.clientHeight || 150;

  // Renderer
  renderer = new THREE.WebGLRenderer({ canvas: canvas.value, antialias: true });
  renderer.setPixelRatio(window.devicePixelRatio);
  renderer.setSize(canvas_width, canvas_height, false);

  // Scene
  scene = new THREE.Scene();
  scene.background = new THREE.Color(0x111111);

  initCamera();
  
  createLabels();

  axesGroup = new THREE.Group();
  curveGroup = new THREE.Group();

  scene.add(axesGroup);
  scene.add(curveGroup);

  createAxesAndTicks(); // builds axesGroup
  drawNcrCurve();       // builds curveGroup
  renderOnce();
}

// ---------------- Camera ----------------
function initCamera() {
  const w = canvas.value.clientWidth || 300;
  const h = canvas.value.clientHeight || 150;
  const aspect = w / h;

  //Defining world bounds
  const paddingX = X_AxisLength * paddingRatio;
  const paddingY = Y_AxisLength * paddingRatio;

  const minX = -paddingX;
  const maxX = X_AxisLength + paddingX;
  const minY = -paddingY;
  const maxY = Y_AxisLength + paddingY;

  //Center of the view
  const centerX = (minX + maxX) / 2;
  const centerY = (minY + maxY) / 2;

  //Raw view size
  let viewWidth = maxX - minX;
  let viewHeight = maxY - minY;

  const viewAspect = viewWidth / viewHeight;

  if (viewAspect > aspect) {
    viewHeight = viewWidth / aspect;
  } else {
    viewWidth = viewHeight * aspect;
  }

  const halfWidth = viewWidth / 2;
  const halfHeight = viewHeight / 2;

  camera = new THREE.OrthographicCamera(
    centerX - halfWidth,  //left
    centerX + halfWidth,  //right
    centerY + halfHeight, //top
    centerY - halfHeight, //bottom
    -10,
    100
  );

  camera.position.set(0, 0, 10);
  camera.lookAt(0, 0, 0);
  camera.updateProjectionMatrix();
}


// ---------------- Axes and Ticks ----------------
function createAxesAndTicks() {
  axesGroup.clear(); // update mechanism

  const axisMaterial = new THREE.LineBasicMaterial({ color: 0xffffff });
  const tickMaterial = new THREE.LineBasicMaterial({ color: 0xaaaaaa });

  // Axes

  // X
  axesGroup.add(new THREE.Line(
    new THREE.BufferGeometry().setFromPoints([
      new THREE.Vector3(0, 0, 0),
      new THREE.Vector3(X_AxisLength, 0, 0)
    ]),
    axisMaterial
  ));
  
  // Y
  axesGroup.add(new THREE.Line(
    new THREE.BufferGeometry().setFromPoints([
      new THREE.Vector3(0, 0, 0),
      new THREE.Vector3(0, Y_AxisLength, 0)
    ]),
    axisMaterial
  ));

  const tickSize = (camera.top - camera.bottom) / 50;

  // ---- X ticks ----
  const xTicks = 5;
  const xMin = 0;
  const xMax = 2 * props.H;

  for (let i = 0; i <= xTicks; i++) {
    const t = i / xTicks;
    const x = t * X_AxisLength;
    const realX = xMin + t * (xMax - xMin);
    if (i>=1) {
      axesGroup.add(new THREE.Line(
        new THREE.BufferGeometry().setFromPoints([
          new THREE.Vector3(x, -tickSize / 2, 0),
          new THREE.Vector3(x, tickSize / 2, 0)
        ]),
        tickMaterial
      ));
    }
    

    axesGroup.add(makeLabel(`${realX.toFixed(1)} m`, x, -tickSize * 2));
  }

  // ---- Y ticks ----
  const yTicks = 5;
  const yMax = Y_REAL_MAX.value;

  for (let i = 0; i <= yTicks; i++) {
    const t = i / yTicks;
    const y = t * Y_AxisLength;
    const realY = t * yMax;

    // Tick line
    if (i>=1) {
      axesGroup.add(new THREE.Line(
        new THREE.BufferGeometry().setFromPoints([
          new THREE.Vector3(-tickSize / 2, y, 0),
          new THREE.Vector3(tickSize / 2, y, 0)
        ]),
        tickMaterial
      ));
    }
    

    // Label
    axesGroup.add(makeLabel(`${realY.toFixed(0)} kN`, -tickSize * 5, y));
  }


}



// ---------------- Labels ----------------
function makeLabel(text, x, y, options = {}) {
  const { fontSize = 10, color = '#ffffff' } = options;

  const DPR = Math.max(window.devicePixelRatio, 2); // fixes low sprite resulution 
  const canvasLabel = document.createElement('canvas');
  const ctx = canvasLabel.getContext('2d');

  ctx.font = `${fontSize * DPR}px Arial`;
  const textWidth = ctx.measureText(text).width;

  canvasLabel.width = (textWidth + 8 * DPR);
  canvasLabel.height = (fontSize * DPR + 8 * DPR);

  ctx.font = `${fontSize * DPR}px Arial`;
  ctx.fillStyle = color;
  ctx.textBaseline = 'middle';
  ctx.textAlign = 'center';

  ctx.fillText(
    text,
    canvasLabel.width / 2,
    canvasLabel.height / 2
  );

  const texture = new THREE.CanvasTexture(canvasLabel);
  texture.minFilter = THREE.LinearFilter;
  texture.magFilter = THREE.LinearFilter;
  texture.generateMipmaps = false;

  const material = new THREE.SpriteMaterial({
    map: texture,
    transparent: true
  });

  const sprite = new THREE.Sprite(material);

  const scale = (camera.top - camera.bottom) / 15 / canvasLabel.height;
  sprite.scale.set(
    canvasLabel.width * scale,
    canvasLabel.height * scale,
    1
  );

  sprite.position.set(x, y, 0);
  return sprite;
}


function createLabels() {
  const paddingX = X_AxisLength * paddingRatio;
  const paddingY = Y_AxisLength * paddingRatio;
  //scene.add(makeLabel("L (m)", xLength / 2, -paddingY / 2));
  scene.add(makeLabel("L (m)", X_AxisLength*1.1, -paddingY / 10));
  scene.add(makeLabel("Ncr (kN)", -paddingX-1 / 2, Y_AxisLength / 2));
}

// ---------------- Curve ----------------

function generateNcrPoints() {
  if (!props.H || !props.K || !Iy.value || !props.E) return [];

  const points = [];
  const Lmin = Math.max(0.5 * props.H, 0.5);
  const Lmax = 2.0 * props.H;
  const step = props.H / 20;

  for (let L = Lmin; L <= Lmax; L += step) {
    const Lmm = L * 1000;
    const Ncr = (Math.PI ** 2 * props.E * Iy.value) / Math.pow(props.K * Lmm, 2);
    points.push({ x: L, y: Ncr * 1e-3 });
  }

  return points;
}

function createPoints() {
  const data = generateNcrPoints();
  return data.map(p => new THREE.Vector3(p.x, p.y, 0));
}



function drawNcrCurve() {
  if (!props.H || !props.K || !Iy.value || !props.E) return;

  if (curveLine) curveGroup.remove(curveLine);

  const data = generateNcrPoints();
  if (!data.length) return;

  // update Y axis range
  const maxNcr = Math.max(...data.map(p => p.y));
  // so it updates labels
  const newYMax = roundNice(maxNcr);

  Y_REAL_MAX.value = roundNice(maxNcr);
  createAxesAndTicks();



  //scale curve using Y_REAL_MAX
  const scaleY = Y_AxisLength / Y_REAL_MAX.value;

  const vertices = data.map(p =>
    new THREE.Vector3(
      mapX(p.x),
      p.y * scaleY,
      0
    )
  );

  curveLine = new THREE.Line(
    new THREE.BufferGeometry().setFromPoints(vertices),
    new THREE.LineBasicMaterial({ color: 0x00aaff })
  );

  curveGroup.add(curveLine);
  renderOnce();
}

function roundNice(value) {
  const exp = Math.floor(Math.log10(value));
  const f = value / Math.pow(10, exp);

  let nice;
  if (f < 1.5) nice = 1;
  else if (f < 3) nice = 2;
  else if (f < 7) nice = 5;
  else nice = 10;

  return nice * Math.pow(10, exp);
}

function mapX(realX) {
  const xMin = 0;
  const xMax = 2 * props.H;
  const range = xMax - xMin || 1;
  return ((realX - xMin) / range) * X_AxisLength;
}

// ---------------- Render ----------------
function renderOnce() {
  renderer.render(scene, camera);
}

// ---------------- Resize ----------------
function onResize() {
  const rect = canvas.value.parentElement.getBoundingClientRect();

  renderer.setSize(rect.width, rect.height, false);

  initCamera();
  renderOnce();
}

// ---------------- Lifecycle ----------------
onMounted(() => {
  initScene();
  window.addEventListener('resize', onResize);
});

// Clean up
onUnmounted(() => {
  window.removeEventListener('resize', onResize);
  renderer?.dispose();
});

// ---------------- Prop Watchers ----------------
watch(
  () => props.H,
  () => {
    createAxesAndTicks();
    renderOnce();
  }
);
watch(
  () => [props.H, props.K, props.E, Iy.value],
  () => {
    drawNcrCurve();
  }
);



watch(
  () => props.prepareGraphWindow,
  async () => {
    await nextTick(); // waits until canvas is visible and sized
    onResize();
  }
)

</script>

<style scoped>
.scene-root {
  width: 100%;
  height: 100%;
  flex: 0 0 auto;
}
canvas {

  display: block;
}
</style>
