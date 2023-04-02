from amcatclient import AmcatAPI
from amcat.models import Article,Project, CodingJob, CodingSchemaField, ArticleSet
import sys, datetime, csv

fromid = int(sys.argv[1])

set = list(ArticleSet.objects.get(pk=3303))
print(set)
