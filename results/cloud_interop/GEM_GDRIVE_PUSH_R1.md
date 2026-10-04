# Gemini Gem library -> Google Drive push r1
time=2026-10-04 18:30:53 +08:00
host=LAPTOP-R77M5D6M
remote=gdrive_jzthjyz:
drive_dir=Arena/Gem/goutoujunshi

gem_md_files_local=12
gem_txt_files_local=10
gem_expected_md=12 gem_expected_txt=10
gem_package_complete=True

rclone_present=True path=C:\Users\文少\AppData\Local\Programs\rclone\rclone.exe
rclone_version| rclone v1.75.1
rclone_version| - os/version: Microsoft Windows 11 Pro 25H2 25H2 (64 bit)
remote_about_ok=True
push_start=True dst=gdrive_jzthjyz:Arena/Gem/goutoujunshi
copy| rclone.exe : 2026/10/04 18:31:26 NOTICE: gdrive_jzthjyz: This remote uses rclone's shared Google Drive client_id, which
copy|  is being retired and will stop working during 2026. Create your own client_id to avoid interruption: https://rclone.or
copy| g/drive/#making-your-own-client-id
copy| ???? ?:2 ??: 5
copy| +     & $using:rclone copy $using:gemDir $using:dst --transfers 4 --che ...
copy| +     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
copy|     + CategoryInfo          : NotSpecified: (2026/10/04 18:3...r-own-client-id:String) [], RemoteException
copy|     + FullyQualifiedErrorId : NativeCommandError
copy_exit=0
check| g/drive/#making-your-own-client-id
check| ???? ?:2 ??: 5
check| +     & $using:rclone check $using:gemDir $using:dst --one-way 2>&1 | O ...
check| +     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
check|     + CategoryInfo          : NotSpecified: (2026/10/04 18:3...r-own-client-id:String) [], RemoteException
check|     + FullyQualifiedErrorId : NativeCommandError
check| 2026/10/04 18:32:26 NOTICE: Google drive root 'Arena/Gem/goutoujunshi': 0 differences found
check| 2026/10/04 18:32:26 NOTICE: Google drive root 'Arena/Gem/goutoujunshi': 24 matching files
check_exit=0
gem_files_remote=32
verify_ok=True

drive_folder=Arena/Gem/goutoujunshi
GDRIVE_GEM_PUSH_OK=True
