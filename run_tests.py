import argparse
import requests
import json
import os


def run_tests():
	parser = argparse.ArgumentParser("RunTests")
	parser.add_argument("uid", help="Universe ID", type=int)
	parser.add_argument("pid", help="Place ID", type=int)
	args = parser.parse_args()
	
	uid = args.uid
	pid = args.pid

	endpoint = f"https://apis.roblox.com/cloud/v2/universes/{uid}/places/{pid}/luau-execution-session-tasks"

	with open("ci/RunTests.luau", "r") as script:
		script_source = script.read()

	data = {
		"script": script_source,
	}

	headers = {
		"Content-Type": "application/json",
		"x-api-key": os.getenv("API_KEY"),
	}

	res = requests.post(endpoint, data=data, headers=headers)
	res_json = res.json()

	print(res_json)


if __name__ == "__main__":
	run_tests()
