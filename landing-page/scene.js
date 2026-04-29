import * as THREE from 'three';

// ── 3D Particle Background ──────────────────────────────────────────
const canvas = document.getElementById('bg-canvas');
if (canvas) {
    const renderer = new THREE.WebGLRenderer({ canvas, alpha: true, antialias: true });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    renderer.setSize(window.innerWidth, window.innerHeight);

    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 0.1, 1000);
    camera.position.z = 30;

    // Particle system — floating pink/purple orbs
    const particleCount = 120;
    const positions = new Float32Array(particleCount * 3);
    const colors = new Float32Array(particleCount * 3);
    const sizes = new Float32Array(particleCount);
    const velocities = [];

    const palette = [
        new THREE.Color(0xE05D83), // primary pink
        new THREE.Color(0xA865B5), // purple
        new THREE.Color(0xFF7A9C), // coral
        new THREE.Color(0xBB86CF), // lavender
        new THREE.Color(0x7EC8A4), // mint
        new THREE.Color(0x7AB3D4), // sky blue
    ];

    for (let i = 0; i < particleCount; i++) {
        positions[i * 3] = (Math.random() - 0.5) * 60;
        positions[i * 3 + 1] = (Math.random() - 0.5) * 60;
        positions[i * 3 + 2] = (Math.random() - 0.5) * 40;

        const color = palette[Math.floor(Math.random() * palette.length)];
        colors[i * 3] = color.r;
        colors[i * 3 + 1] = color.g;
        colors[i * 3 + 2] = color.b;

        sizes[i] = Math.random() * 2.5 + 0.5;

        velocities.push({
            x: (Math.random() - 0.5) * 0.008,
            y: (Math.random() - 0.5) * 0.008,
            z: (Math.random() - 0.5) * 0.004,
            phase: Math.random() * Math.PI * 2
        });
    }

    const geometry = new THREE.BufferGeometry();
    geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    geometry.setAttribute('color', new THREE.BufferAttribute(colors, 3));
    geometry.setAttribute('size', new THREE.BufferAttribute(sizes, 1));

    // Custom shader for soft glowing particles
    const material = new THREE.ShaderMaterial({
        uniforms: {
            uTime: { value: 0 },
            uPixelRatio: { value: renderer.getPixelRatio() }
        },
        vertexShader: `
            attribute float size;
            attribute vec3 color;
            varying vec3 vColor;
            varying float vAlpha;
            uniform float uTime;
            uniform float uPixelRatio;

            void main() {
                vColor = color;
                vec4 mvPos = modelViewMatrix * vec4(position, 1.0);
                float pulse = 0.8 + 0.2 * sin(uTime * 0.5 + position.x * 0.3);
                gl_PointSize = size * uPixelRatio * (80.0 / -mvPos.z) * pulse;
                gl_Position = projectionMatrix * mvPos;
                vAlpha = smoothstep(60.0, 10.0, -mvPos.z) * 0.6;
            }
        `,
        fragmentShader: `
            varying vec3 vColor;
            varying float vAlpha;

            void main() {
                float d = length(gl_PointCoord - 0.5);
                if (d > 0.5) discard;
                float alpha = smoothstep(0.5, 0.0, d) * vAlpha;
                gl_FragColor = vec4(vColor, alpha);
            }
        `,
        transparent: true,
        depthWrite: false,
        blending: THREE.AdditiveBlending
    });

    const particles = new THREE.Points(geometry, material);
    scene.add(particles);

    // Floating torus knots (glass-like)
    const torusGeom = new THREE.TorusKnotGeometry(3, 0.8, 100, 16);
    const torusMat = new THREE.MeshBasicMaterial({
        color: 0xE05D83,
        wireframe: true,
        transparent: true,
        opacity: 0.06
    });
    const torus1 = new THREE.Mesh(torusGeom, torusMat);
    torus1.position.set(-18, 8, -15);
    scene.add(torus1);

    const torus2Mat = new THREE.MeshBasicMaterial({
        color: 0xA865B5,
        wireframe: true,
        transparent: true,
        opacity: 0.04
    });
    const torus2 = new THREE.Mesh(
        new THREE.TorusKnotGeometry(2.5, 0.6, 80, 12),
        torus2Mat
    );
    torus2.position.set(20, -10, -20);
    scene.add(torus2);

    // Floating icosahedron
    const icoGeom = new THREE.IcosahedronGeometry(4, 1);
    const icoMat = new THREE.MeshBasicMaterial({
        color: 0x7EC8A4,
        wireframe: true,
        transparent: true,
        opacity: 0.05
    });
    const ico = new THREE.Mesh(icoGeom, icoMat);
    ico.position.set(15, 12, -18);
    scene.add(ico);

    // Mouse parallax
    let mouseX = 0, mouseY = 0;
    document.addEventListener('mousemove', (e) => {
        mouseX = (e.clientX / window.innerWidth - 0.5) * 2;
        mouseY = (e.clientY / window.innerHeight - 0.5) * 2;
    });

    // Scroll tracking
    let scrollY = 0;
    window.addEventListener('scroll', () => { scrollY = window.scrollY; });

    // Animation loop
    let time = 0;
    function animate() {
        requestAnimationFrame(animate);
        time += 0.016;

        material.uniforms.uTime.value = time;

        // Move particles gently
        const pos = geometry.attributes.position.array;
        for (let i = 0; i < particleCount; i++) {
            const v = velocities[i];
            pos[i * 3] += v.x + Math.sin(time * 0.3 + v.phase) * 0.003;
            pos[i * 3 + 1] += v.y + Math.cos(time * 0.2 + v.phase) * 0.003;
            pos[i * 3 + 2] += v.z;

            // Wrap around
            if (pos[i * 3] > 30) pos[i * 3] = -30;
            if (pos[i * 3] < -30) pos[i * 3] = 30;
            if (pos[i * 3 + 1] > 30) pos[i * 3 + 1] = -30;
            if (pos[i * 3 + 1] < -30) pos[i * 3 + 1] = 30;
        }
        geometry.attributes.position.needsUpdate = true;

        // Rotate geometry
        torus1.rotation.x += 0.002;
        torus1.rotation.y += 0.003;
        torus2.rotation.x -= 0.003;
        torus2.rotation.z += 0.002;
        ico.rotation.x += 0.001;
        ico.rotation.y += 0.002;

        // Camera parallax with mouse and scroll
        camera.position.x += (mouseX * 2 - camera.position.x) * 0.02;
        camera.position.y += (-mouseY * 2 - scrollY * 0.005 - camera.position.y) * 0.02;
        camera.lookAt(0, -scrollY * 0.003, 0);

        renderer.render(scene, camera);
    }
    animate();

    // Resize handler
    window.addEventListener('resize', () => {
        camera.aspect = window.innerWidth / window.innerHeight;
        camera.updateProjectionMatrix();
        renderer.setSize(window.innerWidth, window.innerHeight);
        material.uniforms.uPixelRatio.value = renderer.getPixelRatio();
    });
}
