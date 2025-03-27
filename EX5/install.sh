#!/bin/bash

python3 -m venv myenv

source myenv/bin/activate

pip install setuptools

cd pyfim

python3 setup_fim.py install

echo "PyFIM package installed successfully in virtual environment."
echo "To use the package, activate the environment with:"
echo "source myenv/bin/activate"
