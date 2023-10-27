# Usage - content management HOWTO

While the [content management workflows](content-workflows.md) documentation provides information on each of the workflows provided by the release train, it does not give instructions for how to compose them to achieve common tasks.
That is the aim of this page.

## Update package repositories

Update one or more package repositories to a new version, then build new Kolla container images from those repositories.

If using Yoga release or earlier:

* If the repository URL has changed e.g. a new minor version has been released, add new package repositories to [`package-repos`](https://github.com/stackhpc/stackhpc-release-train/blob/main/ansible/inventory/group_vars/all/package-repos)
* [Sync package repositories](content-workflows.md#syncing-package-repositories) (optional: runs nightly as a scheduled GitHub Action)
* [Update Kayobe repository versions](content-workflows.md#updating-package-repository-versions-in-kayobe-configuration)
* [Build & push Kolla container images](content-workflows.md#building-container-images)
* [Update Kayobe container image tags](content-workflows.md#updating-container-image-tags-in-kayobe-configuration-yoga-release-and-earlier)
* Test
* Review & merge Kayobe configuration changes
* [Promote container images](content-workflows.md#promoting-container-images-yoga-release-and-earlier)

If using Zed release onwards:

* If the repository URL has changed e.g. a new minor version has been released, add new package repositories to [`package-repos`](https://github.com/stackhpc/stackhpc-release-train/blob/main/ansible/inventory/group_vars/all/package-repos)
* [Sync package repositories](content-workflows.md#syncing-package-repositories) (optional: runs nightly as a scheduled GitHub Action)
* [Update Kayobe repository versions](content-workflows.md#updating-package-repository-versions-in-kayobe-configuration)
* [Build & push Kolla container images](content-workflows.md#building-container-images)
* [Update Kayobe container image tags](content-workflows.md#updating-container-image-tags-in-kayobe-configuration-zed-release-onwards)
* Test
* Review & merge Kayobe configuration changes
* [Promote container images](content-workflows.md#promoting-container-images-zed-release-onwards)

## Update Kolla container images

Update one or more Kolla container images, without updating package repositories.

If using Yoga release or earlier:

* [Build & push Kolla container images](content-workflows.md#building-container-images)
* [Update Kayobe container image tags](content-workflows.md#updating-container-image-tags-in-kayobe-configuration-yoga-release-and-earlier)
* Test
* Review & merge Kayobe configuration changes
* [Promote container images](content-workflows.md#promoting-container-images-yoga-release-and-earlier)

If using Zed release onwards:

* [Build & push Kolla container images](content-workflows.md#building-container-images)
* [Update Kayobe container image tags](content-workflows.md#updating-container-image-tags-in-kayobe-configuration-zed-release-onwards)
* Test
* Review & merge Kayobe configuration changes
* [Promote container images](content-workflows.md#promoting-container-images-zed-release-onwards)

## Add a new Kolla container image

### Set up builds for the image

The list of services supported by StackHPC Kayobe configuration is defined via
the feature flags in the
[ci-builder](https://github.com/stackhpc/stackhpc-kayobe-config/blob/stackhpc/wallaby/etc/kayobe/environments/ci-builder/stackhpc-ci.yml)
environment. To add a new service, add the relevant feature flag (see
`etc/kayobe/kolla.yml` for supported flags). For example:

```yaml
kolla_enable_foo: true
```

Create a PR for the change.

### Set up Test Pulp syncing for the image

Next, the new images must be added to the `kolla_container_images` list in
[stackhpc-release-train](
https://github.com/stackhpc/stackhpc-release-train/blob/main/ansible/inventory/group_vars/all/kolla).
For example:

```yaml
kolla_container_images:
  8<
  - foo-api
  - foo-manager
  8<
```

Create a PR for the change.

### Build and consume the image

Once the two PRs have been approved and merged, follow the [steps
above](#update-kolla-container-images) to build and consume the new images.

### Set up client Pulp syncing for the image

Finally, the new images must be added to the `stackhpc_pulp_images` list in [etc/kayobe/pulp.yml](https://github.com/stackhpc/stackhpc-kayobe-config/blob/stackhpc/wallaby/etc/kayobe/pulp.yml).
This updates the list of images that are synced from Ark to clients' local Pulp service.
This step should be performed last, once the images have been pushed to Ark and promoted, otherwise client container syncs would fail.

```yaml
stackhpc_pulp_images:
  8<
  - foo-api
  - foo-manager
  8<
```

Create a PR for the change.
