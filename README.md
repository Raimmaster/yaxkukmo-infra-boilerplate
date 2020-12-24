# Yaxkukmo Infra Boilerplate

## Dependencies

This project was created with **Terraform v0.14.2** and **Packer v1.4.4**.

## Intro

This repo contains a boilerplate to deploy an infrastructure for web-apps using Packer and Terraform (TF).
It assumes you've configured an AWS CLI profile named `terraform-local` in the `us-east-1` region. If you haven't, after you've obtained your access key and secret, you can do so with the following command:

```bash
aws configure --profile terraform-local
```

## Packer
The AMIs generated with Packer are for the VPN instance and EC2 web-app instances, the VPN instance being the one we'll connect to access the SSH in the private web-app instances.

### VPN AMI
For this one I use an [OpenVPN install script](https://github.com/Nyr/openvpn-install) to run on my own EC2 instance, which you'll have to configure later. 

The image can be built by running the following from the project's root directory:
 ```bash
 cd packer/vpn
 packer build vpn.json
 ```

### Web-App AMI
This one should have your web-app configuration, but in the meantime you can test the functionality by running the [NGINX Docker container](https://hub.docker.com/_/nginx). The AMI generated will have Docker container engine **version 19** installed and Docker Compose in order to run the containers.  I use the **alpine** tag in the `docker-compose.yml` to have a smaller image downloaded. It will be binded to the instance's port **80**. There's a unit file (`yaxkukmo.service`) configured in it so the Docker container will run at startup. 

The image can be built by running the following from the project's root directory:
 ```bash
 cd packer/web-app
 packer build web-app.json
 ```

## Terraform
For this configuration I'm using local state, so a future release will be moved to using remote state for the TF configuration. You should set up your own `terraform.tfvars` file with the following variables:

```conf
domain = "your-domain.com"
home_ip = "YOUR_PUBLIC_IP"
public_key = "SSH_PUBLIC_KEY_VALUE"
```

Initiate your Terraform project with the following:
```bash
terraform init
```

You should run the plan first to check what resources will be created and export the plan for future use:
```bash
cd terraform
terraform plan -out infra.plan
```

Plan files are already in the `.gitignore` so you shouldn't worry about their details being leaked. 
After you've checked the plan and what resources will be created, updated, or destroyed, you should run it:
```bash
terraform apply infra.plan
```
### Main Configuration
In the root directory of the TF configuration I use the [TF AWS VPC module](https://github.com/terraform-aws-modules/terraform-aws-vpc) to handle an easier creation of the VPC resources (VPC, private and public subnets, internet and NAT gateways, route tables and associations).

It's currently set to use the `us-east-1` region, so the availability zones the VPC uses `us-east-1a`, `us-east-1b`, and `us-east-1c`. A future release will use variables for the AZs.

### Web-App Configuration
The `web-app` module uses the AMI we generated with Packer to run the Docker `nginx:alpine` container in each instance that will be created by the auto-scaling group (ASG). I use the [TF ASG module](https://github.com/terraform-aws-modules/terraform-aws-autoscaling) to handle an easier creation of the ASG resources, including the instances. The instances are all `t3.micro`, so they should be covered in AWS' free tier. The Application Load Balancer redirects all HTTP traffic to HTTPS automatically.

For the `aws_key_pair` resource you will have to provide your SSH public key in the `.tfvars` file as mentioned earlier. This will create a key pair based on your personal SSH key. You can check on how to generate one in [GitHub's docs](https://docs.github.com/en/github-ae@latest/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent).

Because I'm not using AWS Route 53 for the domain but rather an external one for my domain, for the SSL certificate you'll have to validate manually the SSL certificate in AWS ACM. So if you were using like me Namecheap, you'll have to request a [public certificate in AWS ACM](https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-request-public.html) and then create the respective DNS entry in Namecheap's management console. There is a [TF provider for Namecheap](https://github.com/adamdecaf/terraform-provider-namecheap), **however** you must have Namecheap API access and you can only use that if you have the following: account balance of $50+, 20+ domains in your account, or purchases totaling $50+ within the last 2 years.

After you provide in the `.tfvars` your `domain` variable with the domain you own, it will look in the `data` block for the certificate ACM has issued for you. **This must be done before you run your TF plan.**


### Jumper VPN Configuration
For the Jumper VPN instance you'll SSH access from your home computer if you placed in your `.tfvars` file the `home_ip` value of your public IP. This is necessary on the first time you create your instance because the VPN must be configured according to the public IP the EC2 instance will receive. All you do after accessing the instance is run the following command and fill the prompts:
```bash
sudo bash openvpn-install.sh
```

At the end of prompt you'll be asked the name of the client. If you keep the default, then be sure to move the `.ovpn` file to your home:
```bash
sudo mv /root/client.ovpn .
```

You can get that `.ovpn` file in your computer with `scp`:
```bash
scp -i SSH_PRIVATE_KEY_FILE ubuntu@EC2_PUBLIC_IP:/home/ubuntu/client.ovpn .
```

After that it is recommended you remove the SSH access to the jumper instance from your home PC.


## Accessing Your Instances With SSH
After you've deployed your AWS infra with TF, install OpenVPN in your computer. If you're in Linux, after it's installed and you've downloaded the `.ovpn` file, you can connect to it with the following command:
```bash
sudo openvpn --config client.ovpn
```

You'll then be able to SSH into the web-app private instances with your private key and their private IPs.