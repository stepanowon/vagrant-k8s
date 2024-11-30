# 로컬 머신에 멀티노드 k8s 클러스터 만들기

[VirtualBox](https://www.virtualbox.org/)와 [Vagrant](https://www.vagrantup.com/) 최신 버전을 여러개의 VM을 실행할 수 있는 충분한 메모리를 가진 로컬 컴퓨터에 설치합니다. 

## vagrant을 이용해서 VM을 설치
```sh
# github repo에서 vagrantfile을 내려받아 설치
git clone https://github.com/stepanowon/k8s-multi-node-vagrant
cd k8s-multi-node-vagrant
vagrant up

# 설치가 완료된 후 reload
vagrant reload

# vagrant 사용자 초기 패스워드 : asdf 
```

## Control Plane 역할의 VM(마스터) 초기화
```sh
vagrant ssh master
# 만일 별도의 ssh 터미널로 접속하고 싶다면 다음 명령어로 vagrant 계정의 패스워드를 설정한다.
# sudo passwd vagrant
```
```sh
sudo kubeadm init --apiserver-advertise-address=192.168.56.201 --pod-network-cidr=10.244.0.0/16
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
# kubectl 도구가 설치된 다른 컴퓨터를 이용하고 싶다면 ~/.kube/config 파일을 복사하여 사용함
```
#### [Calico](https://projectcalico.docs.tigera.io/getting-started/kubernetes/quickstart) CNI 플러그인을 설치함. 

```sh
## calico CNI 설치
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/tigera-operator.yaml
kubectl create -f /vagrant/conf/custom-resources.yaml

## 설치 확인
vagrant@master:~$ kubectl get pods --all-namespaces
NAMESPACE          NAME                                       READY   STATUS    RESTARTS   AGE
calico-apiserver   calico-apiserver-8557fd65f-h5799           1/1     Running   0          57s
calico-apiserver   calico-apiserver-8557fd65f-p6mw4           1/1     Running   0          57s
calico-system      calico-kube-controllers-56fccc4788-7fjg9   1/1     Running   0          2m32s
calico-system      calico-node-xpkbv                          1/1     Running   0          2m33s
calico-system      calico-typha-74f5bfd6f7-z2pg5              1/1     Running   0          2m33s
calico-system      csi-node-driver-w24hd                      2/2     Running   0          2m33s
kube-system        coredns-55cb58b774-6ccdl                   1/1     Running   0          3m56s
kube-system        coredns-55cb58b774-dv58v                   1/1     Running   0          3m56s
kube-system        etcd-master                                1/1     Running   1          4m8s
kube-system        kube-apiserver-master                      1/1     Running   1          4m8s
kube-system        kube-controller-manager-master             1/1     Running   1          4m12s
kube-system        kube-proxy-ddj99                           1/1     Running   0          3m56s
kube-system        kube-scheduler-master                      1/1     Running   1          4m12s
tigera-operator    tigera-operator-576646c5b6-6h5t5           1/1     Running   0          2m46s
```

## 작업자 노드 추가(worker1과 worker2에서 수행)

```sh
vagrant ssh worker1
```
```sh
# 마스터에서 kubeadm init 명령어 수행후 콘솔에 출력된 join 명령어를 실행함. 형식은 다음과 같음
$ sudo kubeadm join 192.168.56.201:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>

# 만일 token과 hash 값을 알수 없다면 다음 명령어 실행하여 확인
# kubeadm token list
# kubeadm token create --print-join-command

```
#### worker2 노드에서도 동일하게 수행
#### 로컬 컴퓨터에 3노드 k8s 클러스터 구성 완료 확인
```sh
$ vagrant ssh control-plane
```
```sh
vagrant@master:~$ kubectl get nodes -o wide
NAME      STATUS   ROLES           AGE   VERSION   INTERNAL-IP      EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION   CONTAINER-RUNTIME
master    Ready    control-plane   24m   v1.30.7   192.168.56.201   <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-28-amd64   containerd://1.6.36
worker1   Ready    <none>          13m   v1.30.7   192.168.56.202   <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-28-amd64   containerd://1.6.36
worker2   Ready    <none>          12m   v1.30.7   192.168.56.203   <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-28-amd64   containerd://1.6.36
```

```sh
$ kubectl cluster-info
Kubernetes control plane is running at https://192.168.56.201:6443
CoreDNS is running at https://192.168.56.201:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

```sh
$ kubectl get all --all-namespaces
NAMESPACE          NAME                                           READY   STATUS    RESTARTS   AGE
calico-apiserver   pod/calico-apiserver-58588ff69-2784s           1/1     Running   0          5m44s
calico-apiserver   pod/calico-apiserver-58588ff69-4bst5           1/1     Running   0          5m44s
calico-system      pod/calico-kube-controllers-6b5fc6786d-zn6hm   1/1     Running   0          8m15s
calico-system      pod/calico-node-2hhws                          1/1     Running   0          8m15s
calico-system      pod/calico-node-c74cq                          1/1     Running   0          7m44s
calico-system      pod/calico-node-cznvd                          1/1     Running   0          7m12s
calico-system      pod/calico-typha-6db85d4766-jpdn8              1/1     Running   0          8m15s
calico-system      pod/calico-typha-6db85d4766-wr8fx              1/1     Running   0          7m10s
calico-system      pod/csi-node-driver-4r5sw                      2/2     Running   0          8m15s
calico-system      pod/csi-node-driver-lglh6                      2/2     Running   0          7m44s
calico-system      pod/csi-node-driver-mczqr                      2/2     Running   0          7m12s
kube-system        pod/coredns-55cb58b774-6t8fg                   1/1     Running   0          9m53s
kube-system        pod/coredns-55cb58b774-m4xlx                   1/1     Running   0          9m53s
kube-system        pod/etcd-control-plane                         1/1     Running   0          10m
kube-system        pod/kube-apiserver-control-plane               1/1     Running   0          10m
kube-system        pod/kube-controller-manager-control-plane      1/1     Running   0          10m
kube-system        pod/kube-proxy-fl7x7                           1/1     Running   0          7m44s
kube-system        pod/kube-proxy-j5b7p                           1/1     Running   0          7m12s
kube-system        pod/kube-proxy-tvzg4                           1/1     Running   0          9m54s
kube-system        pod/kube-scheduler-control-plane               1/1     Running   0          10m
tigera-operator    pod/tigera-operator-576646c5b6-8thq6           1/1     Running   0          9m19s

NAMESPACE          NAME                                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                  AGE
calico-apiserver   service/calico-api                        ClusterIP   10.96.212.147    <none>        443/TCP                  5m44s
calico-system      service/calico-kube-controllers-metrics   ClusterIP   None             <none>        9094/TCP                 7m9s
calico-system      service/calico-typha                      ClusterIP   10.110.126.136   <none>        5473/TCP                 8m15s
default            service/kubernetes                        ClusterIP   10.96.0.1        <none>        443/TCP                  10m
kube-system        service/kube-dns                          ClusterIP   10.96.0.10       <none>        53/UDP,53/TCP,9153/TCP   10m

NAMESPACE       NAME                             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
calico-system   daemonset.apps/calico-node       3         3         3       3            3           kubernetes.io/os=linux   8m15s
calico-system   daemonset.apps/csi-node-driver   3         3         3       3            3           kubernetes.io/os=linux   8m15s
kube-system     daemonset.apps/kube-proxy        3         3         3       3            3           kubernetes.io/os=linux   10m

NAMESPACE          NAME                                      READY   UP-TO-DATE   AVAILABLE   AGE
calico-apiserver   deployment.apps/calico-apiserver          2/2     2            2           5m44s
calico-system      deployment.apps/calico-kube-controllers   1/1     1            1           8m15s
calico-system      deployment.apps/calico-typha              2/2     2            2           8m15s
kube-system        deployment.apps/coredns                   2/2     2            2           10m
tigera-operator    deployment.apps/tigera-operator           1/1     1            1           9m19s

NAMESPACE          NAME                                                 DESIRED   CURRENT   READY   AGE
calico-apiserver   replicaset.apps/calico-apiserver-58588ff69           2         2         2       5m44s
calico-system      replicaset.apps/calico-kube-controllers-6b5fc6786d   1         1         1       8m15s
calico-system      replicaset.apps/calico-typha-6db85d4766              2         2         2       8m15s
kube-system        replicaset.apps/coredns-55cb58b774                   2         2         2       9m53s
tigera-operator    replicaset.apps/tigera-operator-576646c5b6           1         1         1       9m19s
```

## Ingress NGINX controller

[https://kubernetes.github.io/ingress-nginx/deploy/baremetal/#via-the-host-network](https://kubernetes.github.io/ingress-nginx/deploy/baremetal/#via-the-host-network).

```sh
$ vagrant ssh master
```
```sh
# worker1 노드를 엣지 노드로 사용함
kubectl label node worker1 node-role.kubernetes.io/edge=""
kubectl label node worker1 node-role.kubernetes.io/node=""
kubectl label node worker2 node-role.kubernetes.io/node=""

$ kubectl get node
NAME            STATUS   ROLES           AGE   VERSION
master          Ready    control-plane   22m   v1.30.5
worker1         Ready    edge,node       19m   v1.30.5
worker2         Ready    node            19m   v1.30.5

# ingress-nginx-controller 설치
$ kubectl create -f /vagrant/conf/ingress-nginx-controller.yaml
$ kubectl -n ingress-nginx get all
NAME                                       READY   STATUS      RESTARTS   AGE
pod/ingress-nginx-admission-create-ngqwv   0/1     Completed   0          16s
pod/ingress-nginx-admission-patch-zql4n    0/1     Completed   1          16s
pod/ingress-nginx-controller-np625         1/1     Running     0          16s

NAME                                         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/ingress-nginx-controller-admission   ClusterIP   10.108.228.71   <none>        443/TCP   16s

NAME                                      DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                                          AGE
daemonset.apps/ingress-nginx-controller   1         1         1       1            1           kubernetes.io/os=linux,node-role.kubernetes.io/edge=   16s

NAME                                       STATUS     COMPLETIONS   DURATION   AGE
job.batch/ingress-nginx-admission-create   Complete   1/1           4s         16s
job.batch/ingress-nginx-admission-patch    Complete   1/1           4s         16s
```
#### worker1 노드(엣지노드)에서 방화벽 설정
```sh
$ vagrant ssh worker1
```
```sh
$ sudo ufw allow http
$ sudo ufw allow https
```

## Example application deployment

```sh
$ vagrant ssh master
```
```sh
# /path1/* 패턴의 경로의 요청을 처리할 deployment와 service
$ kubectl create -f /vagrant/conf/nodeapp1.yaml
# /path2/* 패턴의 경로의 요청을 처리할 deployment와 service
$ kubectl create -f /vagrant/conf/nodeapp2.yaml
# ingress 설치
$ kubectl create -f /vagrant/conf/nodeapp-ingress.yaml

$ kubectl get all
$ kubectl get ingress
NAME              CLASS    HOSTS   ADDRESS         PORTS   AGE
example-ingress   <none>   *       192.168.56.202   80      67s
```
#### /path1/* , /path2/* 경로로 각각 요청해보기
```sh
$ curl -s http://192.168.56.202/path1/abc
$ curl -s http://192.168.56.202/path2/abc
```

