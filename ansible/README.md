# Ansible workflow

Ansible is installed in the user virtualenv at `~/.venvs/techquest-ansible`. The playbooks run on localhost and use the existing `oc` and `virtctl` clients; they do not need a remote Ansible inventory.

From the repository root, prepare the PATH and log in as the OpenShift admin:

```bash
export PATH="$PWD/..:$HOME/.venvs/techquest-ansible/bin:$PATH"
ansible-playbook -i 'localhost,' -c local ansible/login.yml
```

The login playbook reads the cluster ID and admin password from `env.sh`; it hides the password from output. The other playbooks verify the active cluster and admin identity before changes.

## Preparation order for a new cluster

1. `ansible/create_thesource.yml` creates only missing participant VMs, using `MAXUSER` and `IMAGEBUILDERURL` from `env.sh`.
2. `ansible/prepare_thesource.yml` copies the lab ZIP when missing or different, extracts it only if the work directory is absent, and installs `oc`/`virtctl` only if missing.
3. `ansible/configure_multus.yml` ensures each participant `thesource` has the flat network.
4. `ansible/configure_thesource.yml` ensures the internal-registry config and verifies the Red Hat subscription organization.
5. `ansible/start_prep_vms.yml` starts stopped organizer-prepared VMs and waits for them to become Ready.
6. `ansible/prepare_util.yml` creates util only if missing and prepares its tools and web server.
7. `ansible/prepare_registry.yml` prompts for a Red Hat registry service-account username and token, then pushes the required images to OpenShift. Run this only for a new cluster or when those images are missing.
8. Check `labguide/credentials.yaml` and the guide content, then run `ansible/publish_labguide.yml` to publish them to util.

To test the cleanup plan without deleting anything:

```bash
ansible-playbook -i 'localhost,' -c local ansible/cleanup_lab.yml
```

Actual cleanup requires the explicit `-e confirm_cleanup=true` flag. Do not use it while the lab is active.

## Work already done on mpfcp

The participant VMs, util, registry images, and guide were prepared before these playbooks were added. The read-only/idempotent checks for thesource preparation, Multus, subscription ownership, and VM readiness were run. `prepare_registry.yml` and `publish_labguide.yml` were syntax-checked but not executed; images are already present, and publishing should wait until the guide and credentials are reviewed.

`configure_imagemode_multus.yml` adds `nic-flat` to the participant Image Mode VM and restarts it. That change was applied to `rhel10imagemode` in `mtv-user1`; direct SSH from the workstation still requires a network route/VPN that can reach the flat-network address.
