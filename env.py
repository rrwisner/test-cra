from dotenv import dotenv_values
from pathlib import Path
import json
import os
import yaml
import subprocess


# Helper functions

def get_git_revision_hash():
    return subprocess.check_output(['git', 'rev-parse', 'HEAD'])

def get_git_revision_short_hash():
    return subprocess.check_output(['git', 'rev-parse', '--short', 'HEAD'])

# Get ROOT_DIR, make sure s3 folder exists

ROOT_DIR = Path(__file__).resolve(strict=True).parent
os.makedirs("{}/s3".format(ROOT_DIR), exist_ok=True)

# Read .env file and get variables

config = dotenv_values(".env")

environment = {}
for key in config:
    environment[key] = config[key]

print("===========================")
print(environment)

# Read yaml files and get variables

fileObject = open("yaml/sandbox.yaml", "r")
data = yaml.load(fileObject.read(), Loader=yaml.CLoader)

print("===========================")
print(data)

# Update environment variables based on yaml variables

for key in environment:
    for item in data:
        if key == item:
            environment[key] = data[item]

print("===========================")
print(environment)

# Write updated environment variables to config.js

f = open('s3/config.js', 'w')
f.write("window._env_ = window._env_ || {};\n")

for key in environment:
    line = "window._env_.{} = '{}';\n".format(key, environment[key])
    f.write(line)

f.close()

# Read commit reference

with open("ref", "r") as fileObject:
    commit = next(fileObject)

# Update cloudfront distribution-config

fileObject = open('distribution-config.json', 'r')
distribution_config = json.load(fileObject)
fileObject.close()

if "DistributionConfig" in distribution_config:

    distribution_config = distribution_config["DistributionConfig"]

    for item in distribution_config["Origins"]["Items"]:
        item["OriginPath"] = "sandbox/{}".format(commit)

    with open("distribution-config.json", "w") as fileObject:
        json.dump(distribution_config, fileObject, indent=4)

print("===========================")
print("Done")
