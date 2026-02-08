to run this playbook you need to install sshpass and a few things from ansible-galaxy

```bash
sudo apt install sshpass
ansible-galaxy collection install community.docker
```

Need to run this command

```bash
ansible-playbook -i config.ini install_docker_portainer.yml
```

