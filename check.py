
from datetime import datetime as dt, timedelta as td

start = '2020-01-01'
sd = dt.strptime(start, '%Y-%m-%d')
dates ={}
for i in range(1,87):
    w = (i + 3)//5
    d = (i-1) + (2 * w)
    date=sd + td(days=d)
    dates[i]=date
    print(i,w,d, date)
print(dates)
