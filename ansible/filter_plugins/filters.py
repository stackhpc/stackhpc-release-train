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


def select_repos(repos, filter_string):
    """Select repositories that match a filter string.

    The filter string is a comma-separated list of repository short_names.
    """
    if not filter_string:
        return repos
    short_names = filter_string.split(",")
    short_names = [n.strip() for n in short_names]
    return [repo for repo in repos if repo.get("short_name") in short_names]


def select_images(images, filter_string):
    """Select images that match a filter string.

    The filter string is a comma-separated list of image names.
    """
    if not filter_string:
        return images
    names = filter_string.split(",")
    names = [n.strip() for n in names]
    return [image for image in images if image in names]


class FilterModule(object):

    def filters(self):
        return {
            "select_repos": select_repos,
            "select_images": select_images,
        }
