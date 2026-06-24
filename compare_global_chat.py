import os
import codecs

paths = [
    r'C:\Users\admin\Desktop\new123\ticketing_host_editted\lib\features\chat\presentation\pages\global_chat_page.dart',
    r'C:\Users\admin\Desktop\Adithya\ticketing_host_new\lib\features\chat\presentation\pages\global_chat_page.dart'
]

for path in paths:
    with open(path, 'rb') as f:
        raw = f.read()
        print(f'{path}: {len(raw)} bytes')
        print(f'  First 10 bytes: {raw[:10]}')
        print(f'  Null bytes: {raw.count(b"\\x00")}')
        
        # Try to decode
        for enc in ['utf-8', 'utf-16-le', 'utf-16-be', 'utf-8-sig', 'utf-16']:
            try:
                decoded = raw.decode(enc)
                print(f'  Decoded as: {enc}, chars: {len(decoded)}')
                break
            except:
                pass
        print()
