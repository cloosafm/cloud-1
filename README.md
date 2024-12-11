# cloud-1
The goal of this project is to deploy a website and the necessary docker infrastructure on an instance created with a cloud provider.
The website, its database, as well as the webserver mut be in different containers.

## Techs used
We will be using Ansible and Terraform for the deployment, and Docker/docker-compose for the containerization.

## Variables
We have included some dummy files that you can just populate with your own values. you need to have the following :
- terraform/credentials.json				: your credentials for your cloud provider
- terraform/terraform.tvars					: sensitive variables for terraform
- ansible/inception_setup/templates/env.j2	: jinja template to create the .env for docker
- ansible/inception_setup/files/srcs/requirements/wordpress/conf/wp-config.php			: config data for wordpress
- ansible/docker_config/vars/main.yml		: for the docker user
