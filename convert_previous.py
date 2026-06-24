import codecs

with open(r'C:\Users\admin\Desktop\new123\ticketing_host_editted\lib\features\chat\presentation\pages\global_chat_page.dart', 'rb') as f:
    raw = f.read()
    print(f'Previous version raw length: {len(raw)}')
    print(f'First 10 bytes: {raw[:10]}')
    
    decoded = raw.decode('utf-16-le')
    print(f'Decoded length: {len(decoded)}')
    
    with open(r'C:\Users\admin\Desktop\Adithya\ticketing_host_new\previous_global_chat_utf8.dart', 'w', encoding='utf-8') as f:
        f.write(decoded)
    print('Wrote previous version as UTF-8')

with open(r'C:\Users\admin\Desktop\Adithya\ticketing_host_new\lib\features\chat\presentation\pages\global_chat_page.dart', 'rb') as f:
    raw = f.read()
    print(f'Current version raw length: {len(raw)}')
    print(f'First 10 bytes: {raw[:10]}')
    
    try:
        decoded = raw.decode('utf-8')
        print(f'Current decoded length: {len(decoded)}')
    except Exception as e:
        print(f'Current decode failed: {e}')
