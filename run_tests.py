import argparse
import requests
import json
import os
import time


def run_tests():
	parser = argparse.ArgumentParser("RunTests")
	parser.add_argument("uid", help="Universe ID", type=int)
	parser.add_argument("pid", help="Place ID", type=int)
	args = parser.parse_args()
	
	uid = args.uid
	pid = args.pid

	post_endpoint = f"https://apis.roblox.com/cloud/v2/universes/{uid}/places/{pid}/luau-execution-session-tasks"

	with open("ci/RunTests.luau", "r") as script:
		script_source = script.read()

	data = {
		"script": script_source,
	}

	headers = {
		"Content-Type": "application/json",
		"x-api-key": os.getenv("API_KEY"),
	}

	res = requests.post(post_endpoint, data=json.dumps(data), headers=headers)
	res_json = res.json()

	get_endpoint = f"https://apis.roblox.com/cloud/v2/{res_json['path']}?view=BASIC" # view can be BASIC or FULL

	last_state = ""
	while True:
		res = requests.get(get_endpoint, headers={"x-api-key": os.getenv("API_KEY")})
		res_json = res.json()
		state = res_json["state"]
		if state != last_state:
			print(f"State changed: {state}")
			last_state = state
		if state == "CANCELLED":
			exit(1)
		elif state == "COMPLETE":
			break
		elif state == "FAILED":
			print(res_json["error"])
			exit(1)
		else:
			time.sleep(2)

	print("Completed")


if __name__ == "__main__":
	run_tests()
