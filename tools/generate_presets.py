#!/usr/bin/env python3
"""
Fetch songs from GD Studio API and generate preset mode data as JSON asset.
Each mode uses multiple keywords to collect 100+ unique songs.
Delays between requests to avoid rate limiting.
"""

import json
import time
import urllib.request
import urllib.parse

API = 'https://music-api.gdstudio.xyz/api.php'

MODES = {
    '怀旧老歌': ['经典老歌', '80年代经典', '90年代金曲', '怀旧金曲', '老歌精选'],
    'R&B': ['rnb', 'r&b经典', '节奏布鲁斯', 'rnb热门', 'soul音乐'],
    '国风': ['国风音乐', '古风歌曲', '中国风', '古风', '国潮'],
    '粤语经典': ['粤语经典', '粤语歌曲', '粤语金曲', '广东歌', '粤语情歌'],
    'KTV必点': ['ktv必点', 'ktv热歌', 'ktv经典', 'k歌金曲', '麦霸必唱'],
    '轻音乐': ['轻音乐', '纯音乐', '钢琴曲', '放松音乐', '治愈音乐'],
    '热门流行': ['热门歌曲', '流行音乐', '最新流行', '抖音热歌', '网络热歌'],
    '说唱嘻哈': ['中文说唱', '嘻哈', 'hiphop中文', '说唱歌曲', 'rap中文'],
    '民谣': ['民谣', '民谣歌曲', '独立民谣', '校园民谣', '文艺民谣'],
    '摇滚': ['摇滚', '中国摇滚', '摇滚经典', '独立摇滚', '朋克'],
    '电子': ['电子音乐', 'EDM', '电音', 'house音乐', 'DJ热歌'],
    '情歌对唱': ['情歌对唱', '甜蜜情歌', '浪漫情歌', '爱情歌曲', '表白歌曲'],
    '伤感情歌': ['伤感歌曲', '失恋歌曲', '催泪情歌', '心碎歌曲', '难过的歌'],
    '欧美热歌': ['欧美流行', '英文歌曲', '欧美经典', '英文热歌', 'pop hits'],
    '日语歌曲': ['日语歌曲', '日本流行', 'jpop', '日语经典', '动漫歌曲'],
    '韩语歌曲': ['韩语歌曲', 'kpop', '韩国流行', '韩语热歌', '韩流音乐'],
    '影视金曲': ['影视歌曲', '电视剧主题曲', '电影原声', '影视金曲', '综艺歌曲'],
    '运动健身': ['运动音乐', '健身歌曲', '跑步音乐', '燃脂音乐', '动感音乐'],
    '深夜治愈': ['深夜歌曲', '睡前音乐', '安静的歌', '夜晚听歌', '助眠音乐'],
    '华语男歌手': ['周杰伦', '林俊杰', '薛之谦', '陈奕迅', '李荣浩'],
    '华语女歌手': ['邓紫棋', '田馥甄', '蔡依林', '张韶涵', '王菲'],
}

def search(keyword, source='netease', count=30, page=1):
    params = urllib.parse.urlencode({
        'types': 'search',
        'source': source,
        'name': keyword,
        'count': count,
        'pages': page,
    })
    url = f'{API}?{params}'
    req = urllib.request.Request(url, headers={
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
                      'AppleWebKit/537.36 (KHTML, like Gecko)',
    })
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read())
            if isinstance(data, list):
                return data
    except Exception as e:
        print(f'    [ERROR] {keyword}: {e}')
    return []


def parse_tracks(items, source='netease'):
    """Convert API items to SearchVideoModel-compatible dicts."""
    tracks = []
    for item in items:
        try:
            tid = str(item.get('id', ''))
            name = item.get('name', '')
            artist = item.get('artist', [])
            if isinstance(artist, list):
                artist = ' / '.join(str(a) for a in artist)
            else:
                artist = str(artist)
            album = item.get('album', '')
            pic_id = str(item.get('pic_id', ''))
            lyric_id = str(item.get('lyric_id', ''))
            src = item.get('source', source)

            int_id = int(tid) if tid.isdigit() else hash(tid) & 0x7FFFFFFF

            tracks.append({
                'id': int_id,
                'author': artist,
                'mid': 0,
                'title': name,
                'description': album,
                'pic': '',
                'play': 0,
                'danmaku': 0,
                'duration': '0:00',
                'bvid': f'{src}:{tid}:{lyric_id}:{pic_id}',
                'arcurl': '',
                'source': 'gdstudio',
            })
        except Exception as e:
            print(f'    [PARSE ERROR] {e}')
    return tracks


def collect_mode(mode_name, keywords):
    """Collect unique tracks for one mode using multiple keywords."""
    seen_ids = set()
    all_tracks = []

    for kw in keywords:
        print(f'  Searching: "{kw}" ...', end=' ', flush=True)
        items = search(kw, count=30, page=1)
        tracks = parse_tracks(items)
        added = 0
        for t in tracks:
            uid = f"gdstudio_{t['id']}"
            if uid not in seen_ids:
                seen_ids.add(uid)
                all_tracks.append(t)
                added += 1
        print(f'{added} new ({len(all_tracks)} total)')
        time.sleep(1.5)

        # If still under 100, try page 2
        if len(all_tracks) < 100:
            items2 = search(kw, count=30, page=2)
            tracks2 = parse_tracks(items2)
            added2 = 0
            for t in tracks2:
                uid = f"gdstudio_{t['id']}"
                if uid not in seen_ids:
                    seen_ids.add(uid)
                    all_tracks.append(t)
                    added2 += 1
            if added2 > 0:
                print(f'    page 2: {added2} new ({len(all_tracks)} total)')
            time.sleep(1.5)

    print(f'  → {mode_name}: {len(all_tracks)} tracks\n')
    return all_tracks


def main():
    presets = []

    for mode_name, keywords in MODES.items():
        print(f'[{mode_name}]')
        tracks = collect_mode(mode_name, keywords)
        presets.append({
            'name': mode_name,
            'tracks': tracks,
        })

    output = '/Users/linghua/linghuaplayer/assets/data/preset_modes.json'
    import os
    os.makedirs(os.path.dirname(output), exist_ok=True)

    with open(output, 'w', encoding='utf-8') as f:
        json.dump(presets, f, ensure_ascii=False, indent=None)

    total = sum(len(m['tracks']) for m in presets)
    print(f'Done! {len(presets)} modes, {total} total tracks')
    print(f'Saved to: {output}')
    size_kb = os.path.getsize(output) / 1024
    print(f'File size: {size_kb:.1f} KB')


if __name__ == '__main__':
    main()
