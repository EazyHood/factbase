import json, os, pathlib, subprocess
root = pathlib.Path(os.environ['GITHUB_WORKSPACE']) / '.github/validation'
issue = os.environ['ISSUE']
subprocess.run(['git', 'apply', str(root / (issue + '.patch'))], check=True)
files = subprocess.check_output(['git', 'diff', '--name-only'], text=True).splitlines()
subprocess.run(['bundle', 'exec', 'rubocop', *files], check=True)
subprocess.run(['bundle', 'exec', 'rake', 'test'], check=True)
for filename, before, after, test in json.loads((root / 'mutations.json').read_text())[issue]:
    path = pathlib.Path(filename)
    original = path.read_text()
    assert original.count(before) == 1, (filename, before)
    path.write_text(original.replace(before, after))
    try:
        result = subprocess.run(['bundle', 'exec', 'ruby', test], env={**os.environ, 'PICKS':'yes'})
        assert result.returncode != 0, ('Mutation survived', filename, before)
        print('DETECTED MUTATION', filename, before, flush=True)
    finally:
        path.write_text(original)
