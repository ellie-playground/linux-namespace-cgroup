# sudo	PID namespace 생성은 루트 권한 필요 → 관리자 권한으로 실행
# unshare	현재 프로세스로부터 특정 namespace를 분리(unshare) 하여 새 namespace를 생성
# --pid	새로운 PID namespace 생성 (즉, 기존 PID 트리와 분리됨)
# --fork	새로운 PID namespace 안에서 자식 프로세스를 생성하여 실행 (안 쓰면 현재 쉘이 그대로 사용됨)
# -mount-proc	/proc을 새 namespace 기준으로 다시 마운트 → PID 정보가 격리됨
# ps aux	새로 만들어진 PID namespace 내부에서 프로세스 목록 출력
sudo unshare --pid --fork --mount-proc ps aux

# 새로운 UTS(Unix Timesharing System) 네임스페이스를 생성한 뒤, 그 안에서 bash 쉘을 실행하는 명령어 (uts 네임스페이스 접속)
# https://man7.org/linux/man-pages/man1/unshare.1.html
sudo unshare --uts bash