import subprocess
from pathlib import Path
from shutil import copytree, rmtree, move
import os

force_name = {
	"pid": "PID"
}

def pretty_display_name(str: str):
	if str in force_name:
		return force_name[str]
	split = str.split("-")
	split = list(map(lambda s: s[0:1].upper() + s[1:], split))
	return "".join(split)

def build_tests():
	rmtree("./test/modules")
	copytree("./modules", "./test/modules", dirs_exist_ok=True)
	for path in Path("./test/modules").iterdir():
		print("\n" + pretty_display_name(path.name))
		test_dir = Path(str(path) + "_test")
		os.mkdir(test_dir)
		move(path, test_dir)
		new_path = Path.joinpath(test_dir, path.name)
		subprocess.run(["wally", "install"], check=True, cwd=new_path)
		packages = Path.joinpath(new_path, "Packages")
		if Path.is_dir(packages):
			for package_item_path in packages.iterdir():
				move(package_item_path, Path.joinpath(test_dir, package_item_path.name))
			rmtree(packages)
		else:
			print("[NO DEPENDENCIES]")
	subprocess.run(["wally", "install"], check=True, cwd="test")

if __name__ == "__main__":
	print("Building tests...")
	build_tests()
	print("\nTests built")
