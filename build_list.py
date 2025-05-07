from pathlib import Path
import json
import re


force_name = {
	"pid": "PID"
}

description_pattern = re.compile(r"description\s*=\s*\"(.+)\"$")


class WallyInfo:
	description: str = ""
	has_dependencies: bool = False


def pretty_display_name(str: str):
	if str in force_name:
		return force_name[str]
	split = str.split("-")
	split = list(map(lambda s: s[0:1].upper() + s[1:], split))
	return "".join(split)


def get_wally_info(path: Path) -> WallyInfo:
	info = WallyInfo()
	with open(Path.joinpath(path, Path("wally.toml")), "r") as f:
		lines = f.read().splitlines()
		for line in lines:
			match_description = description_pattern.match(line)
			if match_description:
				info.description = match_description.group(1)
			elif line == "[dependencies]":
				info.has_dependencies = True
	
	return info


def build():
	filelist = {
		"modules": [],
	}

	for path in sorted(Path("./modules").iterdir()):
		wally_info = get_wally_info(path)
		module = {
			"name": pretty_display_name(path.name),
			"description": wally_info.description,
			"has_dependencies": wally_info.has_dependencies,
			"path": "/".join(path.parts),
			"files": [],
		}
		for subpath in sorted(path.iterdir(), key=lambda p: p.name.lower()):
			if subpath.is_file() and subpath.name.endswith(".luau") and not subpath.name.endswith(".test.luau"):
				module["files"].append(subpath.name)
		filelist["modules"].append(module)

	json_str = json.dumps(filelist, indent=2)
	with open("filelist.json", "w", newline='\n') as filelist_file:
		filelist_file.write(json_str + "\n")

if __name__ == "__main__":
	build()
	print("List built")
