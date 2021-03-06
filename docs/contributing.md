# Contributing

## Modifying the documentation

This documentation is built via [MkDocs](https://www.mkdocs.org/) and hosted via [GitHub pages](https://stackhpc.github.io/stackhpc-release-train/).
The configuration file is [mkdocs.yml](https://github.com/stackhpc/stackhpc-release-train/blob/main/mkdocs.yml), and documentation Markdown source is in [docs/](https://github.com/stackhpc/stackhpc-release-train/blob/main/docs).
GitHub Actions workflows build the documentation in pull requests, and deploy it to GitHub pages on pushes to `main`.

To build and serve the documentation locally at <http://127.0.0.1:8000/stackhpc-release-train>:
```
python3 -m venv mkdocs-venv
source mkdocs-venv/bin/activate
pip install -U pip
pip install -r docs-requirements.txt
mkdocs serve
```
