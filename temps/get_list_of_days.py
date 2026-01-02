import datetime as dt
import glob
import numpy as np
try:
    #for python 3.0 or later
    from urllib.request import urlopen
except ImportError:
    #Fall back to python 2 urllib2
    from urllib2 import urlopen

import os
from format_temps import format_file

# NO Certificate check
import ssl
ssl._create_default_https_context = ssl._create_unverified_context

#Get the list of contaminated text files
files = glob.glob('../contam_txt_files/*txt')

for i in files:

    x = np.loadtxt(i,dtype={'names':('file','time','pass','fivsig','exptime'),'formats':('S35','S20','i1','i4','f8')},skiprows=2)

    time = x['time'].astype('S10')

    utime = np.unique(time)
    for p in utime: 
        for j in np.arange(-2,2):
            day = dt.datetime.strptime(p.decode('utf-8'),'%Y/%m/%d')+dt.timedelta(days=int(j))
            t = day.strftime('%Y%m%d')
            fname= '{0}_iris_temp.txt'.format(t)
            if os.path.isfile(fname):
                continue
            else:
            #Print added for times when the temp files moved, helpful to know what it looks for but can be commented out if desired
               print("Getting file from: "+'https://www.lmsal.com/solarsoft/irisa/data/prep/aux/temp/{0}'.format(fname))
               res = urlopen('https://www.lmsal.com/solarsoft/irisa/data/prep/aux/temp/{0}'.format(fname))
               dat = res.read()
               fo = open(fname,'w')
               #Convert to byte format (needed in Python3)
               dat = dat.decode('utf-8')
               fo.write(dat)
               fo.close()
               format_file(fname)



    
   






