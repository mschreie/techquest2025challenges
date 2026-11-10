# Ansible workflow

The playbooks run on localhost. They use the `oc` and `virtctl` clients already on your machine and do not need a remote Ansible inventory.

Ansible can be installed in a virtual environment, for example `~/.venvs/techquest-ansible`. This was run with Ansible core 2.21.6 from Homebrew.

From the repository root, put `oc` and `virtctl` on `PATH`:

```bash
export PATH="$PWD/..:$HOME/.venvs/techquest-ansible/bin:$PATH"
```

## env.sh

`env.sh` in the repository root lists the clusters for this event. It is committed. These cluster values are short-lived and are replaced for the next event.

Set:

- `MUTLICLUSTERID`: space-separated cluster ids, for example `cwk2t rhwqw`. The name is spelled that way in the file.
- `MAXUSER`: number of participant projects on each cluster. The playbooks use `mtv-user1` through `mtv-userN`.
- `ADMINPW_<cluster id>`: admin password for each id in `MUTLICLUSTERID`, for example `ADMINPW_cwk2t`.
- `IMAGEBUILDERURL`: signed URL of the RHEL qcow2 built in Image Builder. Replace it when the image expires.

Every playbook reads this file, logs in as admin, and runs once for each cluster id.

## rhsm.sh

`rhsm.sh` holds the Red Hat subscription organization id and activation key. Anyone with both values can register RHEL systems to that account, so the file is listed in `.gitignore` and must not be committed.

Create it from the repository root before registering VMs:

```bash
cp rhsm.sh.example rhsm.sh
```

Set both values in `rhsm.sh`:

- `RHSM_ORG_ID`
- `RHSM_ACTIVATION_KEY`

`configure_thesource.yml`, `prepare_util.yml`, and `cleanup_lab.yml` read this file. `ansible/prepare_all.yml` includes the first two, so `rhsm.sh` must exist before the full run. The task output hides these values.

## Run the preparation

Prepare every configured cluster:

```bash
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
2. `ansible/prepare_thesource.yml` waits until each `thesource` VMI is Ready and SSH accepts connections, then copies the lab ZIP when missing or different, extracts it only if the work directory is absent, and installs `oc`/`virtctl` only if missing.
3. `ansible/configure_multus.yml` ensures each participant `thesource` has the flat network.
4. `ansible/configure_thesource.yml` ensures the internal-registry config and verifies the Red Hat subscription organization from `rhsm.sh`.
5. `ansible/start_prep_vms.yml` starts stopped organizer-prepared VMs and waits for them to become Ready. A missing `util` VM is skipped here.
6. `ansible/prepare_util.yml` waits until the `util` VMI is Ready, creates it on each cluster when it is missing, and prepares its tools and web server. Registration uses `rhsm.sh`.
7. `ansible/prepare_registry.yml` prompts once for a Red Hat registry service-account username and token, then pushes the required images on every cluster. Run this only for a new cluster or when those images are missing.
8. `ansible/publish_labguide.yml` publishes `labguide/` to each cluster's `util`. A mismatch between `credentials.yaml` and the clusters or users in `env.sh` is reported as a warning.

## Clean up

To test the cleanup plan on every configured cluster without deleting anything:

```bash
ansible-playbook -i 'localhost,' -c local ansible/cleanup_lab.yml
```

Actual cleanup requires `-e confirm_cleanup=true`. Do not use that flag while the lab is active. Cleanup also reads `rhsm.sh` and refuses to delete a VM registered to a different organization.
