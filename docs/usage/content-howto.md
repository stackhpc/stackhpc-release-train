# Usage - content management HOWTO

While the [content management workflows](content-workflows.md) documentation provides information on each of the workflows provided by the release train, it does not give instructions for how to compose them to achieve common tasks.
That is the aim of this page.

## Update package repositories

Update one or more package repositories to a new version, then build new Kolla container images from those repositories.

* [Sync package repositories](content-workflows.md#syncing-package-repositories) (optional)
* [Update Kayobe repository versions](content-workflows.md#updating-package-repository-versions-in-kayobe-configuration)
* [Build & push Kolla container images](content-workflows.md#building-container-images)
* [Sync container images](content-workflows.md#syncing-container-images)
* [Update Kayobe container image tags](content-workflows.md#updating-container-image-tags-in-kayobe-configuration)
* Test
* Review & merge Kayobe configuration changes
* [Promote package repositories](content-workflows.md#promoting-package-repositories)
* [Promote container images](content-workflows.md#promoting-container-images)

## Update Kolla container images

Update one or more Kolla container images, without updating package repositories.

* [Build & push Kolla container images](content-workflows.md#building-container-images)
* [Sync container images](content-workflows.md#syncing-container-images)
* [Update Kayobe container image tags](content-workflows.md#updating-container-image-tags-in-kayobe-configuration)
* Test
* Review & merge Kayobe configuration changes
* [Promote container images](content-workflows.md#promoting-container-images)
