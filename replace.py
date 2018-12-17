
# Replace words in .tex files

root = "test"
folders = ["MC", "TA", "be4", "SL"]
filenames = ["world_ew.tex", "world_vw.tex"]
old = "rank{\\textunderscore}var1"
new = "-zEMP"

def main():
	for folder in folders:
		for filename in filenames:
			path = root + "/" + folder + "/" + filename
			with open(path, 'r+') as f:
				t = f.read()
				t = t.replace(old, new)
				f.seek(0)
				f.write(t)
				f.truncate()

if __name__ == '__main__':
	main()
