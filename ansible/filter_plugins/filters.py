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

import re


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


class FilterModule(object):

    def filters(self):
        return {
            "select_repos": select_repos,
            "select_images": select_images,
        }
