#!/usr/bin/env python3
from dataclasses import dataclass
from enum import Enum
import subprocess

index_key = str
ident = str
components = dict[ident, index_key]

@dataclass
class Resource:
    resource_address: str
    components: components

    def refresh_resource(self) -> None:
        print(self.components)
        for ident, index_key in self.components.items():
            query = query_statefile(self.resource_address, ident)
            query_response = unpack_query(query)
            if query_response == QueryResponse.RESOURCE_MISSING or query_response == QueryResponse.RESOURCE_UNKNOWN:
                import_missing_resource(self.resource_address, ident, index_key)


class TeamMembership(Resource):
    def __init__(self):
        Resource.__init__(self, "github_team_membership.team_membership", {"6328997:MrJHBauer": None})


class QueryResponse(Enum):
    RESOURCE_FOUND = 0,
    RESOURCE_MISSING = 1,
    RESOURCE_UNKNOWN = 2,
    UNDEFINED = 4


def query_statefile(resource_address: str, resource_id: str) -> subprocess.CompletedProcess[str]:
    cmd = ["terraform", "state", "list", f"-id={resource_id}", resource_address]
    return subprocess.run(cmd, capture_output=True)


def unpack_query(statefile_response: subprocess.CompletedProcess[str]) -> QueryResponse:
    result: QueryResponse = QueryResponse.UNDEFINED
    if statefile_response.returncode == 0:
        if statefile_response.stdout:
            result = QueryResponse.RESOURCE_FOUND
        else:
            result = QueryResponse.RESOURCE_MISSING
    elif statefile_response.returncode == 1:
        if "The current state contains no resource" in statefile_response.stderr.decode():
            result = QueryResponse.RESOURCE_UNKNOWN
    return result


def import_missing_resource(resource_address: str, resource_id: str, index_key: str = None) -> None:
    complete_resource_address = f"{resource_address}[\"{index_key}\"]" if index_key else resource_address
    cmd = ["terraform", "import", complete_resource_address, resource_id]
    output = subprocess.run(cmd, capture_output=True)
    print(output.stdout.decode())


def main() -> None:
    team = TeamMembership()
    team.refresh_resource()


if __name__ == "__main__":
    main()
