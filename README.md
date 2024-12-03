# cloud-1
The goal of this project is to deploy a website and the necessary docker infrastructure on an instance created with a cloud provider.
The website, its database, as well as the webserver mut be in different containers.

## Techs used
We will be using Ansible and Terraform for the deployment, and Docker/docker-compose for the containerization.

## Variables
we have included some dummy files that you can just populate with your own values. you need to have the following :
- terraform/terraform.tvars
- ansible/docker_config/vars/main.yml
