import argparse
import logging
import random
import csv
import tempfile

from googleapiclient.discovery import build
from oauth2client import file, client, tools
from pathlib import Path
import httplib2
from random import sample

SCOPES = ['https://www.googleapis.com/auth/spreadsheets.readonly']
SHEET_ID = "1ZNEtC4L1Ttyn18d-eboixPMNgT3j6cho_4UZuFxohXk"

client_secret = '''{"installed":{
      "client_id":"298285884184-4pijg18ufms0kvklug1el2o7b5tqltgs.apps.googleusercontent.com",
      "project_id":"talkshows-329811",
      "auth_uri":"https://accounts.google.com/o/oauth2/auth",
      "token_uri":"https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs",
      "client_secret":"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",
      "redirect_uris":["urn:ietf:wg:oauth:2.0:oob", "http://localhost"]
   }}'''

def get_google_service(client_secret, filename, scope, *api):
    storage = file.Storage(Path.cwd() / filename)
    credentials = storage.get()
    if credentials is None or credentials.invalid:
        # Write credentials to temporary file, rewind, and start auth flow
        with tempfile.NamedTemporaryFile(suffix=".json", mode="w") as f:
            f.write(client_secret)
            f.seek(0)
            flow = client.flow_from_clientsecrets(f.name, scope=scope, message="Invalid credentials")
            flags = argparse.ArgumentParser(parents=[tools.argparser]).parse_args([])
            credentials = tools.run_flow(flow, storage, flags)
    http = credentials.authorize(http=httplib2.Http())
    return build(*api, http=http)

def get_words(sheet):
    sheet_range = f"{sheet}!A:B"
    service = get_google_service(client_secret, "googlesheets.dat", SCOPES, "sheets", "v4")
    result = service.spreadsheets().values().get(spreadsheetId=SHEET_ID, range=sheet_range).execute()
    return {nl: it for (nl, it) in result['values'][1:]}


def start_game(sheet):
    answer = input("play game? ('y' to continue)")
    print(" ")
    while answer == 'y':
        vocabDictionary = get_words(sheet)
        keyword_list = list(vocabDictionary.keys())
        keyword_list2 = sample(keyword_list, 4)
        random.shuffle(keyword_list2)
        correct = 0
        wrong = 0
        for keyword in keyword_list2:
            display = "{}"
            print(display.format(keyword))
            userInputAnswer = input("ANSWER: ")
            print(vocabDictionary[keyword])
            print(" ")

            if userInputAnswer == (vocabDictionary[keyword]):
                print("CORRECT")
                correct += 1
            else:
                print("WRONG")
                wrong +=1

            print("_"*25)

        display = "SCORE: {} correct and {} wrong"
        print(display.format(correct, wrong))
        answer = input("Play again? ('y' to continue) ")
    print(" ")
    print("Thanks for playing")


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO, format='[%(asctime)s %(name)-12s %(levelname)-5s] %(message)s')
    parser = argparse.ArgumentParser()
    parser.add_argument("sheet", help="Sheet to ask", )
    args = parser.parse_args()
    start_game(args.sheet)