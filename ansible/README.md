# Ansible workflow

You need Ansible installed on your machine. This could be a users virtualenvironment, like `~/.venvs/techquest-ansible`. The playbooks run on localhost and use the existing `oc` and `virtctl` clients; they do not need a remote Ansible inventory.
On my mac i used `ansible [core 2.21.6]` installed via `brew`.

From the repository root, put `oc` and `virtctl` on `PATH`. `env.sh` lists every target cluster in `MUTLICLUSTERID`. Each playbook logs in as admin and runs once for every listed cluster.

```bash
export PATH="$PWD/..:$HOME/.venvs/techquest-ansible/bin:$PATH"
ansible-playbook -i 'localhost,' -c local ansible/prepare_all.yml
```

Run one step for every configured cluster by naming that playbook:

```bash
ansible-playbook -i 'localhost,' -c local ansible/create_thesource.yml
```

`ansible/login_test.yml` only logs in to each cluster and checks that the session is `admin`.

## Preparation order for a new cluster

`ansible/prepare_all.yml` runs steps 1–6 and then publishes the lab guide. `prepare_registry.yml` stays separate because it prompts for a token.

1. `ansible/create_thesource.yml` creates only missing participant VMs, using `MAXUSER` and `IMAGEBUILDERURL` from `env.sh`.
2. `ansible/prepare_thesource.yml` copies the lab ZIP when missing or different, extracts it only if the work directory is absent, and installs `oc`/`virtctl` only if missing.
3. `ansible/configure_multus.yml` ensures each participant `thesource` has the flat network.
4. `ansible/configure_thesource.yml` ensures the internal-registry config and verifies the Red Hat subscription organization.
5. `ansible/start_prep_vms.yml` starts stopped organizer-prepared VMs and waits for them to become Ready. A missing `util` VM is skipped here.
6. `ansible/prepare_util.yml` creates the `util` VM on each cluster when it is missing, then prepares its tools and web server.
7. `ansible/prepare_registry.yml` prompts once for a Red Hat registry service-account username and token, then pushes the required images on every cluster. Run this only for a new cluster or when those images are missing.
8. `ansible/publish_labguide.yml` publishes `labguide/` to each cluster's `util`. `credentials.yaml` must list exactly the clusters in `MUTLICLUSTERID`, and each cluster must have users `user1` through `userN`, where `N` is `MAXUSER`.

To test the cleanup plan on every configured cluster without deleting anything:

```bash
ansible-playbook -i 'localhost,' -c local ansible/cleanup_lab.yml
```

Actual cleanup requires the explicit `-e confirm_cleanup=true` flag. Do not use it while the lab is active.

## Work already done on mpfcp

The participant VMs, util, registry images, and guide were prepared before these playbooks were added. The read-only/idempotent checks for thesource preparation, Multus, subscription ownership, and VM readiness were run. `prepare_registry.yml` and `publish_labguide.yml` were syntax-checked but not executed; images are already present, and publishing should wait until the guide and credentials are reviewed.

`configure_imagemode_multus.yml` adds `nic-flat` to the participant Image Mode VM and restarts it. That change was applied to `rhel10imagemode` in `mtv-user1`; direct SSH from the workstation still requires a network route/VPN that can reach the flat-network address.
