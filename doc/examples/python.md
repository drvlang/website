# Python with Flask {#python}

Flask locks its Python dependencies with uv. drvpy selects compatible distributions, creates the Python environment, and includes the project’s locked test dependencies for the test command.

```sh
git clone --depth 1 --branch 3.1.3 https://github.com/pallets/flask
nix run github:drvlang/drvpy -- test -C flask -- tests/test_basic.py -q
```

This exercises 130 upstream tests for Flask behavior including requests, routing, and sessions. The arguments after `--` select a file for pytest. To build the runtime environment alone, run `nix run github:drvlang/drvpy -- build -C flask`. [Flask’s tests](https://github.com/pallets/flask/blob/22d924701a6ae2e4cd01e9a15bbaf3946094af65/tests/test_basic.py) · [drvpy workspace and flake options](https://github.com/drvlang/drvpy)
