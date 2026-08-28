# Copyright (c) 2022 StackHPC Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

import posixpath
import re


_VERSION_SUFFIX = re.compile(r"-[0-9]{8}T[0-9]{6}$")


def select_repos(repos, filter_string, package_sync_group):
    """Select repositories that match a filter string and package sync group.

    The filter string is a whitespace-separated list of regular expressions
    matching repository short names.

    The package sync group is a string matching a repository sync group.
    """
    if filter_string:
        regexes = filter_string.split()
        patterns = re.compile(r"|".join(regexes).join('()'))
        filtered_repos = [repo for repo in repos
                if "short_name" in repo and re.search(patterns, repo["short_name"])]
    else:
        filtered_repos = repos

    if package_sync_group:
        return [repo for repo in filtered_repos
            if "sync_group" in repo and repo["sync_group"] == package_sync_group]
    else:
        return filtered_repos


def select_images(images, filter_string):
    """Select images that match a filter string.

    The filter string is a whitespace-separated list of regular expressions
    matching image names.
    """
    if not filter_string:
        return images
    regexes = filter_string.split()
    patterns = re.compile(r"|".join(regexes).join('()'))
    return [image for image in images if re.search(patterns, image)]

def _repo_version(pub):
    # Orders by version, not timestamp.
    return int(pub["repository_version"].rstrip("/").rsplit("/", 1)[-1])


def _resolve(dist_specs, repositories, publications, distributions):
    """Resolve each desired distribution to its repo, latest publication and distribution.

    Builds the lookup tables once, rather than re-scanning every list for each
    repository as the equivalent Jinja did.
    """
    repo_by_name = {repo["name"]: repo for repo in repositories}

    # Newest publication per repository href.
    newest_pub = {}
    for pub in sorted(publications, key=_repo_version, reverse=True):
        newest_pub.setdefault(pub["repository"], pub)

    dists_by_pub = {}
    for dist in distributions:
        dists_by_pub.setdefault(dist.get("publication"), []).append(dist)

    for spec in dist_specs:
        repo = repo_by_name.get(spec["repository"])
        pub = newest_pub.get(repo["pulp_href"]) if repo else None
        dist = None
        if pub:
            base_name = _VERSION_SUFFIX.sub("", spec["name"])
            pattern = re.compile(
                r"^%s(-[0-9]{8}T[0-9]{6})?$" % re.escape(base_name))
            dist = next((d for d in dists_by_pub.get(pub["pulp_href"], [])
                         if pattern.match(d["name"])), None)
        yield spec, pub, dist

def latest_repo_versions(dist_specs, repositories, publications, distributions):
    """Map repository short_name to the version of its latest distribution."""
    return {
        spec["short_name"]: posixpath.basename(dist["base_path"])
        for spec, _pub, dist in _resolve(dist_specs, repositories,
                                         publications, distributions)
        if dist
    }

def distributions_to_create(dist_specs, repositories, publications,
                            distributions):
    """Return specs whose latest publication has no distribution serving it.

    Each returned spec gains a 'publication' key holding that publication's href.
    """
    return [
        dict(spec, publication=pub["pulp_href"])
        for spec, pub, dist in _resolve(dist_specs, repositories,
                                        publications, distributions)
        if pub and not dist
    ]


class FilterModule(object):

    def filters(self):
        return {
            "select_repos": select_repos,
            "select_images": select_images,
            "latest_repo_versions": latest_repo_versions,
            "distributions_to_create": distributions_to_create,
        }
