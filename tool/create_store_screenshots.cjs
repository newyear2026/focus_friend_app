#!/usr/bin/env node
// Compose real Flutter captures with editable typography. No generated UI.
// Requires the bundled @napi-rs/canvas and sharp packages via NODE_PATH.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { spawnSync } = require('node:child_process');
const { createCanvas, loadImage, GlobalFonts } = require('@napi-rs/canvas');
const sharp = require('sharp');

const ROOT = path.resolve(__dirname, '..');
const LANG = process.argv[2] || 'ko';
if (!['ko', 'en'].includes(LANG)) throw new Error('Supported locales: ko, en');
const EN = LANG === 'en';
const CREATED = EN ? '2026-10-16' : '2026-10-15';
const CAPTURE_COMMAND = 'flutter test --no-pub tool/capture_store_screenshots_test.dart'
  + (EN ? ` --dart-define=STORE_SCREENSHOT_LOCALE=en --dart-define=STORE_SCREENSHOT_DATE=${CREATED}` : '')
  + ' --reporter expanded';
const OUT = path.join(ROOT, `deliverables/store_screenshots/${LANG}`);
const W = 1080, H = 1920;
const FONT = 'DeskmatePretendard';
GlobalFonts.registerFromPath(path.join(ROOT, 'assets/fonts/PretendardVariable.ttf'), FONT);
const scenes = [
  { id: '01_together', title: ['혼자 말고,', '함께 집중해요'],
    colors: ['#352734', '#785047'], text: '#FFF3D8', accent: '#FFD08C',
    source: 'redpanda-focus', alt: '랫서팬더가 책상에서 공부하고, 실제 집중 타이머에 25분이 표시됩니다.' },
  { id: '02_friends', title: ['내 마음에 드는', '친구와 함께'],
    colors: ['#FFF5E1', '#E9D0AC'], text: '#493529', accent: '#A9592B',
    source: 'friends', alt: '친구 선택 화면의 랫서팬더·펭귄·해달·다람쥐와 사막여우의 실제 책상 화면입니다.' },
  { id: '03_day_and_night', title: ['아침부터 밤까지,', '나만의 집중방'],
    colors: ['#EEF1E2', '#CCD5BF'], text: '#384A37', accent: '#6B744B',
    source: 'room-morning', alt: '같은 랫서팬더 책상이 아침, 낮, 저녁, 밤의 빛으로 바뀌는 실제 앱 화면 네 개입니다.' },
  { id: '04_focus_sounds', title: ['편안한 소리로', '몰입해요'],
    colors: ['#2C3943', '#537472'], text: '#FFF3D8', accent: '#FFD08C',
    source: 'sound', alt: '집중 사운드 화면에서 빗소리, 숲, 장작 소리를 선택하고 음량을 조절할 수 있습니다.' },
  { id: '05_small_habits', title: ['작은 집중이', '쌓이는 하루'],
    colors: ['#FFF4DF', '#ECD1AE'], text: '#493529', accent: '#A9592B',
    source: 'records', alt: '2026년 10월의 예시 집중 기록입니다. 달력에 집중한 날의 랫서팬더 스탬프가 표시됩니다.' },
  { id: '06_little_rewards', title: ['집중 끝에 만나는', '작은 선물'],
    colors: ['#493127', '#936344'], text: '#FFF3D8', accent: '#FFD08C',
    source: 'collection', alt: '모은 소품 화면에 집중으로 해금한 작은 화분, 따뜻한 머그컵, 포근한 조명이 표시됩니다.' },
];
if (EN) {
  const english = [
    { title: ['Focus feels better', 'with a friend.'],
      alt: 'A red panda studies at a cozy desk while the real focus timer shows 25 minutes.' },
    { title: ['Find your', 'favorite friend.'],
      alt: 'Choose a red panda, penguin, sea otter, squirrel or fennec fox. Each friend has a different room.' },
    { title: ['A cozy space,', 'day and night.'],
      alt: 'Four real app screens show the same red panda desk in morning, daytime, evening and night light.' },
    { title: ['Settle in with', 'soothing sounds.'],
      alt: 'The Focus sounds panel offers rain, forest and fire sounds, a volume slider and automatic stop at the end of focus.' },
    { title: ['Small moments.', 'Steady progress.'],
      alt: 'Example focus records for October 2026 show a calendar with red panda stamps on the days focused, through October 16.' },
    { title: ['A little focus.', 'A little reward.'],
      alt: 'The Collected items screen shows a little plant, warm mug and cozy lamp unlocked by completing focus sessions.' },
  ];
  scenes.forEach((scene, index) => Object.assign(scene, english[index]));
}
const images = new Map();
const textBounds = [];

async function img(relative) {
  const filename = path.join(ROOT, relative);
  if (!images.has(filename)) images.set(filename, await loadImage(filename));
  return images.get(filename);
}
async function source(name) {
  return img(`deliverables/store_screenshots/${LANG}/sources/${name}.png`);
}
function rounded(ctx, x, y, w, h, r) {
  ctx.beginPath();
  ctx.roundRect(x, y, w, h, r);
}
function text(ctx, value, x, baseline, size, weight, color, maxWidth = W - 144) {
  ctx.font = `${Math.round(weight / 100) * 100} ${size}px ${FONT}`;
  ctx.fillStyle = color;
  ctx.textAlign = 'left';
  const bounds = ctx.measureText(value);
  if (bounds.width > maxWidth) throw new Error(`Text overflow: ${value}: ${bounds.width}`);
  ctx.fillText(value, x, baseline);
  textBounds.push({ text: value, x, baseline, size, width: Math.round(bounds.width) });
}
function background(ctx, scene) {
  const gradient = ctx.createLinearGradient(0, 0, W, H);
  gradient.addColorStop(0, scene.colors[0]);
  gradient.addColorStop(1, scene.colors[1]);
  ctx.fillStyle = gradient;
  ctx.fillRect(0, 0, W, H);
  // Broad, quiet light behind the app, with no ornamental artwork.
  const light = ctx.createRadialGradient(740, 1110, 40, 740, 1110, 1000);
  light.addColorStop(0, '#FFD18F20');
  light.addColorStop(1, '#FFD18F00');
  ctx.fillStyle = light;
  ctx.fillRect(0, 0, W, H);
}
async function header(ctx, scene) {
  const icon = await img('assets/icon/app_icon.png');
  ctx.save();
  rounded(ctx, 72, 61, 64, 64, 16);
  ctx.clip();
  ctx.drawImage(icon, 72, 61, 64, 64);
  ctx.restore();
  text(ctx, 'Deskmate', 153, 106, 37, 750, scene.text);
  const sizes = !EN && scene.id === '06_little_rewards' ? [78, 88] : [84, 88];
  text(ctx, scene.title[0], 72, 235, sizes[0], 800, scene.text);
  text(ctx, scene.title[1], 72, 337, sizes[1], 850, scene.accent);
}
function frame(ctx, image, x, y, width, radius = 32) {
  const height = width * image.height / image.width;
  ctx.save();
  ctx.shadowColor = '#1D142838';
  ctx.shadowBlur = 34;
  ctx.shadowOffsetY = 14;
  ctx.fillStyle = '#FFF1D9';
  rounded(ctx, x - 4, y - 4, width + 8, height + 8, radius + 3);
  ctx.fill();
  ctx.restore();
  ctx.save();
  rounded(ctx, x, y, width, height, radius);
  ctx.clip();
  ctx.drawImage(image, x, y, width, height);
  ctx.restore();
  return height;
}
function centered(ctx, value, center, baseline, size, color) {
  ctx.font = `700 ${size}px ${FONT}`;
  text(ctx, value, center - ctx.measureText(value).width / 2, baseline, size, 650, color);
}

async function render(scene) {
  const canvas = createCanvas(W, H);
  const ctx = canvas.getContext('2d');
  background(ctx, scene);
  await header(ctx, scene);
  if (scene.id === '02_friends') {
    frame(ctx, await source('friends'), 72, 421, 686, 30);
    frame(ctx, await source('fennec-home'), 561, 917, 438, 27);
    centered(ctx, EN ? 'Five friends. Five cozy rooms.' : '다섯 친구, 다섯 가지 작은 방', W / 2, 1823, 37, '#79563B');
  } else if (scene.id === '03_day_and_night') {
    const periods = EN
      ? [['morning', 'Morning'], ['day', 'Daytime'], ['evening', 'Evening'], ['night', 'Night']]
      : [['morning', '아침'], ['day', '낮'], ['evening', '저녁'], ['night', '밤']];
    for (let i = 0; i < periods.length; i++) {
      const [period, label] = periods[i];
      const x = i % 2 === 0 ? 116 : 584;
      const y = i < 2 ? 434 : 1185;
      centered(ctx, label, x + 190, y - 23, 31, scene.text);
      frame(ctx, await source(`room-${period}`), x, y, 380, 20);
    }
  } else if (scene.id === '06_little_rewards') {
    frame(ctx, await source(scene.source), 160, 409, 760);
  } else {
    frame(ctx, await source(scene.source), 134, 409, 812);
  }
  const buffer = canvas.toBuffer('image/png');
  const pngPath = path.join(OUT, `${scene.id}.png`);
  await sharp(buffer).removeAlpha().png({ compressionLevel: 9 }).toFile(pngPath);
  await sharp(buffer).removeAlpha().jpeg({ quality: 96, chromaSubsampling: '4:4:4' })
    .toFile(path.join(OUT, `${scene.id}.jpg`));
  return pngPath;
}

async function overview(paths, columns, thumbWidth, filename) {
  const gap = 26, margin = 48, top = 138;
  const thumbHeight = thumbWidth * H / W;
  const rows = Math.ceil(paths.length / columns);
  const width = margin * 2 + columns * thumbWidth + (columns - 1) * gap;
  const height = Math.ceil(top + rows * (thumbHeight + 44) + (rows - 1) * gap + 26);
  const canvas = createCanvas(width, height);
  const ctx = canvas.getContext('2d');
  ctx.fillStyle = '#F2E7D7'; ctx.fillRect(0, 0, width, height);
  text(ctx, 'Deskmate', margin, 68, 36, 800, '#3F3029', width - margin * 2);
  text(ctx, EN ? 'A cozy place to focus · English store screenshots' : '함께 집중하는 작은 방 · 스토어 스크린샷', margin, 106, 21, 500, '#846B55', width - margin * 2);
  for (let i = 0; i < paths.length; i++) {
    const x = margin + (i % columns) * (thumbWidth + gap);
    const y = top + Math.floor(i / columns) * (thumbHeight + 44 + gap);
    const image = await loadImage(paths[i]);
    ctx.drawImage(image, x, y, thumbWidth, thumbHeight);
    const labels = EN
      ? ['Focus together', 'Meet your friend', 'Day & night', 'Focus sounds', 'Your progress', 'Little rewards']
      : ['함께 집중', '다섯 친구', '시간대별 방', '집중 사운드', '집중 기록', '작은 선물'];
    text(ctx, `${String(i + 1).padStart(2, '0')}  ${labels[i]}`, x, y + thumbHeight + 29,
      20, 650, '#6D5644', thumbWidth);
  }
  await sharp(canvas.toBuffer('image/png')).removeAlpha().png()
    .toFile(path.join(OUT, filename));
}

async function main() {
  const paths = [];
  for (const scene of scenes) paths.push(await render(scene));
  await overview(paths, 3, 390, 'overview.png');
  await overview(paths, 6, 360, 'strip.png');
  const files = [];
  for (const scene of scenes) {
    for (const ext of ['png', 'jpg']) {
      const file = `${scene.id}.${ext}`;
      const bytes = fs.readFileSync(path.join(OUT, file));
      const meta = await sharp(bytes).metadata();
      if (meta.width !== W || meta.height !== H || meta.hasAlpha || meta.channels !== 3)
        throw new Error(`Invalid export: ${file}`);
      files.push({ file, width: meta.width, height: meta.height, channels: meta.channels,
        bytes: bytes.length, sha256: crypto.createHash('sha256').update(bytes).digest('hex') });
    }
  }
  const manifest = {
    title: `Deskmate ${EN ? 'English' : 'Korean'} store screenshots`, locale: EN ? 'en-US' : 'ko-KR', created: CREATED,
    dimensions: { width: W, height: H },
    method: 'Real current Flutter widgets captured at 390×700 logical pixels (collection: 390×750), at 3× resolution. Marketing typography and layout composed deterministically with Canvas.',
    font: 'Pretendard Variable (bundled OFL font)',
    imageGeneration: false,
    demoData: `Isolated in-memory demonstration state. Dates are October 2026, through October ${EN ? '16' : '15'}. No installed app database is accessed.`,
    appIcon: 'assets/icon/app_icon.png (current app icon at render time)',
    localization: EN ? 'English marketing copy, English app locale, English panel labels and alt text. Original in-scene illustration artwork is preserved.' : 'Korean marketing copy and app locale.',
    sources: scenes.map(({ id, title, source, alt }) => ({ id, title: title.join(' '), source: `${source}.png`, alt })),
    files,
    quality: { allExports1080x1920: true, allExportsRGBWithoutAlpha: true,
      textOverflowChecksPassed: true, captureCommand: CAPTURE_COMMAND },
    guidelines: `https://support.google.com/googleplay/android-developer/answer/9866151?hl=${LANG}`,
  };
  fs.writeFileSync(path.join(OUT, 'manifest.json'), JSON.stringify(manifest, null, 2) + '\n');
  fs.writeFileSync(path.join(OUT, 'alt-text.tsv'), `file\talt_text_${LANG}\n` + scenes.map(s => `${s.id}.png\t${s.alt}`).join('\n') + '\n');
  const readme = EN
    ? `# Deskmate store screenshots · English\n\n${CREATED} · 6 images · 1080×1920px · RGB PNG/JPEG\n\nUpload 01 through 06 in order. PNG and JPEG versions have the same design; choose one format. The ZIP contains the six uploadable PNGs, overview and supporting notes.\n\n- overview.png: 3×2 preview\n- strip.png: six-image horizontal preview\n- sources/: new captures of the actual English app widgets\n- alt-text.tsv: English alt text for each image\n- manifest.json: sources, dimensions and hashes\n\n## Sequence\n\n${scenes.map(s => `- ${s.id}: ${s.title.join(' ')}`).join('\n')}\n\n## Production\n\nMarketing copy and app controls are in English. Original illustration artwork is preserved. The current morning app icon is used. Records and unlocked items use isolated in-memory demonstration data, through October 16, 2026. No installed app database is read or changed.\n\nCapture: ${CAPTURE_COMMAND}\n\nCompose: node tool/create_store_screenshots.cjs en (set NODE_PATH to the bundled @napi-rs/canvas and sharp packages).\n\nFont: assets/fonts/PretendardVariable.ttf; OFL license: assets/fonts/OFL.txt.\n`
    : `# Deskmate 스토어 스크린샷 · 한국어\n\n2026-10-15 · 6장 · 1080×1920px · RGB PNG/JPEG\n\n01부터 06 순서로 사용할 수 있습니다. PNG와 JPEG는 같은 디자인입니다. 스토어에는 둘 중 한 형식의 6장만 선택하세요.\n\n- overview.png: 3×2 전체 미리보기\n- strip.png: 6장 가로 미리보기\n- sources/: 현재 앱 위젯으로 새로 캡처한 원본\n- alt-text.tsv: 이미지별 한국어 대체 텍스트\n- manifest.json: 제작 방법, 원본 연결, 이미지 크기, 해시\n\n## 구성\n\n${scenes.map(s => `- ${s.id}: ${s.title.join(' ')}`).join('\n')}\n\n## 제작 및 재현\n\n현재 앱의 실제 Flutter 화면과 기존 앱 아이콘만 사용했습니다. 새 일러스트나 가상 UI는 생성하지 않았습니다. 기록·해금 상태는 2026년 10월 15일 기준의 독립된 메모리 예시입니다. 실제 앱과 사용자 저장 데이터는 수정하지 않습니다.\n\n캡처: ${CAPTURE_COMMAND}\n\n레이아웃/문구 편집 및 재출력: tool/create_store_screenshots.cjs (NODE_PATH에 @napi-rs/canvas와 sharp가 필요합니다.)\n\n글꼴: assets/fonts/PretendardVariable.ttf, OFL 라이선스는 assets/fonts/OFL.txt.\n\n[Google Play 프리뷰 에셋 안내](https://support.google.com/googleplay/android-developer/answer/9866151?hl=ko)\n`;
  fs.writeFileSync(path.join(OUT, 'README.md'), readme);
  const cards = scenes.map(s => `<figure><img src="${s.id}.png" alt="${s.alt}"><figcaption>${s.title.join(' ')} <a href="${s.id}.png" download>PNG</a> <a href="${s.id}.jpg" download>JPEG</a></figcaption></figure>`).join('\n');
  fs.writeFileSync(path.join(OUT, 'preview.html'), `<!doctype html><html lang="${LANG}"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Deskmate · ${EN ? 'Store screenshots' : '스토어 스크린샷'}</title><style>*{box-sizing:border-box}body{margin:0;background:#f2e7d7;color:#493529;font:16px system-ui,sans-serif}header{max-width:1500px;margin:auto;padding:40px 28px 20px}h1{margin:0 0 10px;font-size:30px}p{color:#80654f}main{max-width:1500px;margin:auto;padding:0 28px 40px;display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:28px}figure{margin:0}img{width:100%;display:block}figcaption{padding:14px 0;line-height:1.8}a{color:inherit;margin-left:12px}@media(max-width:800px){main{grid-template-columns:repeat(2,minmax(0,1fr))}}@media(max-width:500px){main{grid-template-columns:1fr}}</style><header><h1>Deskmate</h1><p>${EN ? 'A cozy place to focus · 6 English screenshots' : '함께 집중하는 작은 방 · 한국어 6장'} · 1080×1920</p></header><main>${cards}</main></html>`);
  const archive = path.join(OUT, `deskmate-store-screenshots-${LANG}.zip`);
  if (fs.existsSync(archive)) fs.unlinkSync(archive);
  const uploadFiles = scenes.map(s => `${s.id}.png`);
  const zip = spawnSync('/usr/bin/zip', ['-q', '-j', archive, ...uploadFiles, 'README.md', 'alt-text.tsv', 'manifest.json', 'overview.png'], { cwd: OUT, encoding: 'utf8' });
  if (zip.status !== 0) throw new Error(zip.stderr);
  console.log(JSON.stringify({ exported: files.length, dimensions: `${W}×${H}`, overview: path.join(OUT, 'overview.png'), archive, bytes: fs.statSync(archive).size }, null, 2));
}
main().catch(error => { console.error(error); process.exitCode = 1; });
