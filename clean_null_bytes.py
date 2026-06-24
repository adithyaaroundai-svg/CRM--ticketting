with open(r'C:\Users\admin\Desktop\Adithya\ticketing_host_new\lib\features\chat\presentation\pages\global_chat_page.dart', 'rb') as f:
    content = f.read()
    null_count = content.count(b'\x00')
    print(f'Null bytes found: {null_count}')
    try:
        decoded = content.decode('utf-8')
        print('Successfully decoded as UTF-8')
        print(f'Length: {len(decoded)}')
    except Exception as e:
        print(f'UTF-8 decode failed: {e}')
        cleaned = content.replace(b'\x00', b'')
        print(f'Cleaned null bytes, new length: {len(cleaned)}')
        try:
            decoded = cleaned.decode('utf-8')
            print('Successfully decoded after cleaning')
            with open(r'C:\Users\admin\Desktop\Adithya\ticketing_host_new\lib\features\chat\presentation\pages\global_chat_page.dart', 'w', encoding='utf-8') as f:
                f.write(decoded)
            print('Wrote cleaned version back to original file')
        except Exception as e2:
            print(f'Cleaned decode also failed: {e2}')
