"""Run server behavior regressions with Luau and a minimal Roblox API stand-in."""
import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument("--luau", default="luau", help="Standalone Luau executable")
args = parser.parse_args()
binary = shutil.which(args.luau)
if not binary:
    raise SystemExit("Luau not found; pass --luau /path/to/luau")
root = Path(__file__).resolve().parents[1]
sources = sorted((root / "src/server").glob("*.luau")) + sorted((root / "src/shared").glob("*.luau"))
prefix = 'local Mock=require("./RobloxMock")\nlocal sources={}\n'
for path in sources:
    if path.name.startswith("init."):
        continue
    source = path.read_text()
    if "]====]" in source:
        raise SystemExit(f"Source delimiter collision: {path}")
    prefix += f'sources["{path.stem}"]=[====[\n{source}\n]====]\n'
test = (root / "tests/CombatRuntime.spec.luau").read_text()
suite = prefix + 'local env=Mock.environment(sources)\nlocal fn=assert(loadstring([====[\n' + test + '\n]====]))\nsetfenv(fn,env); fn()\n'
with tempfile.TemporaryDirectory(prefix="arena-tests-") as directory:
    folder = Path(directory)
    shutil.copyfile(root / "tests/RobloxMock.luau", folder / "RobloxMock.luau")
    (folder / "suite.luau").write_text(suite)
    subprocess.run([binary, str(folder / "suite.luau")], check=True)
