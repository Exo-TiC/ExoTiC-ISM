# Contribution guidelines

## General guidelines
Hello and thank you for contributing to our project! Go ahead open a new issue or new pull request (PR) for bugs,
feedback, or new features you would like to see by following these guidelines.
Leave a comment anywhere and we will be happy to assist. New contributions and contributors are very welcome!
We recommend that you **fork** the repository and submit your requests according to these guidelines:

1) Search previous issues and pull requests as your question or suggestion might be a duplicate.
2) Open a separate issue or pull request for each suggestion or bug report.
3) Pull requests, issues and commits should have a useful title.
4) Give every PR a description and open it against **develop**, the default branch of the repository.
5) Every PR that adds or changes a feature should also add or change an/the according **test**, if applicable, as well
as **documentation**.

## Running the test suite
We use the [pytest](https://docs.pytest.org/en/stable/) framework for the unit and regression tests on our repository.
To run the tests locally to make sure that they all pass, you just have to navigate into the top-level repository
directory, activate your `exoticism` conda environment (`$ conda activate exoticism`) and run:
```bash
$ pytest
```
This will run all tests and give you a test report with passing and failing tests. The package `pytest` is automatically
installed in the `exoticism` conda environment when creating it from our `environment.yml` file as described in the
[Quickstart section of our README](README.md/#quickstart).

## Code of conduct
This package follows the Contributor Covenant [Code of Conduct](CODE_OF_CONDUCT.md) to provide a welcoming community to everybody.
