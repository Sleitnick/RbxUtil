import argparse
import requests
import json
import os
import time


# Seconds between status polling
POLL_STATUS_INTERVAL = 3

ROOT_API = "https://apis.roblox.com/cloud/v2"
RUNNER_SCRIPT = "ci/RunTests.luau"


def run_script(script_path: str, api_key: str, universe_id: int, place_id: int):
	with open(script_path, "r") as script:
		script_source = script.read()

	data = {
		"script": script_source,
	}
	headers = {
		"Content-Type": "application/json",
		"x-api-key": api_key,
	}

	run_script_url = f"{ROOT_API}/universes/{universe_id}/places/{place_id}/luau-execution-session-tasks"

	res = requests.post(run_script_url, data=json.dumps(data), headers=headers)
	res.raise_for_status()
	res_json = res.json()

	get_status_url = f"{ROOT_API}/{res_json['path']}?view=BASIC" # view can be BASIC or FULL

	return get_status_url


def get_script_status(get_status_url: str, api_key: str):
	res = requests.get(get_status_url, headers={"x-api-key": api_key})
	res.raise_for_status()
	res_json = res.json()

	return res_json


def await_script_completion(get_status_url: str, api_key: str, timeout: float):
	start = time.time()

	last_state = ""
	data = None
	while True:
		data = get_script_status(get_status_url, api_key)

		state = data["state"]
		if state != last_state:
			print(f"State changed: {state}")
			last_state = state
		
		if state == "COMPLETE" or state == "FAILED" or state == "CANCELLED":
			break
		
		# Timeout condition:
		if time.time() - start > timeout:
			print("timeout")
			exit(1)

		time.sleep(POLL_STATUS_INTERVAL)
	
	return data


def run_tests():
	parser = argparse.ArgumentParser("RunTests")
	parser.add_argument("uid", help="Universe ID", type=int)
	parser.add_argument("pid", help="Place ID", type=int)
	args = parser.parse_args()

	api_key = os.getenv("API_KEY")

	get_status_url = run_script(RUNNER_SCRIPT, api_key, args.uid, args.pid)

	data = await_script_completion(get_status_url, api_key, 60)

	match data["state"]:
		case "COMPLETE":
			result = data["output"]["results"][0]
			all_pass = result["AllPass"]

			print(result["Output"])

			if not all_pass:
				exit(1)

		case "FAILED":
			print(data["error"])
			exit(1)

		case "CANCELLED":
			print("Cancelled")
			exit(1)

	print("All tests passed")


if __name__ == "__main__":
	run_tests()
