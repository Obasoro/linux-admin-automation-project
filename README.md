# linux-admin-automation-project

## Part 1: Set up Repository

1. Create Folders

```sudo mkdir -p documentation```

```sudo mkdir -p scripts```

```sudo mkdir -p monitoring```

```sudo mkdir -p config```

```sudo mkdir -p linux-admin-automation-project/{scripts,monitoring,monitoring,documentation}```

2. Create Pre-Commit Hook

```sudo touch .git/hook.pre-commit```

# Pre-commit Hook Setup Script

``` sudo mkdir -p .git/hooks```

## Part 2: Linux Administration 

1. Using a cloud provider `AWS`, created two virtual machine

![image](https://github.com/user-attachments/assets/fe805e71-6dc9-426c-926f-e4ed81147529)

`Admin server`

![image](https://github.com/user-attachments/assets/7192c8e4-8a76-4442-8e02-8970cfac3e1e)

`target server`

![image](https://github.com/user-attachments/assets/3654c1f8-2705-43bc-a7d4-6f940d0049ca)

Create a User `kunle` in `target` server

![image](https://github.com/user-attachments/assets/aff8da77-0cfd-4b9c-a54b-918df60f0570)

Created a user `NodeOps` in `admin` server. Created a group `DevOps`. Added the User to the group.

![image](https://github.com/user-attachments/assets/710bb1da-791b-4b0c-936c-8190d3d3a8f7)



![image](https://github.com/user-attachments/assets/a9526153-8071-4032-8b8d-1c1a18d62e93)

```group NodeOps```

![image](https://github.com/user-attachments/assets/54c23c0d-73c3-42d5-8f50-b664f09a0383)


3. Installation of Packages

   ```sudo yum install nginx``` on bothe `NodeOps` user and 'kunle` user

   ![image](https://github.com/user-attachments/assets/7935f6a1-22f1-4d62-92cc-edc647102eda)

   ![image](https://github.com/user-attachments/assets/7faca0a0-c1d2-408b-91cf-4c8ebab8adc1)

System configuration

![image](https://github.com/user-attachments/assets/3d6f1e7e-7c96-4f68-956d-a0f63b36851b)

![image](https://github.com/user-attachments/assets/36ab2fdd-b824-4520-bda9-37d35b510932)

Find the `cpu` usage of the system

`lscpu`

![image](https://github.com/user-attachments/assets/2970c73b-0c6f-425d-b4d5-609426733333)


`lsblk`

![image](https://github.com/user-attachments/assets/47c7cc60-42eb-46ed-a084-3b72bea9a6af)

Created a volume and attached it to `admin` and `target` servers

![image](https://github.com/user-attachments/assets/1bd43765-2d38-4fdc-ac78-ec7b0fc169a7)


![image](https://github.com/user-attachments/assets/b53958c1-cee0-4ddf-a294-e9815f6eeb84)

Monitoring of System

```sudo ps aux```

![image](https://github.com/user-attachments/assets/aa449e8c-bd45-4839-8808-8b596f9a3875)

```sudo htop```

![image](https://github.com/user-attachments/assets/2e107b37-ae8f-4844-9e66-8ad51be2435c)

******************

## Task 3

****************

For the `users` created on `AWS`

![image](https://github.com/user-attachments/assets/f9d158b0-950a-4a34-be16-95c56af4ba41)

```sh
Open the Amazon EC2 Console
Navigate to "Network & Security" > "Elastic IPs"
Click "Allocate Elastic IP address"
Select "Amazon's pool of IPv4 addresses"
Click "Allocate"

```

![image](https://github.com/user-attachments/assets/0c875819-132e-4298-8d7f-ceffefd819b9)









   






