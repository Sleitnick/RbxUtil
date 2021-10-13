from pathlib import Path
import re

force_name = {
	"pid": "PID"
}

def pretty_display_name(str: str):
	if str in force_name:
		return force_name[str]
	split = str.split("-")
	split = list(map(lambda s: s[0:1].upper() + s[1:], split))
	return "".join(split)

def build():
	readme = ["# RbxUtil\n", "| Module | Dependency | Description |", "| -- | -- | -- |"]
	name_pattern = re.compile(r"name\s*=\s*\"(.+)\"$")
	version_pattern = re.compile(r"version\s*=\s*\"(.+)\"$")
	deescription_pattern = re.compile(r"description\s*=\s*\"(.+)\"$")
	display_name_pattern = re.compile(r".+/(.+)")
	for path in Path("./modules").iterdir():
		with open(Path.joinpath(path, Path("wally.toml")), "r") as f:
			lines = f.read().splitlines()
			for line in lines:
				match_name = name_pattern.match(line)
				match_version = version_pattern.match(line)
				match_description = deescription_pattern.match(line)
				if match_name:
					name = match_name.group(1)
				elif match_version:
					version = match_version.group(1)
				elif match_description:
					description = match_description.group(1)
			match_display_name = display_name_pattern.match(name)
			display_name = pretty_display_name(match_display_name.group(1))
			dependency = f"{display_name} = \"{name}@{version}\""
			readme.append(f"| [{display_name}](https://sleitnick.github.io/RbxUtil/api/{display_name}) | `{dependency}` | {description} |")

	with open("README.md", "w") as readme_file:
		readme_file.write("\n".join(readme) + "\n")

if __name__ == "__main__":
	build()
	print("Readme built")
