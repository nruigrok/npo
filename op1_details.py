import csv
from op1_api import *

out = csv.writer(open("data/details_op1.csv", "w"))
out.writerow(["programid", "key", "value"])

program_ids = [program["id"] for program in csv.DictReader(open("data/meta_op1.csv"))]
#program_ids = ["urn:vme:default:program:2101608120101556931", "urn:vme:default:program:2101608120102681231"]
#i = program_ids.index("urn:vme:default:program:2101810220249767731")
#program_ids = program_ids[i:]

for i, program_id in enumerate(program_ids):
    print(f"{i}/{len(program_ids)}: {program_id}")
    metadata = get_metadata("programs", program_id)
    if 'nisv.guest' in metadata:
        if metadata['nisv.guest']:
            for (guest, role) in metadata['nisv.guest']:
                if "value" in guest:
                    out.writerow([program_id, "guest", guest["value"]])
    if 'nisv.subjectterm' in metadata:
        if metadata['nisv.subjectterm']:
            for subject in metadata['nisv.subjectterm']:
                out.writerow([program_id, "subjectterm", subject[0]["value"]])
    if 'nisv.classification' in metadata:
        if metadata['nisv.classification']:
            for (subject, age) in metadata['nisv.classification']:
                out.writerow([program_id, "classification", subject["value"]])
