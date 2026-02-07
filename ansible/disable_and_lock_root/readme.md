to run this playbook you need to install sshpass

```bash
sudo apt install sshpass
```

Need to run this command

```bash
ansible-playbook -i config.ini lockout_root.yml
```

Note: make sure to have config_verify_root.ini