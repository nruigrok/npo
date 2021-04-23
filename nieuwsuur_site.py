import argparse
import csv
import json
import re
import sys
from pathlib import Path
from typing import Iterable

from lxml import html, etree
from amcatclient import AmcatAPI
import requests
from itertools import count
from datetime import datetime
import cssselect
import lxml
import logging
import locale
import sys
from requests import HTTPError


URL = "https://eenvandaag.avrotros.nl/actueel/#/page=2"
page = requests.get(URL)
page.raise_for_status()
tree = html.fromstring(page.text)
links = tree.cssselect(".is--ready")
print(links)
