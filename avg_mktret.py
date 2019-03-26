
from sas7bdat import SAS7BDAT
import csv

NAME = "medianret"
IN_FILE = NAME + ".sas7bdat"
OUT_FILE = NAME + ".csv"

data = []


def main():

	with SAS7BDAT(IN_FILE) as f:
		raw = [row for row in f][1:]

	country = ""
	start = False
	for obs in raw:
		if obs[0] != country:
			start = False
			country = obs[0]
		if obs[-1] != None:
			start = True
		if start:
			data.append(obs)
		

	for i in range(len(data)):
		obs = data[i]
		if obs[-1] == None:
			pre = [x[-1] for x in data[:i] if x[0] == obs[0]]
			obs[-1] = sum(pre)/len(pre)


	with open(OUT_FILE, 'w', newline='') as csvfile:
		writer = csv.writer(csvfile)
		writer.writerow(['country', 'year', 'ret', 'ret2'])
		for obs in data:
			writer.writerow(obs)


if __name__ == '__main__':
	main()

	print(len(data))
	print(data[:8])