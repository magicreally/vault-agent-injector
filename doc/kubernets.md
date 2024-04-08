[Back](../README.md)

To Strat, stop and delete minikube 

 ```bash
minikube start 

minikube stop 
minikube delete  
 ```
 
to run minikube in a special virtual environmet you should run command below 

 ```bash
minikube start –vm-driver=docker 
```
To get status of nodes  

 ```bash
$ kubectl get nodes 
```
NAME STATUS ROLES AGE VERSION 

minikube Ready control-plane 6d17h v1.27.4 
  
to get status of minikube  
 
 
 ```bash
$ minikube status 
```
minikube 
 ```console
type: Control Plane 

host: Running 

kubelet: Running 

apiserver: Running 

kubeconfig: Configured 
```
 
to check verson of minikube 
  
 
```bash
$ kubectl version 
```
```console
Client Version: v1.28.3 

Kustomize Version: v5.0.4-0.20230601165947-6ce0bf390ce3 

Server Version: v1.27.4 
```
basic kubectl command 
 Pod is the smallest unit 
  ```bash 
$ kubectl get pod 
``` 
```bash
$ kubectl get services 
```
NAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE 

kubernetes ClusterIP 10.96.0.1 <none> 443/TCP 6d17h 
  
 

to create a new one kubernates component
```bash 
$ kubectl create
```
Available Commands: 

```console 
Cluster role Create a cluster role 

clusterrolebinding Create a cluster role binding for a particular cluster role 

configmap Create a config map from a local file, directory or literal value 

cronjob Create a cron job with the specified name 

deployment Create a deployment with the specified name 

ingress Create an ingress with the specified name 

job Create a job with the specified name 

namespace Create a namespace with the specified name 

poddisruptionbudget Create a pod disruption budget with the specified name 

priorityclass Create a priority class with the specified name 

quota Create a quota with the specified name 

role Create a role with single rule 

rolebinding Create a role binding for a particular role or cluster role 

secret Create a secret using a specified subcommand 

service Create a service using a specified subcommand 

serviceaccount Create a service account with the specified name 

token Request a service account token 

```
for exmple for creating deployment run command below 

```bash 
$ kubectl create deloyment NAME –image=image [--dry-run] [options] 
```

NAME: name of deployment 

image: is required because pod need to be created based on some image or some container image (you should download image in docket hub) 
 
```bash
 $ kubectl create deployment nginx-depl –image=nginx 
 ```

if you want to create more than one replicas  
 
```bash
$kubectl create deployment nginx-depl2 --image=nginx --replicas=5  
 ```

to get information about deployment  
 
```bash
$ kubectl get deployment 
```
```console
#NAME READY UP-TO-DATE AVAILABLE AGE 

nginx-depl 0/1 1 0 93s 
```
 as you can see there is a deployment, but it is not ready. 
 Pod is an abstraction of a container and everything deployment should be managed by Kubernetes and you should be worried about any of it and to see the pod  
```bash
$ kubectl get pod 
```
NAME READY STATUS RESTARTS AGE 

nginx-depl-6b7698588c-nptz6 0/1 ImagePullBackOff 0 3m24s 
 as you can see after creating the deployment now, we have a pod that it consist of a prefix of deployment and some random hash and it says the container is created but it is not ready and need to time to be run (statues from ImagePullBackOff should be changed to running) 

In Kubernetes, a replica refers to a set of identical instances of a Pod. Pods are the smallest deployable units in Kubernetes, and they can contain one or more containers. Replicas are used to ensure that a specified number of Pod instances, often called "replicas," are running and maintained at all times. 

The most common resource used to create and manage replicas in Kubernetes is the Deployment resource. Deployments allow you to define the desired state for a set of Pods and ensure that the specified number of replicas are running, even in the face of node failures or other disruptions. 

Here are some key points about replicas in Kubernetes: 

 

Desired State: You specify the desired number of replicas for 	a particular application or service in a Deployment or a similar 	resource. 

 

Scaling: You can scale the number of replicas up or down by 	updating the desired count in the Deployment configuration. 	Kubernetes will then work to make the actual state match the desired 	state. 

 

High Availability: Replicas help ensure high availability by 	distributing the workload across multiple Pods. If a Pod fails, 	Kubernetes automatically replaces it with a new one to maintain the 	desired number of replicas. 

 

Load Balancing: When multiple replicas of a Pod are running, 	Kubernetes often provides load balancing to distribute incoming 	traffic across the replicas. 

 

Rolling Updates: Deployments can also manage rolling updates, 	allowing you to update your application without downtime. Old 	replicas are replaced with new ones gradually to avoid service 	disruptions. 

Replicas are a fundamental concept in Kubernetes that enables you to maintain the availability and reliability of your applications and services in a containerized environment. 

Replicaset is layer between deployment and pod. And replicaset is managing the replicas of a pod 
 With below command you can get information about replicas: 
```bash
$ kubectl get replicaset 
```
```console
NAME DESIRED CURRENT READY AGE 

nginx-depl-6b7698588c 1 1 0 8m16s 
  
 ```

the replica name is mad of prefix name(nginx-depl) and ID (6b7698588c) 

 
 

if you want ot edit image of deployment You shoud not edit the pod directly and you should do it in a deployment  
```bash
$ kubectl edit deployment nginx-depl 
 ```
 nginx-depl is the name of deployment  

we get an auto enerated configuration file the deplyment and you shoud find the the -image:nginx and change it aftar that save(write :wq in the end of fill and press the enter) it and you if you run the the command $ kubectl get pod you will see that your previous deplyment it is terminate and a new one is running. 

To see the deployments logs  
 ```bash
<<<<<<< Updated upstream
$ kubectl logs nginx-depl2-59fbbdc79c-pzz49 
```
To see pod describe  
```bash
$ kubectl describe pod nginx-depl-c8ddc48bf-s64v2 
 ```

Another very useful command when debugging when something is not working or you want to check what is going in inside the Pod is the  
```bash
$kubectl exec –it [Pod name] -- bin/bash - 
```
-It is stands for interactive terminal  

$ kubectl exec -it nginx-depl-c8ddc48bf-s64v2 -- bin/bash 
then you will enter the container nginx-depl and can execute the terminal command inside there 
to exit of the container environment use of exit command 

You can also delete deployment and pod  

$ kubectl delete deployment [name] 
```bash
$ kubectl delete deployment nginx-depl 
```
To create a new component or modify it through configuration file run command below. 
```bash
$ Kubectl apply –f nginx-deployent.yaml 
```
You can also create a new component through $ kubectl create deployment naem image option1 option2  

 $ kubectl apply command it can detect if there is not a deployment under the name of inside file it will be create but if there is exist it will be modify based on the option inside the file. 

To create that file you can use of this method 
```bash 
$ touch nginx-deployment.yaml 
```
```yaml
apiVersion: apps/v1 

kind: Deployment 

metadata: 

  name: nginx-deployment 

  labels: 

    app: nginx 

spec: # specification for deployment 

  replicas: 1 

  selector: 

    matchLabels: 

      app: nginx 

  template:  # Moved this line to the correct level 

    metadata: 

      labels: 

        app: nginx 

    spec: # specification for pod 

      containers: 

        - name: nginx 

          image: nginx:1.16 

          ports: 

            - containerPort: 80 

 ```

 [Back](../README.md)