import codecs

with open(r'C:\Users\admin\Desktop\Adithya\ticketing_host_new\global_chat_page_original.dart', 'rb') as f:
    raw = f.read()
    print(f'Original length: {len(raw)}')
    print(f'First 20 bytes: {raw[:20]}')
    
    # Try different encodings
    for enc in ['utf-8', 'utf-16-le', 'utf-16-be', 'utf-8-sig', 'utf-16']:
        try:
            decoded = raw.decode(enc)
            print(f'\n✅ Successfully decoded with {enc}')
            print(f'Decoded length: {len(decoded)}')
            
            # Write as UTF-8
            with open(r'C:\Users\admin\Desktop\Adithya\ticketing_host_new\lib\features\chat\presentation\pages\global_chat_page.dart', 'w', encoding='utf-8') as f:
                f.write(decoded)
            print(f'Written as UTF-8 to global_chat_page.dart')
            break
        except Exception as e:
            print(f'\n❌ Failed with {enc}: {e}')
