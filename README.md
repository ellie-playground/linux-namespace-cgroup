# 컨테이너의 격리 환경 동작 원리

<img width="711" height="274" alt="image" src="https://github.com/user-attachments/assets/3682b075-97ed-4fca-aa84-314bcb809b23" />

https://anweh.tistory.com/67

Docker는 Virtual Machine (VM)처럼 OS 레벨에서 격리하는 것이 아닌 프로세스 단위로 격리한다. 이러한 기술은 Docker 엔진에서 이루어지며, 리눅스 커널 기술인 namespace, cgroups를 기반으로 구성되어 있다.

Docker의 컨테이너 기술은 리눅스의 컨테이너를 활용한 기술로, 컴퓨터에 독립적인 컴퓨팅 공간을 만들어낸다. 이는 기존의 VM과 비교해 가상환경 구조에 차이가 있는데, VM은 환경 자체(OS)를 가상화해버리는 반면, **도커 컨테이너는 호스트 OS의 커널을 공유하며 단순히 하나의 격리되어 있는 프로세스로써 동작한다.**

컨테이너는 리눅스 커널의 namespace와 리눅스 컨트롤 그룹(cgroup)을 이용해 자원을 격리하고 제어한다. 컨테이너는 이 두 기능으로 단순한 이미지 실행 환경을 넘어 리눅스의 강력한 자원 격리와 제한 기능을 활용한다.

## Container는 가상머신인가?

Container는 hypervisor와 완전히 다르다. hypervisor는 OS 및 커널이 통째로 가상화되는 반면, container는 간단히 보면 filesystem의 가상화만을 이루고 있다. container는 호스트 PC의 커널을 공유하기 때문에 가상화 프로그램과는 다르게 적은 메모리 사용량, 적은 오버헤드를 보인다.

# namespace와 cgroup

<img width="1280" height="1078" alt="image" src="https://github.com/user-attachments/assets/b31a1506-2b2b-4951-bea4-e119a8b67367" />


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

<img width="941" height="678" alt="image" src="https://github.com/user-attachments/assets/5ec83e50-f757-4c29-98de-214eb4083570" />

https://csj000714.tistory.com/655

namespace는 nested process tree를 만들 수 있게 하는데, 이는 **각 프로세스가 시스템 리소스와 함께 고유하게 분리된 프로세스 트리를 가질 수 있음을 의미한다.** **분리된 process tree는 다른 process tree에서 확인하거나 삭제할 수 없다.**

모든 시스템은 부팅 시 PID 1 프로세스가 시작되고, 프로세스 트리 구조로 그 아래에 모든 프로세스들이 시작된다. 이때, PID namespace로 격리를 하게 되면, 하위 namespace의 프로세스가 상위 프로세스의 존재를 알 수 없게 된다. 

상위 namespace의 프로세스는 하위 namespace의 프로세스를 전체적으로 볼 수 있다. 그래서 같은 프로세스일지라도 부모 namespace에서 보면 PID 4321, 자식 namespace 안에서는 PID 1처럼 서로 다른 PID로 보일 수 있다.

## cgroups (Control Groups)

<img width="640" height="300" alt="image" src="https://github.com/user-attachments/assets/fc626203-03af-4aed-b25a-222bb852b3ba" />

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
ubuntu@ip-172-31-210-192:~$ lsns
        NS TYPE   NPROCS   PID USER   COMMAND
4026531834 time        2  1485 ubuntu -bash
4026531835 cgroup      2  1485 ubuntu -bash
4026531836 pid         2  1485 ubuntu -bash
4026531837 user        2  1485 ubuntu -bash
4026531838 uts         2  1485 ubuntu -bash
4026531839 ipc         2  1485 ubuntu -bash
4026531840 net         2  1485 ubuntu -bash
4026531841 mnt         2  1485 ubuntu -bash
```

- 리눅스에서 `lsns (List System namespace)` 명령어를 사용하면 현재 존재하는 namespace를 볼 수 있다.
- `lsns` 명령은 `/proc` 파일 시스템을 읽어 결과를 반환하는데, 일반 사용자가 실행한 결과와 루트 사용자가 실행한 결과가 다르다.

## unshare

- 별도의 namespace를 생성할 수 있다.
- 부모와 공유하지 않는 namespace 공간에 프로그램을 실행할 때 사용하는 명령어이다.
- 자식 프로세스가 `fork()`에 의해 생성되면서 부모 메모리 주소와는 별개의 가상 메모리 주소를 할당받는 Copy-on-Write 방식으로 설정을 상속받는다.

### Copy On Write

- 부모와 자식 프로세스가 서로 다른 가상 메모리 공간을 할당받지만, 같은 물리 메모리 공간을 참조한다.
- 자식 프로세스에서 변경 사항이 없는 경우 같은 물리 메모리 공간만을 사용한다.
- 자식 프로세스에서 값을 변경하게 되면, 수정이 발생한 내용만 별도의 물리 메모리 공간에 저장한다.
- 변경이 발생하지 않은 데이터는 부모와 같은 메모리 공간을 참고하고, 변경된 부분은 새로 할당받은 물리 메모리 공간을 참조한다.

# 참고 자료

- https://insight.infograb.net/blog/2025/04/09/linux-container/
- https://anweh.tistory.com/67
- https://dennis.k8s.kr/10
- https://tech.ssut.me/what-even-is-a-container/
- https://csj000714.tistory.com/655
- [https://wariua.github.io/man-pages-ko/unshare(2)/](https://wariua.github.io/man-pages-ko/unshare%282%29/)

# 참고 자료

- https://insight.infograb.net/blog/2025/04/09/linux-container/
- https://anweh.tistory.com/67
- https://dennis.k8s.kr/10
- https://tech.ssut.me/what-even-is-a-container/
- https://csj000714.tistory.com/655
