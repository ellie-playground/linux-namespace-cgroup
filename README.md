# 컨테이너의 격리 환경 동작 원리

<img width="711" height="274" alt="image" src="https://github.com/user-attachments/assets/4ac67340-d845-470e-af0f-ca73ede5eafd" />

https://anweh.tistory.com/67

Docker는 Virtual Machine (VM)처럼 OS 레벨에서 격리하는 것이 아닌 프로세스 단위로 격리한다. 이러한 기술은 Docker 엔진에서 이루어지며, 리눅스 커널 기술인 namespace, cgroups를 기반으로 구성되어 있다.

Docker의 컨테이너 기술은 리눅스의 컨테이너를 활용한 기술로, 컴퓨터에 독립적인 컴퓨팅 공간을 만들어낸다. 이는 기존의 VM과 비교해 가상환경 구조에 차이가 있는데, VM은 환경 자체(OS)를 가상화해버리는 반면, **도커 컨테이너는 호스트 OS의 커널을 공유하며 단순히 하나의 격리되어 있는 프로세스로써 동작한다.**

컨테이너는 리눅스 커널의 namespace와 리눅스 컨트롤 그룹(cgroup)을 이용해 자원을 격리하고 제어한다. 컨테이너는 이 두 기능으로 단순한 이미지 실행 환경을 넘어 리눅스의 강력한 자원 격리와 제한 기능을 활용한다.

## Container는 가상머신인가?

Container는 hypervisor와 완전히 다르다. hypervisor는 OS 및 커널이 통째로 가상화되는 반면, container는 간단히 보면 filesystem의 가상화만을 이루고 있다. container는 호스트 PC의 커널을 공유하기 때문에 가상화 프로그램과는 다르게 적은 메모리 사용량, 적은 오버헤드를 보인다.

# namespace와 cgroup

<img width="1280" height="1078" alt="image" src="https://github.com/user-attachments/assets/060d4682-d572-474b-b37e-f342dd8a920c" />


## namespace

VM은 각 게스트 머신별로 독립적인 공간을 제공하고 서로 충돌하지 않도록 하는 기능을 갖고 있다. 리눅스에서는 이와 동일한 역할을 하는 namespace 기능을 커널에 내장하고 있다.

리눅스 커널의 namespace는 **커널 자원을 분할해 프로세스마다 격리된 시스템 환경을 제공하는 커널 기능**이다. 예를 들어, 하나의 건물 안에 여러 개의 독립된 방이 있는 것처럼, **네임스페이스로 컨테이너 내부의 프로세스가 호스트 시스템이나 다른 컨테이너 자원에 접근하지 못하도록 논리적 경계를 설정한다.**

하나의 system에서 수행되지만, 각각 별개의 독립된 공간처럼 격리된 환경을 제공하는 lightweight 가상화 기술이다. VM에서는 각 게스트 별로 독립적인 공간을 제공하고 충돌하지 않도록 Hardware Resource 자체를 가상화하지만, namespace의 경우 동일한 os, kernel에서 Linux 내의 자원을 가상화한다.

### 주요 네임스페이스 종류

리눅스 커널은 다양한 네임스페이스를 제공하며, 각각 특정 자원을 격리한다. 컨테이너 기술에서 주로 사용하는 네임스페이스는 다음과 같다.

- 마운트(mnt): 독립적인 파일 시스템 환경을 위한 마운트 지점 격리
- 프로세스 ID(pid): 컨테이너 내부의 프로세스를 독립적으로 관리하기 위한 pid 공간 분리
- 네트워크(net): IP 주소와 포트 등 독립적인 네트워크 스택 제공
- IPC: 프로세스 간 통신(IPC) 자원의 격리
- UTS: 호스트 이름과 도메인 이름의 격리
- 사용자(user): 사용자와 그룹 ID의 격리, 호스트 시스템에서 root 권한 제한
- cgroup: 자원 제어 그룹 계층 구조 격리
- 타임(time): 시스템 시간을 독립적으로 설정하도록 지원

### namespace isolation

<img width="941" height="678" alt="image" src="https://github.com/user-attachments/assets/b4186e6a-11cb-48f4-ad85-b78bf0fc4efd" />


https://csj000714.tistory.com/655

namespace는 nested process tree를 만들 수 있게 하는데, 이는 **각 프로세스가 시스템 리소스와 함께 고유하게 분리된 프로세스 트리를 가질 수 있음을 의미한다.** **분리된 process tree는 다른 process tree에서 확인하거나 삭제할 수 없다.**

모든 시스템은 부팅 시 PID 1 프로세스가 시작되고, 프로세스 트리 구조로 그 아래에 모든 프로세스들이 시작된다. 이때, PID namespace로 격리를 하게 되면, 하위 namespace의 프로세스가 상위 프로세스의 존재를 알 수 없게 된다. 

상위 namespace의 프로세스는 하위 namespace의 프로세스를 전체적으로 볼 수 있다. 그래서 같은 프로세스일지라도 부모 namespace에서 보면 PID 4321, 자식 namespace 안에서는 PID 1처럼 서로 다른 PID로 보일 수 있다.

## cgroups (Control Groups)

<img width="640" height="300" alt="image" src="https://github.com/user-attachments/assets/bcabb98d-a473-4c43-bfe0-63323f7faab4" />

https://anweh.tistory.com/67

프로세스 그룹의 자원 사용을 제어하고 제한하는 핵심 커널 기능이다. 리눅스에서 프로그램은 프로세스로 실행되고, 프로세스는 하나 이상의 쓰레드로 이루어져 있다. cgroups는 프로세스와 쓰레드를 그룹화해서 관리하는 기술이다.

CPU, 메모리, 디스크 I/O 등 시스템 자원을 효율적으로 제한해 프로세스 그룹별로 격리할 수 있다. cgroups는 계층 구조를 기반으로, 부모 cgroup 아래에 여러 자식 cgroup을 생성해 각각 다른 자원 제한을 부여할 수 있다.

이 구조는 멀티 테넌트 환경에서 특정 프로세스의 자원 독점을 방지하고 컨테이너별 자원 할당의 안정성 보장에 도움이 된다. 즉, 컨테이너에서 사용하는 리소스를 제한함으로써 하나의 컨테이너가 자원을 모두 사용해 다른 컨테이너가 영향을 받지 않도록 할 수 있다.

## 네트워크 네임스페이스와 가상 이더넷(veth)

네트워크 네임스페이스는 각 컨테이너에 독립적인 네트워크 환경을 제공하는 핵심 기능이다. 각 네임스페이스는 자체 네트워크 인터페이스, IP주소, 라우팅 테이블, 방화벽 규칙이 있다. 이 떄문에 여러 컨테이너가 한 호스트 위에서 동시에 동작해도 서로 네트워크 설정에 간섭받지 않는다.

가상 이더넷(veth: virtual ethernet) 쌍은 네임스페이스 간 통신을 구성할 때 사용된다. veth는 두 개의 가상 네트워크 인터페이스로, 한쪽에서 전송한 패킷이 곧바로 다른쪽에 수신된다. 이를 이용하면 한쪽 인터페이스를 컨테이너의 네트워크 네임스페이스에, 다른쪽을 호스트나 다른 컨테이너 네임스페이스에 연결해 컨테이너와 호스트 간 또는 컨테이너 간에 네트워크 통신을 설정할 수 있다.

# namespace와 cgroup 실습해보기

## 현재 존재하는 namespace 살펴보기

```bash
ubuntu@ip-172-31-84-252:~$ lsns
        NS TYPE   NPROCS   PID USER   COMMAND
4026531834 time        2  1417 ubuntu -bash
4026531835 cgroup      2  1417 ubuntu -bash
4026531836 pid         2  1417 ubuntu -bash
4026531837 user        2  1417 ubuntu -bash
4026531838 uts         2  1417 ubuntu -bash
4026531839 ipc         2  1417 ubuntu -bash
4026531840 net         2  1417 ubuntu -bash
4026531841 mnt         2  1417 ubuntu -bash
```

```java
ubuntu@ip-172-31-84-252:~$ sudo lsns
        NS TYPE   NPROCS   PID USER            COMMAND
4026531834 time      113     1 root            /sbin/init
4026531835 cgroup    113     1 root            /sbin/init
4026531836 pid       113     1 root            /sbin/init
4026531837 user      113     1 root            /sbin/init
4026531838 uts       107     1 root            /sbin/init
4026531839 ipc       113     1 root            /sbin/init
4026531840 net       113     1 root            /sbin/init
4026531841 mnt       104     1 root            /sbin/init
4026532224 mnt         1   198 root            ├─/usr/lib/systemd/systemd-udevd
4026532225 uts         1   198 root            ├─/usr/lib/systemd/systemd-udevd
4026532236 mnt         1   323 systemd-resolve ├─/usr/lib/systemd/systemd-resolved
4026532239 mnt         1   512 systemd-network ├─/usr/lib/systemd/systemd-networkd
4026532240 uts         1   692 syslog          ├─/usr/sbin/rsyslogd -n -iNONE
4026532241 mnt         2   780 _chrony         ├─/usr/sbin/chronyd -F 1
4026532242 mnt         1   588 polkitd         ├─/usr/lib/polkit-1/polkitd --no-debug
4026532243 uts         2   780 _chrony         ├─/usr/sbin/chronyd -F 1
4026532244 uts         1   588 polkitd         ├─/usr/lib/polkit-1/polkitd --no-debug
4026532298 mnt         1   632 root            ├─/usr/lib/systemd/systemd-logind
4026532299 uts         1   632 root            ├─/usr/lib/systemd/systemd-logind
4026532305 mnt         1   855 root            └─/usr/sbin/ModemManager
4026531862 mnt         1    23 root            kdevtmpfs
```

- 리눅스에서 `lsns (List System namespace)` 명령어를 사용하면 현재 존재하는 namespace를 볼 수 있다.
- `lsns` 명령은 `/proc` 파일 시스템을 읽어 결과를 반환하는데, 일반 사용자가 실행한 결과와 루트 사용자가 실행한 결과가 다르다.
    - 일반 사용자는 `/proc/{pid}` 중 자신이 소유한 프로세스만 볼 수 있고, root 사용자는 모든 프로세스의 `/proc/{pid}`를 볼 수 있기 때문이다.

## unshare

`unshare` 명령어를 사용하면 별도의 namespace를 생성할 수 있다. **`unshare` 명령은 부모와 공유하지 않는 namespace 공간에 프로그램을 실행할 때 사용하는 명령어다.** 자식 프로세스가 `fork()` 에 의해 생성되면서 부모 메모리 주소와는 별개의 가상 메모리 주소를 할당받는 copy-on-write 방식으로 설정을 상속받는다.

### Copy On Write

- 부모와 자식 프로세스가 서로 다른 가상 메모리 공간을 할당받지만, 같은 물리 메모리 공간을 참조한다.
- 자식 프로세스에서 변경 사항이 없는 경우 같은 물리 메모리 공간만을 사용한다.
- 자식 프로세스에서 값을 변경하게 되면, 수정이 발생한 내용만 별도의 물리 메모리 공간에 저장한다.
- 변경이 발생하지 않은 데이터는 부모와 같은 메모리 공간을 참고하고, 변경된 부분은 새로 할당받은 물리 메모리 공간을 참조한다.

## uts namespace 격리

**Unix Timesharing System (UTS) Namespace는 유닉스 시분할 시스템으로, 시스템의 호스트 이름과 도메인을 분리해주는 공간이다.** 프로세스를 추가로 생성한 후, uts namespace에 할당한 다음 호스트 이름을 변경하면, 새로 격리된 namespace 안에 적용되기 때문에 호스트 단말기의 호스트 이름은 변하지 않는다.

1. 호스트 단말기의 hostname 확인
    
    ```java
    ubuntu@ip-172-31-84-252:~$ hostname
    ip-172-31-84-252
    ```
    
2. uts namespace 생성 후 bash shell 실행
    
    ```java
    ubuntu@ip-172-31-84-252:~$ sudo unshare --uts bash
    root@ip-172-31-84-252:/home/ubuntu# hostname
    ip-172-31-84-252
    ```
    
    - 새로운 uts namespace를 생성한 후, 그 안에서 bash shell을 실행하면 현재 시스템과 분리된 새로운 hostname 공간을 가진 Bash shell을 실행한다.
3. hostname 변경
    
    ```java
    root@ip-172-31-84-252:/home/ubuntu# hostname new
    root@ip-172-31-84-252:/home/ubuntu# hostname
    new
    ```
    
4. 리눅스 터미널 추가 후 namespace 확인
    
    ```java
    root@ip-172-31-84-252:/home/ubuntu# sudo lsns -t uts
    sudo: unable to resolve host new: Temporary failure in name resolution
            NS TYPE NPROCS   PID USER    COMMAND
    4026531838 uts     100     1 root    /sbin/init
    4026532225 uts       1   198 root    ├─/usr/lib/systemd/systemd-udevd
    4026532240 uts       1   692 syslog  ├─/usr/sbin/rsyslogd -n -iNONE
    4026532243 uts       2   780 _chrony ├─/usr/sbin/chronyd -F 1
    4026532244 uts       1   588 polkitd ├─/usr/lib/polkit-1/polkitd --no-debug
    4026532299 uts       1   632 root    └─/usr/lib/systemd/systemd-logind
    4026532245 uts       4  1485 root    bash
    ```
    
5. bash shell 종료 후 hostname 확인
    
    ```java
    root@ip-172-31-84-252:/home/ubuntu# exit
    exit
    ubuntu@ip-172-31-84-252:~$ hostname
    ip-172-31-84-252
    ```
    

## pid namespace 격리

process id도 별도의 namespace를 생성하면 호스트 단말기에서 사용중인 다른 프로세스들과 격리되어 구성된다.

- PID (Process ID)는 운영체제가 각 프로세스를 고유하게 식별하기 위해 부여하는 숫자 ID이다. 프로세스가 시작될 때 운영체제에 의해 자동으로 할당되며, 프로세스가 종료되면 해당 PID는 재사용될 수 있다.
    
    ```bash
    # 실행중인 프로세스들을 트리 형태로 보여준다.
    # 루트 프로세스에 위치한 systemd가 바로 PID 1번의 init 시스템이다.
    ubuntu@ip-172-31-84-252:~$ pstree
    systemd─┬─ModemManager───3*[{ModemManager}]
            ├─acpid
            ├─2*[agetty]
            ├─amazon-ssm-agen───6*[{amazon-ssm-agen}]
            ├─chronyd───chronyd
            ├─cron
            ├─dbus-daemon
            ├─multipathd───6*[{multipathd}]
            ├─networkd-dispat
            ├─polkitd───3*[{polkitd}]
            ├─rsyslogd───3*[{rsyslogd}]
            ├─snapd───9*[{snapd}]
            ├─sshd───sshd───sshd───bash───pstree
            ├─systemd───(sd-pam)
            ├─systemd-journal
            ├─systemd-logind
            ├─systemd-network
            ├─systemd-resolve
            ├─systemd-udevd
            ├─udisksd───5*[{udisksd}]
            └─unattended-upgr───{unattended-upgr}
    ```
    
1. pid namespace 생성
    
    ```java
    ubuntu@ip-172-31-84-252:~$ sudo unshare --pid --fork bash
    root@ip-172-31-84-252:/home/ubuntu# 
    ```
    
2. namespace 확인
    
    ```java
    root@ip-172-31-84-252:/home/ubuntu# sudo lsns -t pid
            NS TYPE NPROCS   PID USER COMMAND
    4026531836 pid     108     1 root /sbin/init
    4026532245 pid       4  1519 root bash
    ```
    
3. namespace 내부의 프로세스 목록 조회
    
    ```java
    root@ip-172-31-84-252:/home/ubuntu# ps -aux
    fatal library error, lookup self
    ```
    
    - 실행 시 오류가 발생하는데, pid namespace를 분리했지만, `/proc` 을 새 네임스페이스에 마운트하지 않았기 때문에 발생한 오류이다.
    - `sudo unshare --pid --fork bash` 만 실행할 경우, pid namespace는 분리되지만, `/proc` 은 여전히 부모 네임스페이스의 `/proc` 을 바라보고 있다.
4. `chroot` 테스트용 신규 루트 디렉토리 생성
    
    ```java
    root@ip-172-31-84-252:/home/ubuntu# mkdir new_root_directory
    root@ip-172-31-84-252:/home/ubuntu# cd new_root_directory/
    ```
    
    - `chroot` 는 change root directory의 줄임말로, 리눅스는 `chroot` 시스템 콜을 통해 **프로세스의 루트 디렉터리를 변경할 수 있다. 이를 활용하면 특정 디렉터리를 루트(/)처럼 인식하게 만들 수 있으며, 컨테이너는 이러한 기능을 통해 자신만의 파일 시스템 루트를 가지게 된다.**
5. 리눅스 파일 시스템 구성
    
    ```java
    root@ip-172-31-84-252:/home/ubuntu/new_root_directory# ls
    alpine.tar.gz  dev  home  media  opt   root  sbin  sys  usr
    bin            etc  lib   mnt    proc  run   srv   tmp  var
    ```
    
6. pid namespace 생성 및 chroot 적용
    
    ```java
    root@ip-172-31-84-252:/home/ubuntu/new_root_directory# sudo unshare --pid --fork chroot ./new_root_directory sh
    chroot: cannot change root directory to './new_root_directory': No such file or directory
    root@ip-172-31-84-252:/home/ubuntu/new_root_directory# cd ..
    root@ip-172-31-84-252:/home/ubuntu# sudo unshare --pid --fork chroot ./new_root_directory sh
    / # ls
    alpine.tar.gz  home           opt            sbin           usr
    bin            lib            proc           srv            var
    dev            media          root           sys
    etc            mnt            run            tmp
    / # ps
    PID   USER     TIME  COMMAND
    / # ls proc
    ```
    
    - 최초 chroot 적용 후 프로세스 목록을 조회하면, `/proc` 폴더가 비어있기 때문에 아무것도 조회되지 않는다.
    - 커널이 해당 디렉터리에 프로세스 정보를 채우게 하려면 proc 타입의 파일 시스템을 mount 해줘야 한다.
7. proc 타입 파일 시스템 마운트 후 프로세스 목록 조회
    
    ```java
    / # mount -t proc proc proc
    / # ls proc
    1                  fb                 locks              swaps
    6                  filesystems        mdstat             sys
    acpi               fs                 meminfo            sysrq-trigger
    bootconfig         interrupts         misc               sysvipc
    buddyinfo          iomem              modules            thread-self
    bus                ioports            mounts             timer_list
    cgroups            irq                mtrr               tty
    cmdline            kallsyms           net                uptime
    consoles           kcore              pagetypeinfo       version
    cpuinfo            key-users          partitions         version_signature
    crypto             keys               pressure           vmallocinfo
    devices            kmsg               schedstat          vmstat
    diskstats          kpagecgroup        scsi               xen
    dma                kpagecount         self               zoneinfo
    driver             kpageflags         slabinfo
    dynamic_debug      latency_stats      softirqs
    execdomains        loadavg            stat
    / # ps
    PID   USER     TIME  COMMAND
        1 root      0:00 sh
        7 root      0:00 ps
    ```

## NET namespace 격리

NET namespace는 **컨테이너가 고유한 네트워크 인터페이스, IP 주소, 라우팅 테이블, 포트 등 네트워크 스택 전반을 독립적으로 소유하도록 하여, 네트워크 자원 측면에서의 완전한 격리를 제공**한다. 이를 통해 하나의 물리 서버에서 여러 컨테이너가 각각 자신만의 가상 네트워크 환경을 구성하고, 다른 컨테이너나 호스트와 충돌 없이 통신하거나 완전히 차단된 상태로 동작할 수 있다.

### Network Interface

네트워크 인터페이스는 컴퓨터 시스템이 외부 네트워크와 통신하기 위해 사용하는 가상의 통신 창구 또는 장치를 의미한다. 쉽게 말해, 운영체제 안에서 네트워크를 통해 데이터를 주고받는 입출력 통로라고 할 수 있다.

리눅스와 같은 운영체제에서는 eth0, lo 등과 같은 이름으로 네트워크 인터페이스가 표현되며, 각각의 인터페이스는 MAC 주소, IP 주소, MTU(최대 전송 단위) 등의 속성을 가지고 있다. 이러한 속성들은 해당 인터페이스가 데이터를 어떻게 송수신 할 지를 결정하는 중요한 기준이 된다.

**인터페이스 정보 확인하기**

```bash
ubuntu@ip-172-31-84-252:~$ ip link
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: enX0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9001 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
    link/ether 02:70:14:39:a2:29 brd ff:ff:ff:ff:ff:ff
3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN mode DEFAULT group default 
    link/ether ba:1b:b2:51:ec:ee brd ff:ff:ff:ff:ff:ff
```

### NET namespace 실습하기

1. veth 생성
    
    ```bash
    ubuntu@ip-172-31-84-252:~$ sudo ip link add veth0 type veth peer name veth1
    ubuntu@ip-172-31-84-252:~$ ip -br link
    lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
    enX0             UP             02:70:14:39:a2:29 <BROADCAST,MULTICAST,UP,LOWER_UP> 
    docker0          DOWN           ba:1b:b2:51:ec:ee <NO-CARRIER,BROADCAST,MULTICAST,UP> 
    veth1@veth0      DOWN           8a:4f:ea:80:26:82 <BROADCAST,MULTICAST,M-DOWN> 
    veth0@veth1      DOWN           06:8e:bc:d0:28:67 <BROADCAST,MULTICAST,M-DOWN> 
    ```
    
    리눅스에서는 가상의 인터페이스를 veth(Virtual Ethernet Device) 라고 부르며, ip 명령어로 생성할 수 있다. veth는 항상 쌍(pair)으로 만들어진다.

# 참고 자료

- https://insight.infograb.net/blog/2025/04/09/linux-container/
- https://anweh.tistory.com/67
- https://dennis.k8s.kr/10
- https://tech.ssut.me/what-even-is-a-container/
- https://csj000714.tistory.com/655
- https://man7.org/linux/man-pages/man1/unshare.1.html
- https://engineer-diarybook.tistory.com/entry/Linux-namespace
