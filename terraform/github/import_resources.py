#!/usr/bin/env python3
from dataclasses import dataclass
from enum import Enum, unique
from functools import reduce
import json
import operator
import subprocess

index_key = str
ident = str
components = dict[ident, index_key]

@dataclass
class Resource:
    resource_address: str
    components: components

    def refresh_resource(self) -> None:
        for ident, index_key in self.components.items():
            query = query_statefile(self.resource_address, ident)
            query_response = unpack_query(query)
            if query_response == QueryResponse.RESOURCE_MISSING or query_response == QueryResponse.RESOURCE_UNKNOWN:
                import_missing_resource(self.resource_address, ident, index_key)


class TeamMembership(Resource):
    # API: gh api \
    # -H "Accept: application/vnd.github+json" \
    # /orgs/stackhpc/teams -q '.[] | {id, name}'
    def __init__(self, team_id: str, roster: list[str]):
        Resource.__init__(self, "github_team_membership.team_membership",
            {f'{team_id}:{entry}': f'{team_id}:{entry}' for entry in roster})


class TeamRepository(Resource):
    # API: gh api \
    # -H "Accept: application/vnd.github+json" \
    # /orgs/stackhpc/teams -q '.[] | {id, name}'
    def __init__(self, team_name: str, team_ident: str, repositories: list[str]):
        Resource.__init__(self, f"github_team_repository.{team_name}_repositories",
            {f"{team_ident}:{repository}": repository for repository in repositories})


class OrganisationTeam(Resource):
    # API: gh api \
    # -H "Accept: application/vnd.github+json" \
    # /orgs/stackhpc/teams -q '.[] | {id, name}'
    def __init__(self, teams: components):
        Resource.__init__(self, "github_team.organisation_teams", teams)


class BranchProtection(Resource):
    def __init__(self, team_name: str, patterns: dict[str, str]):
        Resource.__init__(self, f"github_branch_protection.{team_name}_branch_protection", patterns)


    def refresh_resource(self) -> None:
        for ident, index_key in self.components.items():
            query = query_statefile(self.resource_address)
            query_response = unpack_query(query)
            if query_response == QueryResponse.RESOURCE_MISSING or query_response == QueryResponse.RESOURCE_UNKNOWN:
                import_missing_resource(self.resource_address, ident, index_key)


class IssueLabel(Resource):
    def __init__(self, label_name: str, repositories: list[str]):
        Resource.__init__(self, f"github_issue_label.{label_name}_label",
            {f"{repository}:{label_name.replace('_', '-')}": repository for repository in repositories})


class Repository(Resource):
    def __init__(self, repositories: list[str]):
        Resource.__init__(self, "github_repository.repositories",
            {repository : repository for repository in repositories})


class QueryResponse(Enum):
    RESOURCE_FOUND = 0,
    RESOURCE_MISSING = 1,
    RESOURCE_UNKNOWN = 2,
    UNDEFINED = 4

@unique
class TeamID(Enum):
    ANSIBLE = 6329007
    AZIMUTH = 6328998
    BATCH = 6328999
    DEVELOPERS = 6329004
    KAYOBE = 6329000
    OPENSTACK = 6329005
    RELEASETRAIN = 6328997
    SMSLAB = 6329001

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
    return subprocess.run(cmd, capture_output=True)


def unpack_query(statefile_response: subprocess.CompletedProcess[str]) -> QueryResponse:
    result: QueryResponse = QueryResponse.UNDEFINED
    if statefile_response.returncode == 0:
        if statefile_response.stdout:
            result = QueryResponse.RESOURCE_FOUND
            print(f"\033[1m\033[92mResource Found:\033[0;0m \033[1m{statefile_response.stdout.decode()}\033[0;0m")
        else:
            result = QueryResponse.RESOURCE_MISSING
            print(statefile_response.stderr.decode())
    elif statefile_response.returncode == 1:
        if "The current state contains no resource" in statefile_response.stderr.decode():
            result = QueryResponse.RESOURCE_UNKNOWN
        print(statefile_response.stderr.decode())
    return result


def import_missing_resource(resource_address: str, resource_id: str, index_key: str = None) -> None:
    complete_resource_address = f"{resource_address}[\"{index_key}\"]" if index_key else resource_address
    cmd = ["terraform", "import", complete_resource_address, resource_id]
    output = subprocess.run(cmd, capture_output=True)
    print(output.stdout.decode())


def get_default_branches() -> dict[str, str]:
    commands = [
        ["terraform", "show", "-json"],
        ['jq', '-r', '.values[].resources[] | select(.mode == \"data\") | .values | {(.name): .default_branch}'],
        ['jq', '-s']
    ]
    terraform_show = subprocess.run(commands[0], capture_output=True)
    jq_extract = subprocess.run(commands[1], input=terraform_show.stdout, capture_output=True)
    jq_combine = subprocess.run(commands[2], input=jq_extract.stdout, capture_output=True)
    return reduce(lambda left, right: left | right, json.loads(jq_combine.stdout.decode()), {})

def main() -> None:
    repositories: dict[TeamID, list[str]] = {
        TeamID.ANSIBLE: [
            "kolla-ansible"
        ],
        TeamID.AZIMUTH: [],
        TeamID.BATCH: [],
        TeamID.KAYOBE: [],
        TeamID.OPENSTACK: [
            "cloudkitty"
        ],
        TeamID.RELEASETRAIN: [],
        TeamID.SMSLAB: []
    }
    team_roster: dict[TeamID, list[str]] = {
        TeamID.ANSIBLE: [
            "MrJHBauer",
            "jackhodgkiss"
        ],
        TeamID.AZIMUTH: [],
        TeamID.BATCH: [],
        TeamID.KAYOBE: [],
        TeamID.OPENSTACK: ["jackhodgkiss"],
        TeamID.RELEASETRAIN: [],
        TeamID.SMSLAB: []
    }
    issue_labels: list[str] = [
        "stackhpc_ci",
        "workflows",
        "community_files"
    ]
    for team_id, users in team_roster.items():
        team_membership_resource = TeamMembership(team_id.value, users)
        team_membership_resource.refresh_resource()
    for team_id, team_repositories in repositories.items():
        team_repository_resource = TeamRepository(team_id.name.lower(), team_id.value, team_repositories)
        team_repository_resource.refresh_resource()
    organisation_team_resource = OrganisationTeam({str(team.value): str(team) for team in TeamID})
    organisation_team_resource.refresh_resource()
    for issue_label in issue_labels:
        issue_label_resource = IssueLabel(issue_label, [repository for teams in repositories.values() for repository in teams])
        issue_label_resource.refresh_resource()
    repository_resource = Repository([repository for teams in repositories.values() for repository in teams])
    repository_resource.refresh_resource()
    default_branches = get_default_branches()
    for team_id, team_repositories in repositories.items():
        if team_id == TeamID.KAYOBE or team_id == TeamID.OPENSTACK:
            branch_protection_resource = BranchProtection(team_id.name.lower(), {f"{name}:stackhpc/**": name  for name in team_repositories})
            branch_protection_resource.refresh_resource()
        else:
            branch_protection_resource = BranchProtection(team_id.name.lower(), {f"{name}:{default_branches[name]}": name  for name in team_repositories})
            branch_protection_resource.refresh_resource()


if __name__ == "__main__":
    main()
