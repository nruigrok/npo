for PAGE in {1..50}; do
    echo $PAGE
    #curl "https://www.npostart.nl/media/series/POW_04596562/episodes?page=$PAGE&tileMapping=dedicated&tileType=asset&pageType=franchise" -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:84.0) Gecko/20100101 Firefox/84.0' -H 'Accept: */*' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'X-XSRF-TOKEN: eyJpdiI6ImNKZkJaVVRDSkVEbnpraGJPaHkyOVE9PSIsInZhbHVlIjoiT3BGNkxwNlF2RHl2SlJtaVFuMENFM0xicDkzT0JPK3kxMzJZWGlZQjFYOUdER3NacTJzQmN4MjRLd2xMaXF1KyIsIm1hYyI6IjI3ZDVhMzM5ZGM0YjZiNTBhNjgzYWRmOWJkMTU4NDVmMjkzYzFkYjU2M2RjYTMyOGYxYTVlZWE1MDlhNjkxY2MifQ==' -H 'X-Requested-With: XMLHttpRequest' -H 'Connection: keep-alive' -H 'Referer: https://www.npostart.nl/op1/POW_04596562' -H 'Cookie: XSRF-TOKEN=eyJpdiI6IkhvOFNpQVZsTER1c3ZOSGhENWVnc2c9PSIsInZhbHVlIjoiOXVKeHJqRW04UkM2TFU2cks0QitVVjlQVmJubjZ4NHp4Q1gzUERpTGZjNFFUZjJTXC9odFUzcnBFZnJhVW5qXC9iIiwibWFjIjoiNDY3OGMzMmE2ZDE2NjQ1Y2M5OTU0Y2UxOTI3NjJkOTNjZTgxYjE4YzAyYjFlYWZlNGY0OWE4Y2IxYzU4MDNmOCJ9; npo_session=eyJpdiI6InNQZ3ROckJ1YmRETENxTUJLSzM0bEE9PSIsInZhbHVlIjoiazJKU0ZVbGY0NGZiYjh5Q25PU05VSnVIVnFJNUhDditRWVphNk1MTjJIbHhtMWpVcHh0cmlxTEkxOU9HbjRcL24iLCJtYWMiOiJiNWRiMTMzZGI4Zjc1MTM0OGMzMmZlZmY2YmEzN2JjNDMyMjUwNzZhNDU0YzYxYjJhMTI3N2Q4NjU5NGVlODVlIn0%3D; Cookie_Consent=Tue Oct 06 2020 13:33:56 GMT+0200 (Central European Summer Time); CCM_ID=fn6Tm6dPQ2gzMg==; Cookie_Category_Necessary=true; Cookie_Category_Analytics=true; atidvisitor=%7B%22name%22%3A%22atidvisitor%22%2C%22val%22%3A%7B%22vrn%22%3A%22-595271-%22%2C%22ac%22%3A%223%22%7D%2C%22options%22%3A%7B%22path%22%3A%22%2F%22%2C%22session%22%3A15724800%2C%22end%22%3A15724800%7D%7D; atuserid=%7B%22name%22%3A%22atuserid%22%2C%22val%22%3A%226428fbc5-18e4-485b-9cca-d96024af92ba%22%2C%22options%22%3A%7B%22end%22%3A%222021-11-07T11%3A33%3A38.556Z%22%2C%22path%22%3A%22%2F%22%7D%7D; _dvp=0:kfxvx7r8:akyFupPvmjJb9RQkRf1l_T_7NCCwOpKb; __cfduid=d65048a5a1fdf9caf83f5b76421b89c091610122798; subscription=npoplus; atkantarsession=%7B%22name%22%3A%22atkantarsession%22%2C%22val%22%3A%22session_in_progress%22%2C%22options%22%3A%7B%22expiration%22%3A1800%2C%22path%22%3A%22%2F%22%7D%7D; CCM_Wrapper_Cache=eyJ2ZXIiOiJ2My4xLjEwIiwianNoIjoiIiwiY2lkIjoiZm42VG02ZFBRMmd6TWc9PSIsImNvbmlkIjoib2p1eTUifQ==; _dvs=0:kkpz1n3q:T5Le1dJk9RhNi1S8X9yTHdjoCo2kXAK~' -H 'TE: Trailers' > op1_2021_$PAGE.json
    #curl "https://www.npostart.nl/media/series/POW_03333061/episodes?page=$PAGE&tileMapping=dedicated&tileType=asset&pageType=franchise" -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:85.0) Gecko/20100101 Firefox/85.0' -H 'Accept: */*' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'X-XSRF-TOKEN: eyJpdiI6IjdLVFhKMFpMZ21uQUszdkRhdnQrbXc9PSIsInZhbHVlIjoibGtcL2F3Uit0VkcyZGkxY0t5V21CWFpsUjdBaWR2dmtXZ0cxTFhqcFhucjlhSmpSa0JyaGdqelllN3hiVHY0K28iLCJtYWMiOiJjNzAzNDllZjRjYzYyOGY2ZjMyM2U0YTE4MWI4NzlhYTAzNjU5N2FlNzNiZTY4YTI0NzcxNjQ3ODE5NGRlNDQ0In0=' -H 'X-Requested-With: XMLHttpRequest' -H 'Connection: keep-alive' -H 'Referer: https://www.npostart.nl/goedemorgen-nederland/POW_03333061' -H 'Cookie: XSRF-TOKEN=eyJpdiI6InN5QXFUWEExWFROTTUzWGhkSjc1c3c9PSIsInZhbHVlIjoiemhYM0s2eHp6Nk9pNUZZdmtRZnV6WkZ3VjlxRGI0XC9XSFdZSDdRSVNQSldpSG9tREs5NmtWSU9URkt4alwvU3hUIiwibWFjIjoiMTVjZGRhYWIwOTQ3YWE0YjVjZDdjMDYwN2Y5YWU5NjhhM2E5ZDk1MjcwYzIwMGI2YWJmMGJmNWJhYTdjZDMxNCJ9; npo_session=eyJpdiI6ImMyejBmblNRTUtNcmdjXC9Qd0V1TGxRPT0iLCJ2YWx1ZSI6IjhTb0Y4R25vcjZUQk14UlI4clllYXJcL0J3S1dTMzVMT0dFcVFIRXZKcDZucDJWSUI0T0FZV1wvOUVRNTN2NjBBeSIsIm1hYyI6IjkxMzg2OGI1MWQ0MTRlMWUyNzg1MjEyMGM2Y2M0NDljMTk4MjI2ZmVjMWQxNjQzNmVkZTBmNGU5NGY1NjA4ZTIifQ%3D%3D; Cookie_Consent=Tue Oct 06 2020 13:33:56 GMT+0200 (Central European Summer Time); CCM_ID=fn6Tm6dPQ2gzMg==; Cookie_Category_Necessary=true; Cookie_Category_Analytics=true; atidvisitor=%7B%22name%22%3A%22atidvisitor%22%2C%22val%22%3A%7B%22vrn%22%3A%22-595271-%22%2C%22ac%22%3A%223%22%7D%2C%22options%22%3A%7B%22path%22%3A%22%2F%22%2C%22session%22%3A15724800%2C%22end%22%3A15724800%7D%7D; atuserid=%7B%22name%22%3A%22atuserid%22%2C%22val%22%3A%226428fbc5-18e4-485b-9cca-d96024af92ba%22%2C%22options%22%3A%7B%22end%22%3A%222021-11-07T11%3A33%3A38.556Z%22%2C%22path%22%3A%22%2F%22%7D%7D; _dvp=0:kfxvx7r8:akyFupPvmjJb9RQkRf1l_T_7NCCwOpKb; __cfduid=da250b154e8ace5a9d5c45b704dc3b09d1613318893; atkantarsession=%7B%22name%22%3A%22atkantarsession%22%2C%22val%22%3A%22session_in_progress%22%2C%22options%22%3A%7B%22expiration%22%3A1800%2C%22path%22%3A%22%2F%22%7D%7D; atkantarid=%7B%22name%22%3A%22atkantarid%22%2C%22val%22%3A%7B%7D%2C%22options%22%3A%7B%22end%22%3A604800%2C%22path%22%3A%22%2F%22%7D%7D' > goedemorgen_$PAGE.json
    #curl "https://www.npostart.nl/media/series/VARA_101377717/episodes?page=$PAGE&tileMapping=dedicated&tileType=asset&pageType=franchise" -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:85.0) Gecko/20100101 Firefox/85.0' -H 'Accept: */*' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'X-XSRF-TOKEN: eyJpdiI6IkNUYVdsbHpyWEhxRHo4T25UZjVUUVE9PSIsInZhbHVlIjoibjZhcHlOMjJKbmJkdmNyTTcxd1wvMDJ2eWV0eFpkSEhcL1wvN2xMajlUUlRjVmJDdUdXVTJ4U3k4bW9DQzRNc3dhZyIsIm1hYyI6ImY0MGFlOGY5YjViMTk4NWQ4NDY5ZDNkYTdhOWVkYjRjYzBjYjMwYzliODIxYjQ4Y2NmNDEyYWQxNjk3ZmExYjEifQ==' -H 'X-Requested-With: XMLHttpRequest' -H 'Connection: keep-alive' -H 'Referer: https://www.npostart.nl/de-wereld-draait-door/VARA_101377717/episode' -H 'Cookie: XSRF-TOKEN=eyJpdiI6IkNBVEZLSGdEXC9IMGZ5b3NNUkM4bXBBPT0iLCJ2YWx1ZSI6IlwvYUNabUMyVno1WlJpZkV1WXZDSEVQbElmUDNhSGdrVUR1amRqZzNzdEFWanpmVzRsclwvNmJXZnVpakJcL1Y4M1oiLCJtYWMiOiIzOGEwNThhMDcyOWNkZDQ4MWU4ZWRjMjI5ODRjNWQ4OTFkNWY1NWRiMzE5ZTFhZDEwODM5NjQ4ZmE1NWM0ZDBjIn0%3D; npo_session=eyJpdiI6Ik10Y2kzV1hzUlFBcHNJOWpRVElPOWc9PSIsInZhbHVlIjoiVE9wem9SYm1rK1NSS3dpNHdmOWN3ZzZkd1ZSQ3grMmRTZEtBSE9pZWczcjRBXC9vOFBRSVwvb1p4bFBqbHZPbUpvIiwibWFjIjoiOWUyOTI0YTc1NGRjYWUwNTlkMzRmMjQ1YjVlYWNkY2U4ODc1ZmU4ZDVmZTIyNmNiNDBmY2JmMDJhYTM5OGZlMyJ9; Cookie_Consent=Tue Oct 06 2020 13:33:56 GMT+0200 (Central European Summer Time); CCM_ID=fn6Tm6dPQ2gzMg==; Cookie_Category_Necessary=true; Cookie_Category_Analytics=true; atidvisitor=%7B%22name%22%3A%22atidvisitor%22%2C%22val%22%3A%7B%22vrn%22%3A%22-595271-%22%2C%22ac%22%3A%223%22%7D%2C%22options%22%3A%7B%22path%22%3A%22%2F%22%2C%22session%22%3A15724800%2C%22end%22%3A15724800%7D%7D; atuserid=%7B%22name%22%3A%22atuserid%22%2C%22val%22%3A%226428fbc5-18e4-485b-9cca-d96024af92ba%22%2C%22options%22%3A%7B%22end%22%3A%222021-11-07T11%3A33%3A38.556Z%22%2C%22path%22%3A%22%2F%22%7D%7D; _dvp=0:kfxvx7r8:akyFupPvmjJb9RQkRf1l_T_7NCCwOpKb; __cfduid=da250b154e8ace5a9d5c45b704dc3b09d1613318893; atkantarsession=%7B%22name%22%3A%22atkantarsession%22%2C%22val%22%3A%22session_in_progress%22%2C%22options%22%3A%7B%22expiration%22%3A1800%2C%22path%22%3A%22%2F%22%7D%7D; atkantarid=%7B%22name%22%3A%22atkantarid%22%2C%22val%22%3A%7B%7D%2C%22options%22%3A%7B%22end%22%3A604800%2C%22path%22%3A%22%2F%22%7D%7D; CCM_Wrapper_Cache=eyJ2ZXIiOiJ2My4xLjEwIiwianNoIjoiIiwiY2lkIjoiZm42VG02ZFBRMmd6TWc9PSIsImNvbmlkIjoib2p1eTUifQ==; _dvs=0:kl80uhti:SzmUHYb3XyqqfgpQKMJ6hJtnpbL1V5p1' -H 'TE: Trailers' > dwdd_$PAGE.json
    #curl 'https://www.npostart.nl/media/series/BV_101401602/episodes?page=$PAGE&seasonId=BV_101401603&tileMapping=dedicated&tileType=asset&pageType=franchise' -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:85.0) Gecko/20100101 Firefox/85.0' -H 'Accept: */*' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'X-XSRF-TOKEN: eyJpdiI6ImIzSEpmVU1EWVhtQ09WOXdXZHozM2c9PSIsInZhbHVlIjoibjN2MjFyVWM1UHZXM0N1MUxMUlJocE55cDNlb0JWOEU4ZXExZkZxc1VLTWRKMlNIRlJwZUpEamRnK0RwMlV3aCIsIm1hYyI6IjZkYmQzNDI5YTExZWVmYWNiNDNlZTY5NjkyM2JmNTIwYjdhM2FkOTlkMjFmODBlNTkzYjRmZDc2YWRiNmMzNTUifQ==' -H 'X-Requested-With: XMLHttpRequest' -H 'Connection: keep-alive' -H 'Referer: https://www.npostart.nl/de-vooravond/BV_101401602' -H 'Cookie: XSRF-TOKEN=eyJpdiI6IlFTQmVaM2FCY25veDVyTXc3bHlaUkE9PSIsInZhbHVlIjoieTRpcWw2ODNlc1wvN3dqdFFiNk90aFZFT2t5NjFlWnRCVVlidktKQnBySVwvUGhEVnNWUmxoZ21NODlOdUY4NmxCIiwibWFjIjoiMWFlZDBlOWNlZTA4MzAzZDg5OWJlMDVjZGU0Yzc0NzcyMDQxMDliZTBhYzlmMTQ3NjhhMjM0MjI4OWQ3NzJjOSJ9; npo_session=eyJpdiI6InU5OUZZSGF1NU9Qekk2dFBZa1JTZ3c9PSIsInZhbHVlIjoiTkhGaDdDbGFpXC9xdkdkVDdBQWM0RXUrb3lDbVNQNnd0MnhoR0dzRDNRMjVuUkhnTnlHbXpzdHRyVXFSV1hGM2wiLCJtYWMiOiI4YzkzMjY1MTNkYzlhZTk3M2JlNTRlYTlhOTdlNzQ1ODVkNDQxNzFiZmExMTk1ODViOTQwYjVmODA3ZjU2MzZiIn0%3D; Cookie_Consent=Tue Oct 06 2020 13:33:56 GMT+0200 (Central European Summer Time); CCM_ID=fn6Tm6dPQ2gzMg==; Cookie_Category_Necessary=true; Cookie_Category_Analytics=true; atidvisitor=%7B%22name%22%3A%22atidvisitor%22%2C%22val%22%3A%7B%22vrn%22%3A%22-595271-%22%2C%22ac%22%3A%223%22%7D%2C%22options%22%3A%7B%22path%22%3A%22%2F%22%2C%22session%22%3A15724800%2C%22end%22%3A15724800%7D%7D; atuserid=%7B%22name%22%3A%22atuserid%22%2C%22val%22%3A%226428fbc5-18e4-485b-9cca-d96024af92ba%22%2C%22options%22%3A%7B%22end%22%3A%222021-11-07T11%3A33%3A38.556Z%22%2C%22path%22%3A%22%2F%22%7D%7D; _dvp=0:kfxvx7r8:akyFupPvmjJb9RQkRf1l_T_7NCCwOpKb; __cfduid=da250b154e8ace5a9d5c45b704dc3b09d1613318893; atkantarsession=%7B%22name%22%3A%22atkantarsession%22%2C%22val%22%3A%22session_in_progress%22%2C%22options%22%3A%7B%22expiration%22%3A1800%2C%22path%22%3A%22%2F%22%7D%7D; atkantarid=%7B%22name%22%3A%22atkantarid%22%2C%22val%22%3A%7B%7D%2C%22options%22%3A%7B%22end%22%3A604800%2C%22path%22%3A%22%2F%22%7D%7D; _dvs=0:kl80uhti:SzmUHYb3XyqqfgpQKMJ6hJtnpbL1V5p1; CCM_Wrapper_Cache=eyJ2ZXIiOiJ2My4xLjEwIiwianNoIjoiIiwiY2lkIjoiZm42VG02ZFBRMmd6TWc9PSIsImNvbmlkIjoib2p1eTUifQ==' -H 'TE: Trailers' -H 'If-None-Match: W/"d791c6d4d910d8c0b447a9c922bd0554"' > vooravond2020_$PAGE.json
    #curl 'https://www.npostart.nl/media/series/BV_101401602/episodes?seasonId=BV_101404632&tileMapping=dedicated&tileType=asset&pageType=franchise' -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:86.0) Gecko/20100101 Firefox/86.0' -H 'Accept: */*' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'X-XSRF-TOKEN: eyJpdiI6IlJpb245aWJCb0ZUZHVNamF4KytjUUE9PSIsInZhbHVlIjoiTFBack9QS01Jdm9udXEwYWZXclBzbFBBZnlncUNkdkROdFwvaEk2ZzdiMGgzQlwvaXJ5MzNCN05XemFlTGJkT0JjIiwibWFjIjoiZDk4ODQ0Y2ExYjQyN2I2ZDcwMjJmOTVjYWEwNGU5YmEwYmVhYmI1NTNmZjdkZjkyOTBiMGFmNzYzOGJlMTcxNyJ9' -H 'X-Requested-With: XMLHttpRequest' -H 'Connection: keep-alive' -H 'Referer: https://www.npostart.nl/de-vooravond/BV_101401602' -H 'Cookie: XSRF-TOKEN=eyJpdiI6IjlIZG51NVo3VVk1b1RzV2E4T1N1cFE9PSIsInZhbHVlIjoiK0NOTzdrakZzU1JvZjBBSGNzWVhcL2Z1bktNOStBVTBucEppY1FiaXdFTGpaMGdjUWFLK2VWVG1IdHhlajdLMHciLCJtYWMiOiJkMGRjOTcwOWRjMmZkMjk5YjY4NWMwYThiNjA2Yzc5YmExODk2OGI3Y2FiNTYyMDY5NDM1NmJkMWFlY2ViYmU3In0%3D; npo_session=eyJpdiI6IlpWR3Z5VXFSQ2p4VGR0eGZ3SHNDUVE9PSIsInZhbHVlIjoiWUpkVFJ1R1VWdlVcL3NmMCtcL2lXVko1Q04rSXMwaDdSVlZndHh6UjEwcUluK0RkUGdjTVowK0VETFg1TnBxWElHIiwibWFjIjoiMmUyMGEyNTNmMjg3NTY1OGI4N2VhODUyMGMzMWI5M2ZmMGVmNzk1Yzg0NTM0MjUzMjc0Mzc2ZDM3YTZhYzY2MiJ9; Cookie_Consent=Tue Oct 06 2020 13:33:56 GMT+0200 (Central European Summer Time); CCM_ID=fn6Tm6dPQ2gzMg==; Cookie_Category_Necessary=true; Cookie_Category_Analytics=true; atidvisitor=%7B%22name%22%3A%22atidvisitor%22%2C%22val%22%3A%7B%22vrn%22%3A%22-595271-%22%2C%22ac%22%3A%223%22%7D%2C%22options%22%3A%7B%22path%22%3A%22%2F%22%2C%22session%22%3A15724800%2C%22end%22%3A15724800%7D%7D; atuserid=%7B%22name%22%3A%22atuserid%22%2C%22val%22%3A%226428fbc5-18e4-485b-9cca-d96024af92ba%22%2C%22options%22%3A%7B%22end%22%3A%222021-11-07T11%3A33%3A38.556Z%22%2C%22path%22%3A%22%2F%22%7D%7D; _dvp=0:kfxvx7r8:akyFupPvmjJb9RQkRf1l_T_7NCCwOpKb; __cfduid=da250b154e8ace5a9d5c45b704dc3b09d1613318893; atkantarid=%7B%22name%22%3A%22atkantarid%22%2C%22val%22%3A%7B%7D%2C%22options%22%3A%7B%22end%22%3A604800%2C%22path%22%3A%22%2F%22%7D%7D; atkantarsession=%7B%22name%22%3A%22atkantarsession%22%2C%22val%22%3A%22session_in_progress%22%2C%22options%22%3A%7B%22expiration%22%3A1800%2C%22path%22%3A%22%2F%22%7D%7D; CCM_Wrapper_Cache=eyJ2ZXIiOiJ2My4xLjEwIiwianNoIjoiIiwiY2lkIjoiZm42VG02ZFBRMmd6TWc9PSIsImNvbmlkIjoib2p1eTUifQ==; _dvs=0:klnltwup:g4~F1z6ApZdPBHvifaeZitVXrf6NEsIN' -H 'If-None-Match: W/"fa37e76efb9c97630176b7914ce4dc84"' -H 'TE: Trailers' > vooravond_1b.json
    #curl "https://www.npostart.nl/media/series/KN_1699061/episodes?page=$PAGE&tileMapping=dedicated&tileType=asset&pageType=franchise" -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:85.0) Gecko/20100101 Firefox/85.0' -H 'Accept: */*' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'X-XSRF-TOKEN: eyJpdiI6ImFUVHVhVG1lQ3pzdE53YUZlNUxMXC9BPT0iLCJ2YWx1ZSI6Im9BeEZPNUFIbnE3MXEwTE1YMzcrMEV1d3RqTDdGYzdxcnFCQ1hRMVA5cnJJTHdMdWlUVkxpV1wvTVJERXJ4bklOIiwibWFjIjoiMzlkNGJiNjMwNWE3ZjBiMmRlMzY1MjQzNGE4OTdlOTYyYmYyOTJhYzhhOTNiYjdjYTk4YTVhNWM3MWI4MGRlZSJ9' -H 'X-Requested-With: XMLHttpRequest' -H 'Connection: keep-alive' -H 'Referer: https://www.npostart.nl/m/KN_1699061' -H 'Cookie: XSRF-TOKEN=eyJpdiI6Ikg4N010eFArYmFvRXYrNXk4VHdkUnc9PSIsInZhbHVlIjoiSDZTZ2tyYnRUclJ0aktXVUYyMU1ubFpiWEk0Tlg5bUthY3poT0IwTXFmRUxaOWtCeDJHVU0xYk5lc29HdEdrayIsIm1hYyI6IjE0OThmOGJjM2VmZDhiZThkZWU0NmUyOGU3YTE4OTUzYzMxYjZmMGY3MDdjMzMzZGRjM2QyODNiYWYyZmEzNTgifQ%3D%3D; npo_session=eyJpdiI6Ikx3S01VU1pwY3U5T1wvRXQ1TWVOa3JnPT0iLCJ2YWx1ZSI6InprYlFUYWtYUnJqMThEREZxZVwvV3VyWnpQcVlrblJ4ZktvMzhXOUwwbjE0WDdoUVJnRUltYmJaTkJHWE9mZmZpIiwibWFjIjoiYzU2NzVhNmM1ZDBkMDEzNjE0M2QzOGRmNjk3MDFlNTcyNzVhMTJhNjExNDdjYTMwMzkzNTU1YjliMzdkMmE1NSJ9; Cookie_Consent=Tue Oct 06 2020 13:33:56 GMT+0200 (Central European Summer Time); CCM_ID=fn6Tm6dPQ2gzMg==; Cookie_Category_Necessary=true; Cookie_Category_Analytics=true; atidvisitor=%7B%22name%22%3A%22atidvisitor%22%2C%22val%22%3A%7B%22vrn%22%3A%22-595271-%22%2C%22ac%22%3A%223%22%7D%2C%22options%22%3A%7B%22path%22%3A%22%2F%22%2C%22session%22%3A15724800%2C%22end%22%3A15724800%7D%7D; atuserid=%7B%22name%22%3A%22atuserid%22%2C%22val%22%3A%226428fbc5-18e4-485b-9cca-d96024af92ba%22%2C%22options%22%3A%7B%22end%22%3A%222021-11-07T11%3A33%3A38.556Z%22%2C%22path%22%3A%22%2F%22%7D%7D; _dvp=0:kfxvx7r8:akyFupPvmjJb9RQkRf1l_T_7NCCwOpKb; __cfduid=da250b154e8ace5a9d5c45b704dc3b09d1613318893; atkantarsession=%7B%22name%22%3A%22atkantarsession%22%2C%22val%22%3A%22session_in_progress%22%2C%22options%22%3A%7B%22expiration%22%3A1800%2C%22path%22%3A%22%2F%22%7D%7D; atkantarid=%7B%22name%22%3A%22atkantarid%22%2C%22val%22%3A%7B%7D%2C%22options%22%3A%7B%22end%22%3A604800%2C%22path%22%3A%22%2F%22%7D%7D; _dvs=0:kl80uhti:SzmUHYb3XyqqfgpQKMJ6hJtnpbL1V5p1; CCM_Wrapper_Cache=eyJ2ZXIiOiJ2My4xLjEwIiwianNoIjoiIiwiY2lkIjoiZm42VG02ZFBRMmd6TWc9PSIsImNvbmlkIjoib2p1eTUifQ==' -H 'TE: Trailers' > data/m_$PAGE.json
    curl "https://www.npostart.nl/media/series/KN_1699061/fragments?page=$PAGE&tileMapping=normal&tileType=asset&pageType=franchise" -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:85.0) Gecko/20100101 Firefox/85.0' -H 'Accept: */*' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'X-XSRF-TOKEN: eyJpdiI6ImFUVHVhVG1lQ3pzdE53YUZlNUxMXC9BPT0iLCJ2YWx1ZSI6Im9BeEZPNUFIbnE3MXEwTE1YMzcrMEV1d3RqTDdGYzdxcnFCQ1hRMVA5cnJJTHdMdWlUVkxpV1wvTVJERXJ4bklOIiwibWFjIjoiMzlkNGJiNjMwNWE3ZjBiMmRlMzY1MjQzNGE4OTdlOTYyYmYyOTJhYzhhOTNiYjdjYTk4YTVhNWM3MWI4MGRlZSJ9' -H 'X-Requested-With: XMLHttpRequest' -H 'Connection: keep-alive' -H 'Referer: https://www.npostart.nl/m/KN_1699061' -H 'Cookie: XSRF-TOKEN=eyJpdiI6Ikg4N010eFArYmFvRXYrNXk4VHdkUnc9PSIsInZhbHVlIjoiSDZTZ2tyYnRUclJ0aktXVUYyMU1ubFpiWEk0Tlg5bUthY3poT0IwTXFmRUxaOWtCeDJHVU0xYk5lc29HdEdrayIsIm1hYyI6IjE0OThmOGJjM2VmZDhiZThkZWU0NmUyOGU3YTE4OTUzYzMxYjZmMGY3MDdjMzMzZGRjM2QyODNiYWYyZmEzNTgifQ%3D%3D; npo_session=eyJpdiI6Ikx3S01VU1pwY3U5T1wvRXQ1TWVOa3JnPT0iLCJ2YWx1ZSI6InprYlFUYWtYUnJqMThEREZxZVwvV3VyWnpQcVlrblJ4ZktvMzhXOUwwbjE0WDdoUVJnRUltYmJaTkJHWE9mZmZpIiwibWFjIjoiYzU2NzVhNmM1ZDBkMDEzNjE0M2QzOGRmNjk3MDFlNTcyNzVhMTJhNjExNDdjYTMwMzkzNTU1YjliMzdkMmE1NSJ9; Cookie_Consent=Tue Oct 06 2020 13:33:56 GMT+0200 (Central European Summer Time); CCM_ID=fn6Tm6dPQ2gzMg==; Cookie_Category_Necessary=true; Cookie_Category_Analytics=true; atidvisitor=%7B%22name%22%3A%22atidvisitor%22%2C%22val%22%3A%7B%22vrn%22%3A%22-595271-%22%2C%22ac%22%3A%223%22%7D%2C%22options%22%3A%7B%22path%22%3A%22%2F%22%2C%22session%22%3A15724800%2C%22end%22%3A15724800%7D%7D; atuserid=%7B%22name%22%3A%22atuserid%22%2C%22val%22%3A%226428fbc5-18e4-485b-9cca-d96024af92ba%22%2C%22options%22%3A%7B%22end%22%3A%222021-11-07T11%3A33%3A38.556Z%22%2C%22path%22%3A%22%2F%22%7D%7D; _dvp=0:kfxvx7r8:akyFupPvmjJb9RQkRf1l_T_7NCCwOpKb; __cfduid=da250b154e8ace5a9d5c45b704dc3b09d1613318893; atkantarsession=%7B%22name%22%3A%22atkantarsession%22%2C%22val%22%3A%22session_in_progress%22%2C%22options%22%3A%7B%22expiration%22%3A1800%2C%22path%22%3A%22%2F%22%7D%7D; atkantarid=%7B%22name%22%3A%22atkantarid%22%2C%22val%22%3A%7B%7D%2C%22options%22%3A%7B%22end%22%3A604800%2C%22path%22%3A%22%2F%22%7D%7D; _dvs=0:kl80uhti:SzmUHYb3XyqqfgpQKMJ6hJtnpbL1V5p1; CCM_Wrapper_Cache=eyJ2ZXIiOiJ2My4xLjEwIiwianNoIjoiIiwiY2lkIjoiZm42VG02ZFBRMmd6TWc9PSIsImNvbmlkIjoib2p1eTUifQ==' -H 'TE: Trailers' > data/m_$PAGE.json
    #curl 'https://ipso.nl/ipso-inloophuizen/' -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:85.0) Gecko/20100101 Firefox/85.0' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'Connection: keep-alive' -H 'Cookie: _ga=GA1.2.1726902043.1613691434; _gid=GA1.2.1375136324.1613691434; _gat_gtag_UA_167873257_1=1' -H 'Upgrade-Insecure-Requests: 1' -H 'TE: Trailers' > inloop.json
    #curl "https://www.npostart.nl/media/series/BV_101401602/episodes?page=$PAGE&tileMapping=dedicated&tileType=asset&pageType=franchise" -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:86.0) Gecko/20100101 Firefox/86.0' -H 'Accept: */*' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'X-XSRF-TOKEN: eyJpdiI6IlJpb245aWJCb0ZUZHVNamF4KytjUUE9PSIsInZhbHVlIjoiTFBack9QS01Jdm9udXEwYWZXclBzbFBBZnlncUNkdkROdFwvaEk2ZzdiMGgzQlwvaXJ5MzNCN05XemFlTGJkT0JjIiwibWFjIjoiZDk4ODQ0Y2ExYjQyN2I2ZDcwMjJmOTVjYWEwNGU5YmEwYmVhYmI1NTNmZjdkZjkyOTBiMGFmNzYzOGJlMTcxNyJ9' -H 'X-Requested-With: XMLHttpRequest' -H 'Connection: keep-alive' -H 'Referer: https://www.npostart.nl/de-vooravond/BV_101401602' -H 'Cookie: XSRF-TOKEN=eyJpdiI6IlwvXC9cL2J2cnA0K0FXMWxPSzdKRm5MN2c9PSIsInZhbHVlIjoiYzZKV2VDUk53TmxPOE5BVEtpWDFHTTZFZ0pkRTZKVjMwQUNYODkzODQ3TXJycnhCdXFHSVJtWGtrNGFha2JRRiIsIm1hYyI6ImNiYTVlZTU0Y2Y3MDk1NTBlYmQwYzBjNTZlM2U3Y2ZkYzU3MmQ0YzM0Nzg1MWNiMzM5ZGFhMjFmYzQ4MDVkMDcifQ%3D%3D; npo_session=eyJpdiI6IlQ5VDM5UXp2VHZ1ZExHV2k3UW5XSlE9PSIsInZhbHVlIjoidTNTREVOXC9pV0xkT25FUlVPXC9GWFE2NjVVcHlVSk1rOGdLcXJiQ0pQY2xDODRONUR0RE1OVElHNUg3YXB5ZFZuIiwibWFjIjoiZWI4YWI4YWUyYTI4NjVjMDMyNzQyY2NkZGQ0NWIyMGNjYTJmMWVjNzllNTU2NTA3ZDFhZWVjM2RhNjUxZjdjNyJ9; Cookie_Consent=Tue Oct 06 2020 13:33:56 GMT+0200 (Central European Summer Time); CCM_ID=fn6Tm6dPQ2gzMg==; Cookie_Category_Necessary=true; Cookie_Category_Analytics=true; atidvisitor=%7B%22name%22%3A%22atidvisitor%22%2C%22val%22%3A%7B%22vrn%22%3A%22-595271-%22%2C%22ac%22%3A%223%22%7D%2C%22options%22%3A%7B%22path%22%3A%22%2F%22%2C%22session%22%3A15724800%2C%22end%22%3A15724800%7D%7D; atuserid=%7B%22name%22%3A%22atuserid%22%2C%22val%22%3A%226428fbc5-18e4-485b-9cca-d96024af92ba%22%2C%22options%22%3A%7B%22end%22%3A%222021-11-07T11%3A33%3A38.556Z%22%2C%22path%22%3A%22%2F%22%7D%7D; _dvp=0:kfxvx7r8:akyFupPvmjJb9RQkRf1l_T_7NCCwOpKb; __cfduid=da250b154e8ace5a9d5c45b704dc3b09d1613318893; atkantarid=%7B%22name%22%3A%22atkantarid%22%2C%22val%22%3A%7B%7D%2C%22options%22%3A%7B%22end%22%3A604800%2C%22path%22%3A%22%2F%22%7D%7D; atkantarsession=%7B%22name%22%3A%22atkantarsession%22%2C%22val%22%3A%22session_in_progress%22%2C%22options%22%3A%7B%22expiration%22%3A1800%2C%22path%22%3A%22%2F%22%7D%7D' -H 'If-None-Match: W/"d791c6d4d910d8c0b447a9c922bd0554"' -H 'TE: Trailers' > vooravond2020_$PAGE.json
    #curl "https://www.videoland.com/series/500572/humberto" > humberto2021.json

done

