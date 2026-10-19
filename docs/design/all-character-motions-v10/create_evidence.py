"""Encode all ten actual app motion captures and compare unaffected clips."""
from pathlib import Path
import hashlib
import json
import subprocess

OUT = Path(__file__).resolve().parent
CAPTURE = OUT/'capture'
OLD = OUT.parent/'all-character-motions-v9/capture'
manifest = json.loads((CAPTURE/'manifest.json').read_text())
report = {'frames':sum(e['frames'] for e in manifest),'videos':[],
          'unchangedClips':[],'newStudy':[]}
assert len(manifest)==10 and all(not e['static'] for e in manifest)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def decoded_hash(path):
    return subprocess.check_output([
        '/opt/homebrew/bin/ffmpeg','-v','error','-i',str(path),
        '-map','0:v:0','-f','hash','-hash','sha256','-',
    ],text=True).strip()


for entry in manifest:
    stem = entry['friend']+'-'+entry['mode']
    clip = CAPTURE/(stem+'.mp4')
    subprocess.run([
        '/opt/homebrew/bin/ffmpeg','-y','-v','error',
        '-framerate','12','-i',str(CAPTURE/'frames'/stem/'%04d.png'),
        '-an','-c:v','libx264','-threads','2','-preset','fast','-crf','18',
        '-pix_fmt','yuv420p','-movflags','+faststart',str(clip),
    ],check=True)
    metadata = json.loads(subprocess.check_output([
        '/opt/homebrew/bin/ffprobe','-v','error','-select_streams','v:0',
        '-show_entries','stream=width,height,nb_frames,avg_frame_rate',
        '-show_entries','format=duration','-of','json',str(clip),
    ]))
    stream=metadata['streams'][0]
    assert stream['avg_frame_rate']=='12/1'
    assert int(stream['nb_frames'])==entry['frames']
    assert abs(float(metadata['format']['duration'])-entry['clipSeconds'])<.001
    report['videos'].append({'clip':stem,**metadata})
    if entry['friend'] in ['squirrel','fennec'] and entry['mode']=='study':
        assert entry['frames']==486
        assert set(entry['phases'])=={'writing','pageTurn'}
        frames=CAPTURE/'frames'/stem
        same=sha(frames/'0000.png')==sha(frames/'0485.png')
        assert same, f'Loop seam changed: {stem}'
        report['newStudy'].append({'clip':stem,'seconds':40.5,'fps':12,
            'frames':486,'canonicalLoopSeamExact':same,
            'phases':entry['phases'],
            'seenCels':sorted({s['from'] for s in entry['samples']})})
    else:
        before=decoded_hash(OLD/(stem+'.mp4'))
        after=decoded_hash(clip)
        assert before==after, f'Unrelated motion changed: {stem}'
        report['unchangedClips'].append({'clip':stem,'frames':entry['frames'],
            'decodedFrameSha256':after,'matchesV9':True})
(OUT/'verification.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
