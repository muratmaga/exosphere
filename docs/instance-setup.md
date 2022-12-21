# Instance Setup Code

Exosphere uses Ansible to configure and provision new instances. (Among other things, it installs and configures Docker and Apache Guacamole server for the one-click terminal and remote desktop environment.) The setup code is stored in the `ansible/` directory of the Exosphere repository.

By default, new instances pull this code from the master branch of the upstream [exosphere/exosphere](https://gitlab.com/exosphere/exosphere/) repository. This is true even for instances which are launched using a different branch or fork of Exosphere.

You may wish to configure Exosphere to deploy instances using your own (modified) instance setup code, for development/testing purposes or as customized for your own organization. To do that, you must push the code to a git repository somewhere that new instances can download from, and then set two options in `config.js`:

- `instanceConfigMgtRepoUrl` to the git repository URL that new instances can download your setup code from
- `instanceConfigMgtRepoCheckout` to the repository branch/tag/commit that should be checked out (defaults to master if left `null`)

Note that Exosphere downloads the specified repo and runs the playbook stored at `ansible/playbook.yml`, so implement your changes by modifying that playbook.

---

To test the instance setup code locally on a cloud instance, do this:
```
virtualenv /opt/ansible-venv
. /opt/ansible-venv/bin/activate
pip install ansible-core
ansible-pull --url https://gitlab.com/exosphere/exosphere.git --directory /opt/instance-config-mgt -i /opt/instance-config-mgt/ansible/hosts /opt/instance-config-mgt/ansible/playbook.yml
```

Optionally, pass the `--checkout` argument to specify a git branch/tag or commit hash.

For now, we are using only [built-in Ansible modules](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/#modules), because Exosphere uses the lightweight `ansible-core` package.

## Ansible variables currently used

Exosphere sets these variables when running the instance setup code on a new instance.

| variable     | type    | required | description                                                             |
|--------------|---------|----------|-------------------------------------------------------------------------|
| guac_enabled | boolean | no       | deploys Apache Guacamole to serve terminal (and optionally desktop)     |
| gui_enabled  | boolean | no       | deploys VNC server, configures Guacamole to serve graphical desktop     |