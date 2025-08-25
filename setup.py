"""Setup configuration for userprocessor package."""

from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="userprocessor",
    version="0.1.0",
    author="PyApp Template",
    author_email="example@example.com",
    description="A simple CSV processor using pandas and tabulate",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/example/userprocessor",
    packages=find_packages(),
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires=">=3.8",
    install_requires=[
        "pandas>=1.0.0",
        "tabulate>=0.8.0",
    ],
    entry_points={
        "console_scripts": [
            "userprocessor=userprocessor.__main__:main",
        ],
    },
    include_package_data=True,
    package_data={
        "userprocessor": ["*.csv"],
    },
)
