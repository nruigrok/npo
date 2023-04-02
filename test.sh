echo "Bash version ${BASH_VERSION}..."
for i in {0..10..2}
  do
     echo "Welcome $i times"
 done

 for PAGE in {0..600..10}; do
    #curl "https://api.nlziet.nl/v7/series/v9UF8_YSN0-3TOmL7OLizQ/episodes?limit=10&offset=$PAGE" > gasten2021/jinek_2021_$PAGE.json
    #curl "https://api.nlziet.nl/v7/series/qQtl7oxRTUyBz3aVWp8tNQ/episodes?limit=10&offset=$PAGE" > gasten2021/beau_$PAGE.json
    #curl "https://api.nlziet.nl/v7/series/HCI9fXoImEOKVb2HuWG-dA/episodes?seasonId=AQkMiNkHbUOZFxX7hpDYaw&limit=10&offset=$PAGE" >gasten2021/humberto2021_$PAGE.json
    #curl "https://api.nlziet.nl/v7/series/HCI9fXoImEOKVb2HuWG-dA/episodes?seasonId=spHQpiZFfESz2abUgSVazw&limit=10&offset=$PAGE" >gasten2021/humberto2021_voorjaar_$PAGE.json
    #curl "https://api.nlziet.nl/v7/series/tWY_1QC6_kq42GZ-jqzABQ/episodes?limit=10&offset=$PAGE&lastReceivedId=6-Ykn8OirESS790p3PZBtg" > gasten2021/op1_2021_$PAGE.json
    #curl "https://api.nlziet.nl/v7/series/V3qAiAMQ4kyZZEo8JMrWDA/episodes?seasonId=VriWjkczSECP-xlRqz9NMA&limit=10&offset=$PAGE" > gasten2021/sophie_2021_$PAGE.json
    #curl "https://api.nlziet.nl/v7/series/Hq3-ooOec0GJ7noqFP5j1g/episodes?limit=10&offset=$PAGE&lastReceivedId=450phrGO60qqU63KHBh1uQ" > gasten2021/pauw_$PAGE.json
    #curl "https://api.nlziet.nl/v7/series/Mp0hlGtSDEqxQFZLY5KAOQ/episodes?limit=10&offset=$PAGE&lastReceivedId=zHp5-tNXGkCdwEUvm5z5Zw" > gasten2021/jinek_npo$PAGE.json
    #curl "https://www.npostart.nl/media/series/POMS_S_VARA_059932/episodes?page=$PAGE&tileMapping=dedicated&tileType=asset&pageType=franchise" > gasten2021/pw_$PAGE.json
    curl "https://api.nlziet.nl/v7/series/WB9Bqt1cYEusl0zdwkRchQ/episodes?limit=10&offset=30&lastReceivedId=KUfk3TYWl0Cf7mXjjVtB8w" > gasten2021/pw_$PAGE.json
done
