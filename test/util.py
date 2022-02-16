import difflib

def assert_diff(src: list[str], target: list[str]):
    for line in difflib.unified_diff(src, target,
                                     fromfile='a', tofile='b'):
        print(line)
    return src == target
