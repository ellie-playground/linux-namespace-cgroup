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

## cgroups (Control Groups)

<img width="640" height="300" alt="image" src="https://github.com/user-attachments/assets/fc626203-03af-4aed-b25a-222bb852b3ba" />

https://anweh.tistory.com/67

프로세스 그룹의 자원 사용을 제어하고 제한하는 핵심 커널 기능이다. 리눅스에서 프로그램은 프로세스로 실행되고, 프로세스는 하나 이상의 쓰레드로 이루어져 있다. cgroups는 프로세스와 쓰레드를 그룹화해서 관리하는 기술이다.

CPU, 메모리, 디스크 I/O 등 시스템 자원을 효율적으로 제한해 프로세스 그룹별로 격리할 수 있다. cgroups는 계층 구조를 기반으로, 부모 cgroup 아래에 여러 자식 cgroup을 생성해 각각 다른 자원 제한을 부여할 수 있다.

이 구조는 멀티 테넌트 환경에서 특정 프로세스의 자원 독점을 방지하고 컨테이너별 자원 할당의 안정성 보장에 도움이 된다. 즉, 컨테이너에서 사용하는 리소스를 제한함으로써 하나의 컨테이너가 자원을 모두 사용해 다른 컨테이너가 영향을 받지 않도록 할 수 있다.

# 참고 자료

- https://insight.infograb.net/blog/2025/04/09/linux-container/
- https://anweh.tistory.com/67
- https://dennis.k8s.kr/10
- https://tech.ssut.me/what-even-is-a-container/
- https://csj000714.tistory.com/655
