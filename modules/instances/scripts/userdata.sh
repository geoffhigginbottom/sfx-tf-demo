#cloud-config
users:
  - name: terraform
    groups: sudo
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh-authorized-keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQCvNDoTGGhDgRmu12gqH7fn8aLxIL4Gnm3bQr6XXx9wUVtAjMipxlYJlrUV9Y5tk3w3RSRdUeXcol8pRe0+fWtd2w9Kj9POfBu+Nc2bA1HOKE+HJqsrvHSUM0sp3fqo82fLWzTDZ+o6OoF5mQy2Sbpuxl31VpVhuqMAAKh+DazZMQ== geoff@geoffh
runcmd:
  - sudo usermod -a -G wheel terraform