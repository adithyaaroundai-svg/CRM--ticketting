import os
import shutil

source = r'C:\Users\admin\Desktop\new123\ticketing_host_editted\lib\features\chat\presentation\pages\global_chat_page.dart'
target = r'C:\Users\admin\Desktop\Adithya\ticketing_host_new\lib\features\chat\presentation\pages\global_chat_page.dart'
backup = r'C:\Users\admin\Desktop\Adithya\ticketing_host_new\lib\features\chat\presentation\pages\global_chat_page_current_backup.dart'

# Backup current version
if os.path.exists(target):
    shutil.copy2(target, backup)
    print(f'Backed up current version to {backup}')

# Read UTF-16 source and convert to UTF-8
with open(source, 'rb') as f:
    raw = f.read()
    print(f'Source raw size: {len(raw)} bytes')

# Detect and decode
decoded = None
for enc in ['utf-16-le', 'utf-16-be', 'utf-8', 'utf-8-sig']:
    try:
        decoded = raw.decode(enc)
        print(f'Decoded source as {enc}, chars: {len(decoded)}')
        break
    except Exception as e:
        continue

if decoded is None:
    raise RuntimeError('Could not decode source file')

# Write as UTF-8
with open(target, 'w', encoding='utf-8') as f:
    f.write(decoded)

print(f'Restored feature-rich GlobalChatPage to {target}')
print(f'Final size: {os.path.getsize(target)} bytes')
