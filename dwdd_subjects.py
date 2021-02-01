import csv
from dwdd_api import *


out_subjects = csv.writer(open("data/subjects.csv", "w"))
out_subjects.writerow(["programid", "schema", "subject"])


for program in csv.DictReader(open("data/meta.csv")):
    print(program["id"])
    metadata = get_metadata("programs", program["id"])
    #metadata = get_metadata("programs", l)
    if metadata['nisv.subjectterm']:
        for (subject) in metadata['nisv.subjectterm']:
            print(subject)
            out_subjects.writerow([program["id"], "subjectterm", subject[0]["value"]])
    if metadata['nisv.classification']:
        for (subject, age) in metadata['nisv.classification']:
            print(subject, age)
            out_subjects.writerow([program["id"], "classification", subject[0]["value"]])





