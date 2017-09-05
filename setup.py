import versioneer

from setuptools import setup, find_packages

setup(
    name="sscid",
    version=versioneer.get_version(),
    cmdclass=versioneer.get_cmdclass(),
    packages=find_packages(exclude=["tests"]),
    include_package_data=True,
    install_requires=[
        "boto3",
        "flask",
        "GitPython"
    ],
    entry_points="""
        [console_scripts]
        sscid=sscid.sscid:main
    """,
    author="datawire.io",
    author_email="dev@datawire.io",
    url="https://github.com/datawire/sscid",
    download_url="https://github.com/datawire/sscid/tarball/{}".format(versioneer.get_version()),
    keywords=[],
    classifiers=[],
)
