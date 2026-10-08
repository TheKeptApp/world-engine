"""Offline independent numerical reference, NOT observed sky or NOAA self-output.
USNO 'Approximate Solar Coordinates': https://aa.usno.navy.mil/faq/sun_approx
Low precision geocentric solar RA/declination + IAU GMST expression.
Freeze 24 values: two cities x both solstices/equinoxes x rise/transit/set.
No runtime/test dependency on Python and no network or installed packages.
"""
import math as m, json
from datetime import datetime, timezone, timedelta
from pathlib import Path
R=m.pi/180
s=lambda x:m.sin(x*R)
c=lambda x:m.cos(x*R)
def position(ts,lat,lon):
    d=ts/86400+2440587.5-2451545
    g=(357.529+0.98560028*d)%360
    q=(280.459+0.98564736*d)%360
    L=q+1.915*s(g)+0.020*s(2*g)
    eps=23.439-0.00000036*d
    ra=m.atan2(c(eps)*s(L),c(L))/R
    dec=m.asin(s(eps)*s(L))
    H=((280.46061837+360.98564736629*d+lon-ra+180)%360)-180
    elevation=m.asin(s(lat)*m.sin(dec)+c(lat)*m.cos(dec)*c(H))/R
    azimuth=(m.atan2(s(H),c(H)*s(lat)-m.tan(dec)*c(lat))/R+180)%360
    return elevation,azimuth,H
rows=[]
for city,lat,lon in [('Denver',39.7392,-104.9903),('Chicago',41.8781,-87.6298)]:
    for date in ['2026-03-20','2026-06-21','2026-09-22','2026-12-21']:
        midnight=datetime.fromisoformat(date).replace(tzinfo=timezone.utc).timestamp()
        noon=midnight+(12-lon/15)*3600
        for event,lo,hi in [('sunrise',noon-10*3600,noon),('noon',noon-3600,noon+3600),('sunset',noon,noon+10*3600)]:
            def f(ts):
                e,a,h=position(ts,lat,lon)
                return h if event=='noon' else (e+0.833333)*(1 if event=='sunrise' else -1)
            for _ in range(60):
                mid=(lo+hi)/2
                if f(mid)<0: lo=mid
                else: hi=mid
            ts=round((lo+hi)/2)
            e,a,h=position(ts,lat,lon)
            rows.append(dict(city=city,event=event,date=date,lat=lat,lon=lon,
                time=datetime.fromtimestamp(ts,timezone.utc).isoformat().replace('+00:00','Z'),
                elevationDeg=round(e,6),azimuthDeg=round(a,6)))
Path(__file__).with_name('solar-reference.json').write_text(json.dumps(dict(
    source='USNO Approximate Solar Coordinates; independent Python implementation in generate-solar-reference.py',
    evidence='calculated reference, not measurements; no online service queried', fixtures=rows),indent=2)+'\n')
