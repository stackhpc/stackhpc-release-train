#!/usr/bin/env python3

"""
Import existing GitHub resources from the `stackhpc` organisation
so that they maybe managed by Terraform. It shall only import resources
that are defined within the `terraform.tfvars.json` file nd are currently
available on GitHub.
"""

import argparse
from dataclasses import dataclass
from enum import Enum, unique
import itertools
import json
from pathlib import Path
import subprocess
from typing import Any

IndexKey = str
Ident = str
Components = dict[Ident, IndexKey]


@dataclass
class Resource:
    resource_address: str
    components: Components
    is_dry_run: bool = False

    def refresh_resource(self) -> None:
        for ident, index_key in self.components.items():
            query = query_statefile(self.resource_address, ident)
            query_response = unpack_query(query)
            if query_response == QueryResponse.INSTANCE_MISSING or query_response == QueryResponse.RESOURCE_UNKNOWN:
                import_missing_resource(
                    self.resource_address, ident, index_key, self.is_dry_run)


class TeamMembership(Resource):
    def __init__(self, team_name: str, team_id: str, roster: list[str], is_dry_run: bool):
        Resource.__init__(self, "github_team_membership.team_membership",
                          {f'{team_id}:{entry}': f'{team_name}:{entry}' for entry in roster}, is_dry_run)


class TeamRepository(Resource):
    def __init__(self, team_name: str, team_ident: str, repositories: list[str], is_dry_run: bool):
        Resource.__init__(self, f"github_team_repository.{team_name}_repositories",
                          {f"{team_ident}:{repository}": repository for repository in repositories}, is_dry_run)


class OrganisationTeam(Resource):
    def __init__(self, teams: Components, is_dry_run: bool):
        Resource.__init__(
            self, "github_team.organisation_teams", teams, is_dry_run)


class BranchProtection(Resource):
    def __init__(self, team_name: str, patterns: dict[str, str], is_dry_run: bool):
        Resource.__init__(
            self, f"github_branch_protection.{team_name}_branch_protection", patterns, is_dry_run)

    def refresh_resource(self) -> None:
        for ident, index_key in self.components.items():
            query = query_statefile(self.resource_address)
            query_response = unpack_query(query)
            if query_response == QueryResponse.INSTANCE_MISSING or query_response == QueryResponse.RESOURCE_UNKNOWN:
                import_missing_resource(
                    self.resource_address, ident, index_key, self.is_dry_run)


class IssueLabel(Resource):
    def __init__(self, label_name: str, repositories: list[str], is_dry_run: bool):
        Resource.__init__(self, f"github_issue_label.{label_name}_label",
                          {f"{repository}:{label_name.replace('_', '-')}": repository for repository in repositories}, is_dry_run)


class Repository(Resource):
    def __init__(self, repositories: list[str], is_dry_run: bool):
        Resource.__init__(self, "github_repository.repositories",
                          {repository: repository for repository in repositories}, is_dry_run)


class QueryResponse(Enum):
    RESOURCE_FOUND = 0,
    INSTANCE_MISSING = 1,
    RESOURCE_UNKNOWN = 2,
    UNDEFINED = 4


@unique
class TeamID(Enum):
    # API: gh api \
    # -H "Accept: application/vnd.github+json" \
    # /orgs/stackhpc/teams -q '.[] | {id, name}'
    ANSIBLE = 2454000
    AZIMUTH = 6372898
    BATCH = 6372897
    DEVELOPERS = 6309608
    KAYOBE = 6156230
    OPENSTACK = 6372899
    RELEASETRAIN = 6372895
    SMSLAB = 6372896

    def __str__(self) -> str:
        result: str = self.name.capitalize()
        if self == TeamID.OPENSTACK:
            result = "OpenStack"
        elif self == TeamID.RELEASETRAIN:
            result = "ReleaseTrain"
        elif self == TeamID.SMSLAB:
            result = "SMSLab"
        return result


def query_statefile(resource_address: str, resource_id: str = None) -> subprocess.CompletedProcess[str]:
    cmd = ["terraform", "state", "list", f"-id={resource_id}", resource_address] if resource_id \
        else ["terraform", "state", "list", resource_address]
    return subprocess.run(cmd, capture_output=True, check=False)


def unpack_query(statefile_response: subprocess.CompletedProcess[str]) -> QueryResponse:
    result: QueryResponse = QueryResponse.UNDEFINED
    try:
        statefile_response.check_returncode()
    except subprocess.CalledProcessError as error:
        if "The current state contains no resource" in error.stderr.decode():
            result = QueryResponse.RESOURCE_UNKNOWN
        print(error.stderr.decode().splitlines()[1])
    else:
        if statefile_response.returncode == 0:
            if statefile_response.stdout:
                result = QueryResponse.RESOURCE_FOUND
                print(f"Resource Found: {statefile_response.stdout.decode()}")
            else:
                result = QueryResponse.INSTANCE_MISSING
                print("Warning: Instance missing")
    return result


def import_missing_resource(resource_address: str, resource_id: str, index_key: str = None, is_dry_run: bool = False) -> None:
    complete_resource_address = f"{resource_address}[\"{index_key}\"]" if index_key else resource_address
    cmd = ["terraform", "import", complete_resource_address, resource_id]
    print("\trun =>", *cmd)
    if not is_dry_run:
        output = subprocess.run(cmd, capture_output=True, check=False)
        try:
            output.check_returncode()
        except subprocess.CalledProcessError as error:
            if "Could not find" in error.stderr.decode():
                print(error.stderr.decode().splitlines()[1], end="\n\n")
            else:
                print(error.stderr.decode())
        else:
            if "Import successful!" in output.stdout.decode():
                print("Import Successful!", end="\n\n")
            else:
                print(error.stderr.decode())


def get_default_branches() -> dict[str, str]:
    branches = {}
    cmd = ["terraform", "state", "pull"]
    complete_path = Path(__file__).parent.joinpath("terraform.state.pull")
    tfstate_file = open(complete_path, "w", encoding="utf-8")
    subprocess.run(cmd, stdout=tfstate_file, encoding="utf-8", check=False)
    tfstate_json = json.load(open(complete_path, "r", encoding="utf-8"))
    for repository in tfstate_json["resources"][0]["instances"]:
        branches[repository["index_key"]] = repository["attributes"]["default_branch"]
    return branches


def populate_repository_data() -> None:
    cmd = ["terraform", "apply", "-refresh-only", "-auto-approve"]
    output = subprocess.run(cmd, capture_output=True, check=False)
    print(output.stdout.decode())


def read_vars(path: str = "terraform.tfvars.json") -> dict[str, Any]:
    complete_path = Path(__file__).parent.joinpath(path)
    return json.load(open(complete_path, "r", encoding="utf-8"))


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("-n", "--dry-run", action=argparse.BooleanOptionalAction, default=False,
                        help="Do not perform any actions that would result in permanent change \
                        to the statefile. Intended to be used to determine if running would make \
                        the intended changes")
    return parser.parse_args()


def main() -> None:
    parsed_args = parse_args()
    print(f"Is Dry Run: {parsed_args.dry_run}")
    terraform_vars = read_vars()
    populate_repository_data()
    team_roster = {TeamID[team[0].upper()]:
                   [*itertools.chain.from_iterable(team[1]["users"].values())]
                   for team in terraform_vars["teams"].items()}
    repositories = {TeamID[team[0].upper()]: team[1]
                    for team in terraform_vars["repositories"].items()}
    default_branches = get_default_branches()
    issue_labels = terraform_vars["labels"]
    for team_id, team_repositories in repositories.items():
        if team_id == TeamID.KAYOBE or team_id == TeamID.OPENSTACK:
            branch_protection_resource = BranchProtection(team_id.name.lower(
            ), {f"{name}:stackhpc/**": name for name in team_repositories}, parsed_args.dry_run)
            branch_protection_resource.refresh_resource()
        else:
            branch_protection_resource = BranchProtection(team_id.name.lower(
            ), {f"{name}:{default_branches[name]}": name for name in team_repositories}, parsed_args.dry_run)
            branch_protection_resource.refresh_resource()
    for team_id, users in team_roster.items():
        team_membership_resource = TeamMembership(
            str(team_id), team_id.value, users, parsed_args.dry_run)
        team_membership_resource.refresh_resource()
    for team_id, team_repositories in repositories.items():
        team_repository_resource = TeamRepository(
            team_id.name.lower(), team_id.value, team_repositories, parsed_args.dry_run)
        team_repository_resource.refresh_resource()
    for _, team_repositories in repositories.items():
        team_repository_resource = TeamRepository(TeamID.DEVELOPERS.name.lower(
        ), TeamID.DEVELOPERS.value, team_repositories, parsed_args.dry_run)
        team_repository_resource.refresh_resource()
    organisation_team_resource = OrganisationTeam(
        {str(team.value): str(team) for team in TeamID}, parsed_args.dry_run)
    organisation_team_resource.refresh_resource()
    for issue_label in issue_labels:
        issue_label_resource = IssueLabel(issue_label, [
                                          repository for teams in repositories.values() for repository in teams], parsed_args.dry_run)
        issue_label_resource.refresh_resource()
    repository_resource = Repository(
        [*itertools.chain.from_iterable(repositories.values())], parsed_args.dry_run)
    repository_resource.refresh_resource()


if __name__ == "__main__":
    main()
