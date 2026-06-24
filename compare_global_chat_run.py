import os
import codecs

out_path = r'C:\Users\admin\Desktop\Adithya\ticketing_host_new\compare_global_chat_output.txt'
with open(out_path, 'w', encoding='utf-8') as out:
    paths = [
        r'C:\Users\admin\Desktop\new123\ticketing_host_editted\lib\features\chat\presentation\pages\global_chat_page.dart',
        r'C:\Users\admin\Desktop\Adithya\ticketing_host_new\lib\features\chat\presentation\pages\global_chat_page.dart'
    ]
    
    for path in paths:
        with open(path, 'rb') as f:
            raw = f.read()
            out.write(f'{path}: {len(raw)} bytes\n')
            out.write(f'  First 10 bytes: {raw[:10]}\n')
            out.write(f'  Null bytes: {raw.count(b"\\x00")}\n')
            
            decoded = None
            for enc in ['utf-8', 'utf-16-le', 'utf-16-be', 'utf-8-sig', 'utf-16']:
                try:
                    decoded = raw.decode(enc)
                    out.write(f'  Decoded as: {enc}, chars: {len(decoded)}\n')
                    break
                except:
                    pass
            out.write('\n')
print(f'Output written to {out_path}')
