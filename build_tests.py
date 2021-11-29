import subprocess
from pathlib import Path
from shutil import copytree, rmtree, move
import os
import time
from watchdog.observers import Observer
from watchdog.events import PatternMatchingEventHandler
from threading import Timer

force_name = {
	"pid": "PID"
}

files_locked = {}

def update_test_file(test_path, original_src_path):
	if test_path.is_file():
		print(f"Updated {str(test_path)}")
		with open(test_path, "w") as test_file:
			with open(original_src_path, "r") as src_file:
				test_file.write(src_file.read())
	del files_locked[original_src_path]

class WatchHandler(PatternMatchingEventHandler):
	def __init__(self):
		PatternMatchingEventHandler.__init__(self, patterns=["*.lua"], ignore_directories=True, case_sensitive=False)
	def on_modified(self, event):
		original_src_path = event.src_path
		if original_src_path in files_locked:
			return
		files_locked[original_src_path] = True
		src_path = Path(original_src_path).relative_to("modules")
		module_name = src_path.parent.name
		test_path = Path.joinpath(Path("test/modules"), module_name + "_test", src_path)
		t = Timer(0.1, update_test_file, [test_path, original_src_path])
		t.start()

def pretty_display_name(str: str):
	if str in force_name:
		return force_name[str]
	split = str.split("-")
	split = list(map(lambda s: s[0:1].upper() + s[1:], split))
	return "".join(split)

def build_tests():
	rmtree("./test/modules", ignore_errors=True)
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
	print("Watching for changes...")

	observer = Observer()
	observer.schedule(WatchHandler(), "./modules", recursive=True)
	observer.start()
	
	try:
		while True:
			time.sleep(1)
	except KeyboardInterrupt:
		observer.stop()
	finally:
		observer.join()

	print("Stopped")
