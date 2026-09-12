const desktopQuery = window.matchMedia('(min-width: 960px)');
const motionQuery = window.matchMedia('(prefers-reduced-motion: reduce)');

// 首屏那台大一号、底框出画，是 CSS 按 data-active 切的（--phone-hero /
// --phone-fit），不走这里的 pose——两套动画各管各的，免得离散的 data-active
// 和连续的 progress 打架。
const POSES = [
  { scale: 1, x: 0, y: 0, ry: 0, rx: 0, rz: 0 },
  { scale: 1, x: 0, y: 0, ry: 0, rx: 0, rz: 0 },
  { scale: 0.98, x: -1, y: 0, ry: -10, rx: 3, rz: -1 },
  { scale: 1, x: 0, y: 0, ry: 0, rx: 0, rz: 0 },
  { scale: 0.84, x: 0, y: 0, ry: 8, rx: 0, rz: 0 },
];

function clamp(value, min, max) {
  return Math.min(max, Math.max(min, value));
}

function lerp(a, b, t) {
  return a + (b - a) * t;
}

function lerpPose(a, b, t) {
  return {
    scale: lerp(a.scale, b.scale, t),
    x: lerp(a.x, b.x, t),
    y: lerp(a.y, b.y, t),
    ry: lerp(a.ry, b.ry, t),
    rx: lerp(a.rx, b.rx, t),
    rz: lerp(a.rz, b.rz, t),
  };
}

function poseAt(progress) {
  const max = POSES.length - 1;
  if (progress <= 0) return POSES[0];
  if (progress >= max) return POSES[max];
  const index = Math.min(Math.floor(progress), max - 1);
  return lerpPose(POSES[index], POSES[index + 1], progress - index);
}

function sceneProgress(scenes) {
  const tops = scenes.map((scene) => scene.getBoundingClientRect().top);
  if (tops[0] >= 0) return 0;
  for (let i = 0; i < scenes.length - 1; i++) {
    const a = tops[i];
    const b = tops[i + 1];
    if (b >= 0) {
      const span = a - b;
      const t = span === 0 ? 1 : a / span;
      return i + clamp(t, 0, 1);
    }
  }
  return scenes.length - 1;
}

function restPose() {
  return { scale: 1, x: 0, y: 0, ry: 0, rx: 0, rz: 0 };
}

function applyPose(rig, phone, pose, on) {
  if (!on) {
    rig.style.transform = '';
    phone.style.transform = '';
    rig.style.setProperty('--turn', '0');
    return;
  }
  rig.style.transform = `rotateY(${pose.ry}deg) rotateX(${pose.rx}deg) rotateZ(${pose.rz}deg)`;
  phone.style.transform = `translate3d(${pose.x}%, ${pose.y}%, 0) scale(${pose.scale})`;
  const turn = clamp(Math.abs(pose.ry) / 12, 0, 1);
  rig.style.setProperty('--turn', String(turn));
}

function applyScreens(story, screens, progress, discrete, sceneCount) {
  const sceneActive = String(Math.round(clamp(progress, 0, sceneCount - 1)));
  if (story.dataset.active !== sceneActive) story.dataset.active = sceneActive;
  const phoneActive = Math.round(clamp(progress, 0, screens.length - 1));
  screens.forEach((screen, index) => {
    const opacity = discrete ? (index === phoneActive ? 1 : 0) : clamp(1 - Math.abs(progress - index), 0, 1);
    screen.style.opacity = String(opacity);
    if (opacity > 0.5) screen.removeAttribute('aria-hidden');
    else screen.setAttribute('aria-hidden', 'true');
  });
}

function applyLockNudge(story, desktop) {
  const phone = story.querySelector('.story-phone');
  const stage = phone?.querySelector('[data-lock-stage]');
  if (!(phone instanceof HTMLElement) || !(stage instanceof HTMLElement)) return;
  if (!desktop) {
    stage.style.setProperty('--lock-nudge', '0px');
    return;
  }
  const screen = phone.querySelector('.device-screen');
  const field = stage.querySelector('.lock-field');
  if (!(screen instanceof HTMLElement) || !(field instanceof HTMLElement)) return;
  const screenRect = screen.getBoundingClientRect();
  const fieldRect = field.getBoundingClientRect();
  const header = document.querySelector('.site-header');
  const host = story.querySelector('.story-stage');
  const headerBottom = header instanceof HTMLElement ? header.getBoundingClientRect().bottom : 0;
  const hostRect = host instanceof HTMLElement ? host.getBoundingClientRect() : { top: 0, bottom: window.innerHeight };
  const visibleTop = Math.max(screenRect.top, headerBottom, hostRect.top);
  const visibleBottom = Math.min(screenRect.bottom, window.innerHeight, hostRect.bottom);
  if (visibleBottom <= visibleTop + 40) return;
  const visibleMid = (visibleTop + visibleBottom) / 2;
  const fieldMid = (fieldRect.top + fieldRect.bottom) / 2;
  const delta = visibleMid - fieldMid;
  if (Math.abs(delta) < 0.5) return;
  const current = Number.parseFloat(stage.style.getPropertyValue('--lock-nudge')) || 0;
  stage.style.setProperty('--lock-nudge', `${current + delta}px`);
}

function applyCluster(story, progress, desktop, reduce) {
  const cluster = story.querySelector('.story-platforms');
  const rig = story.querySelector('.phone-3d');
  if (!(cluster instanceof HTMLElement) || !(rig instanceof HTMLElement)) return;
  if (!desktop) {
    cluster.style.opacity = '';
    cluster.style.transform = '';
    rig.style.opacity = '';
    return;
  }
  const t = clamp((progress - 3.12) / 0.72, 0, 1);
  const ease = t * t * (3 - 2 * t);
  const phoneOpacity = 1 - ease;
  const clusterOpacity = ease;
  rig.style.opacity = String(phoneOpacity);
  cluster.style.opacity = String(clusterOpacity);
  cluster.style.pointerEvents = clusterOpacity > 0.5 ? 'auto' : 'none';
  if (reduce) {
    cluster.style.transform = 'translate3d(0, -50%, 0)';
    return;
  }
  const scale = 0.92 + 0.08 * ease;
  const dy = (1 - ease) * 4;
  cluster.style.transform = `translate3d(0, calc(-50% + ${dy}%), 0) scale(${scale})`;
}

function applyLockStages(story, progress, desktop, reduce) {
  for (const stage of story.querySelectorAll('[data-lock-stage]')) {
    const sticky = Boolean(stage.closest('.story-phone'));
    const scene = Boolean(stage.closest('.scene-phone'));
    const play =
      !reduce &&
      !document.hidden &&
      ((desktop && sticky && progress >= 2.4) || (!desktop && scene && stage.classList.contains('is-inview')));
    stage.classList.toggle('is-playing', play);
    stage.classList.toggle('is-static', reduce);
  }
  applyLockNudge(story, desktop);
}

function bindStoryPhone(root = document) {
  for (const story of root.querySelectorAll('[data-story]')) {
    if (story.dataset.bound === '1') continue;
    story.dataset.bound = '1';
    const scenes = [...story.querySelectorAll('[data-scene]')];
    const rig = story.querySelector('.phone-3d');
    const phone = story.querySelector('.story-phone');
    const screens = [...story.querySelectorAll('.story-phone .screen')];
    if (scenes.length === 0 || !rig || !phone) continue;

    const lockObserver = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          entry.target.classList.toggle('is-inview', entry.isIntersecting);
        }
        requestTick();
      },
      { threshold: 0.45 },
    );
    for (const stage of story.querySelectorAll('.scene-phone [data-lock-stage]')) {
      lockObserver.observe(stage);
    }

    let ticking = false;
    const tick = () => {
      ticking = false;
      const desktop = desktopQuery.matches;
      const reduce = motionQuery.matches;
      if (!desktop) {
        applyPose(rig, phone, restPose(), false);
        applyLockStages(story, 0, false, reduce);
        applyCluster(story, 0, false, reduce);
        return;
      }
      const progress = sceneProgress(scenes);
      const pose = reduce ? restPose() : poseAt(progress);
      applyPose(rig, phone, pose, true);
      applyScreens(story, screens, reduce ? Math.round(progress) : progress, reduce, scenes.length);
      applyLockStages(story, progress, true, reduce);
      applyCluster(story, reduce ? Math.round(progress) : progress, true, reduce);
    };
    const requestTick = () => {
      if (ticking) return;
      ticking = true;
      requestAnimationFrame(tick);
    };

    window.addEventListener('scroll', requestTick, { passive: true });
    window.addEventListener('resize', requestTick);
    document.addEventListener('visibilitychange', requestTick);
    desktopQuery.addEventListener('change', requestTick);
    motionQuery.addEventListener('change', requestTick);
    tick();
  }
}

bindStoryPhone();
