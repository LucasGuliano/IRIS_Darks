Long term dark analysis
=======================

The general goal of this pipeline and the person who uses it is to update the iris_dark_trend.pro file and send it to LMSAL to be used in the IRIS data processing pipeline. To correctly update this file, the processor must run this code, look at it with the GUI, make the correct adjustments to our model, then incorporate those adjustments into the iris_dark_trend.pro file so that it can be used in the data pipeline. 

These scripts test the long term trending of the IRIS pedestal dark level, which was first noticed to be discrepant from the launch model in ~June 2014.

The main directory contains a c-shell script (run_dark_checks.csh), which runs a series of codes.

First, it finds the most recent run of dark scripts by querying the IRIS timeline page with the script find_dark_runs_no_google.py. Then it grabs the text of the timeline file for that day and searches for the simpleb and complexa OBSIDs. 

NOTE: This used to be done with a script find_dark_runs.py which found the observed darks by querying the google calibration-as-run calendar for IRIS dark runs in the last 25 days. It would then grab the text of the timeline file for that day and search for the simpleb and complexa OBSIDs (find_dark_runs.py, N.B. add a proxy server to your environment in find_dark_runs.py if your institution does not allow access to the Google Calendar API). The No Google version became the default to avoid needing any updates or changes  to the API. 

Please ensure the entry on the calendar is correctly labeled (Calib 3: Dark), should be copied from each previous entry to ensure it is correct. Update as needed.

Using the last set of observed dark times, the dark files are download from JSOC using the drms module (get_dark_files.py)

Currently at SAO, the archive for IRIS darks is stored on the following server and drive:
newtokyo2:/vol/vol2/alisdair

Which can be mounted to machines at a set location. For the examples in this guide and the latest version of the pipeline, this was mounted to a location on a machine called:
/Volumes/IRIS_Darks/

The code initially places the level1 dark files in the directory listed on the second line of the parameter file. This can be wherever the archive is located or mounted to. Currently that is listed at:
/Volumes/IRIS_Darks/IRIS_LEVEL1_DARKS/ YYYY/MM/

 This is the standard location at SAO and is dictated by the parameter file. If this needs to be changed, it should be done in the parameter file. It will rename the files to adhere to previous standards.

Next, it converts the level1 files to level0 darks (do_lev1to0_darks.pro) for a given month and moves them to the level0 directory, located as the 3rd line in the parameter file. Currently for SAO that is listed at:
/Volumes/IRIS_Darks/opabina/level0/

Then the script checks for darks significantly affected by SAAs or transient particle hits (find_contaminated_darks.pro; i.e. too many 5 sigma hot pixels for a Gaussian distribution.).

Next, it will download the temperature files for the day darks are observed plus +/- 1 day and format the output temperature file for IDL.

Once all the files are in place, the core of the pipeline will be running dark_trend.pro. This script will use the contam txt files to read in every good level0 simpleB dark from the mission so far and compare the calculated dark model for that observation WITHOUT the long-term fix to the observed dark file. 

The last step in the dark pedestal pipeline creates plots to compare the observed to the modeled dark pedestal trend.

When the model does not align well with the taken darks, you may need to refit the model with new parameters. This is done once or twice a year typically. The GUI is used to find improved parameters and the new parameters are added in the correct locations. 

Additionally, at the end of each year, the model parameters for the previous year are ‘locked in’ and a new segment of the model is created. 

The hot_pixel_plot_wrapper is included at the end of the script. After the pedestal analysis finishes, the code runs the hot pixel analysis. The hot pixel analysis counts the number of Hot (5sigma) pixels in the level 1 IRIS observations.

For more information navigate to the IRIS_dark_and_hot_pixel sub-folder and read the README.md inside.

The program works automatically because the plots output to the 'Z' window in IDL. Therefore, the job maybe cronned. Though it can be easier to troubleshoot if run in sections once a month instead. 

NOTE: There are some minor changes between the iris_dark_trend_fix.pro file used locally at SAO and the one used at LMSAL. Copy the latest iris_dark_trend_fix_VXX.pro file and update for the file to be sent to LMSAL. Update the iris_dark_trend_fix.pro for local use. Both need to be updated after each model change or refit. 

Overview Recalibration Procedure 
--------------
Standard procedure is now to update dark model on an annual basis. However, if you notice the dark trend does not represent the dark pedestal measurements (~ 2 sigma) for a couple months in a row, then you need to do a recalibration of the dark pedestal in between cycles. 

Starting in 2022, a new methodology was developed for the IRIS darks. Rather than updating the parameters for the entire mission, parameters were separated. Parameters before the separation were locked in and no longer are adjusted. Parameters after adhere to a new model and are free to adjust. 

Model A: Covers from the start of the mission through July 8th, 2020. 
Model B: Covers from July 9th, 2020 through December 2021. 
Model C: Covers all of 2022. 
Model D: Covers all of 2023.... etc

YOU SHOULD NEVER NEED TO MODIFY PARAMETERS FOR PREVIOUS MODEL VERSIONS, ONLY CURRENT MODEL VERSION AND VERSIONS GOING FORWARD!

General model refit:
Run run_dark_checks.csh to add the new darks and analyze the trend
Run the python_fit_ports GUI and modify the parameters or create a new model to improve the trend
Update initial_parameter.txt
Copy the new parameters into calc_trend_darks/iris_dark_trend_fix_VXX.pro to create file to send to calibration team
Run dark_trend.pro and iris_make_dark_trend_plots.pro to obtain the new plots (or get new plots from GUI)
Send the new plots, an updated iris_dark_trend_fix-VXX.pro, and tentative report to the local dark pedestal curator (probably you)
When the report is approved send it to iris_calib, attach new iris_dark_trend_fix_VXX.pro if model has changed

See the README in the python Gui fits folder for detailed instructions on creating a new model segment. 


run_dark_checks.csh
-------------------
The c-shell file is a wrapper combining the IDL and python portions of the program.
This wrapper is all you need to run for a simple run of IRIS dark calibrations.
In order to run the script from your machine you will need to do a few things.
First, is make this script executable by typing chmod a+x run_dark_checks.csh.
Then you need to update the HOME variable at the top of the directory to be your HOME directory.

find_dark_runs.py
-----------------
The program searches the calendar for the string calib3:dark and sends the day to get_dark_files.py and the year,month to c-shell script,
which the c-shell script uses to pass to IDL functions.

NOTE: This section is only relevant when using the original find_dark_runs.py, not the currently used no_google version
Finally, you need to follow instructions at https://developers.google.com/google-apps/calendar/quickstart/python
to get the google calendar API for your email address and the associated python packages.
The google documentation is a bit weak, so I will add a bit more detail.
First, make sure to add the IRIS calibration as-run to your calendar if you don't already have it.
If you followed the instructions on the webpage you should have downloaded a file called credentials.json in the current directory. 
After you verify the code as detailed on the webpage, 
copy the token.json to client_secret.json and ~/.credentials/calendar-python-quickstart.json. 

If the Google code fails, then follow the following steps:     

python quickstart.py --noauth_local_webserver    

Then a webpage will print in the terminal. Copy and paste that text into a web browser (mine looked like https://accounts.google.com/o/oauth2/auth?client_id=......). Then allow that application access to your calendar.

That page will give you a verification code. Copy that code from the browser back to the terminal, which is now asking for a code. After you paste the code and hit enter you should see some events from your calendar.

Now if you run python quickstart.py --noauth_local_webserver it will immediately print a few calendar events.

After you verify the code as detailed on the webpage, 
copy the token.json to client_secret.json and ~/.credentials/calendar-python-quickstart.json. 


find_dark_runs_no_google.py
-----------------
This version of find_dark_runs uses the iris timeline files. 
The program searches archived timeline files and sends the day to get_dark_files.py and the year,month to c-shell script,
which the c-shell script uses to pass to IDL functions.


get_dark_files.py
-----------------
This program is the work horse for obtaining the darks from JSOC.
It takes the time from find_dark_runs.py and whether you are seeking complexA or simpleB darks (find_dark_runs asks for both).
The program then gets the timeline text from Lockheed, which it parses to find start and stop times for OBSIDs corresponding to the selected dark.
Next, it uses the time frame found in the timeline to query JSOC iris level1 using the drms module in python ([will need to install drms]).
Once the JSOC query finishes, the program downloads the files and renames them according to a previous file naming convention for convince.

Versions of the program after September 17, 2018 require a parameter file in the current directory called "parameter_file".
This file contains three lines in the order below (use help(get_dark_files) for more information:
Line1: email address registered with JSOC (e.g. email@email.org)    
Line2: A base directory containing the level 1 IRIS dark files. The program will concatenate YYYY/MM/simpleb/ or YYYY/MM/complexa/ onto the base directory    
Line3: A base directory containing the level 0 IRIS dark files. The program will concatenate simpleb/YYYY/MM/ or complexa/YYYY/MM/ onto the base directory    

An example parameter file exists in the current directory.

do_lev1to0_darks
----------------
This is a legacy program, which uses sswidl libraries.
You may call it by the following commands in IDL.

>do_lev1to0_darks,MM,YYYY,/simpleB,'0','dummydir/'

>do_lev1to0_darks,MM,YYYY,/complexA,'0','dummydir/'

The program assumes the darks are located in line 2 of parameter file in addition to the YYYY/MM subdirectory passed to the program.
The level 1 to level 0 conversion is small and mostly rotates the image using the sswidl function iris_lev120_darks.
Currently, the program is set to output to a dummy directory because saving to a network directory from IDL can 
cause hangs.
Therefore, it creates the files locally and then immediately move them in the script to the output directory specified in line 3 of the parameter file.


find_con_darks_no_thread
----------------
This work is performed by the script find_con_darks_no_thread.pro, which is an IDL program which finds IRIS darks contaminated by SAA or CMEs. (It used to have a more complicated multi-threading structure that caused issues and was more complicated than it needed to be, so a non-threading version was used moving forward.) 

The main processing and analysis of each file is done by check_sig_level.pro. 

The program runs by taking an array of dates, the dark file types, and channel (NUV or FUV). You can specify the day in either 1 or 2 digits and the year in 2 or 4 digits. If only one year is specified then all months in a month array are assumed for that year.

The program finds contaminated darks by breaking each dark image into its four ports. Then it finds the number of pixels more than 5 sigma away from the mean.

It then sums the total number of pixels 5 sigma away from the mean and normalizes that number by the integration time (if the integration time is greater than 1). Then it uses the pixel fraction greater than 5 sigma to find images affected by SAA.

If you assume a Gaussian distribution, we expect that fraction to be 6.E-5, so we assume the 5 sigma Gaussian fraction to reject images with fraction higher than the Gaussian value.

Finally, the program writes the file name, start time of integration, whether it passed (1 is passed 0 is failed), total pixels above the 5 sigma level normalized by exposure time, and the integration time to a file in /contam_txt_files/. The output file is formatted NUV(or FUV)_YYYY_MM.txt.


temps/get_list_of_days.py
-------------------------
This is a simple python script, which grabs the temperature information from Lockheed.
It uses the files created by find_con_darks to find days darks were observed.
Then the program checks to make the temperature information does not exist locally,
and if it does not exist it downloads it.
Finally, it formats the file to just the important temperatures so IDL calls it easily.


calc_trend_darks/dark_trend
---------------------------
The final component is the plotting of the dark trend with the average dark values for a given month over-plotted.
The program to run the fix is dark_trend.pro and has a simple syntax, which specifies whether to run the trend on the simpleB  (/simpleb) darks.
An example follows:

full:

>dark_trend,sdir=sdir,pdir=pdir,simpleb=simpleb,complexa=complexa,logdir=logdir,outdir=outdir

usual:

>dark_trend,/simpleb

The program uses the SAA free darks found previously to look in the level0 directory for darks.
Again, the program again assumes the level0 data is located on the given network drive, but that can be changed by setting the sdir keyword.
After grouping all dark observations, it loops over all darks computing the average and sigma values over the whole chip in the program check_ave_pixel_sub, which is the workhorse of the program.
Upon completion of finding the averages the program calls plot_dark_trend with the after pixel values and the observation times.
Finally, the program saves the information to .sav and .txt files (alldark_ave_sig.sav and current_pixel_averages.txt).

check_ave_pixel_sub.pro
------------------------------------
This program's primary function is subtracting the current dark model from the set of darks passed to the program.
The syntax for check_ave_pixel_sub is as follows:

>check_ave_pixel_sub,file,endfile,timfile,avepix,sigpix,temps,levels,writefile=writefile

All parameters are set by default in dark_trend.pro, but for clarities sake they will be described here.
file is the full path to a given dark observation (string),
endfile is a formated file name which we will pass to plot_dark_trend (string),
timfile is the file formatted for reading the Lockheed IRIS temperature data and is computed in the program (string),
avepix is the average model subtracted dark pixel value returned by the program (4D vectory),
sigpix is the 1 sigma variation in the average value (4D vector),
temps is an array of temperatures used to derive the dark model (3x6 array),
levels is an array of dark pedestal values computed from the long term trend (4D vector),
and writefile is keyword which writes out the full dark-model dark-long term trend dark to a file. 


calc_dark_trend/plot_dark_trend.pro
-----------------------------------
plot_dark_trend groups the average dark information and plots it as a function of time with the long term pedestal trend
overplotted.
Again everything is set by default if you use the dark_trend program,
but the keywords and syntax are as follows:

>plot_dark_trend,time,yval,sdir=sdir,pdir=pdir,rest=rest

Where time is and array of file names returned by check_ave_pixel_sub in the endfile variable,
yval is the average pixel values from check_ave_pixel_sub,
sdir is the location of the simpleb darks with time information excluded (deprecated),
pdir is the output plotting directory,
and the rest keyword allows you to restore a previously save dark save file output by dark_trend.pro (alldark_ave_sig.sav).


Programs in Subdirectories
==========================

IRIS_dark_and_hot_pixel/
-----------------------
Contains program suite for IRIS hot pixel analysis. Automatically runs in run_dar_checks.csh.

calc_trend_darks/python_fit_ports/
---------------------------------
A python GUI for refitting the long term dark pedestal level. 


Parameters for Model A
==========
amp1: float    
    The amplitude of the approximately 1 year sine function.    
amp2: float    
    The amplitude of the approximately 1/2 year sine function.    
phi1: float    
    The phase of the approximately 1 year sine function in radians.    
phi2: float    
    The phase of the approximately 1/2 year sine function in radians.    
trend: float    
    The linear coefficient explaining the increase in the pedestal level.     
quad : float    
    The quadratic coefficient explaining the increase in the pedestal level.     
off:  float    
    The intercept for the quadratic and linear function    
qscale: float    
    The flattening of the linear and quadratic term after August 2017    
bo_drop: float    
    The fractional drop in the offset (intercept term) due to the bake out on June 13-15, 2018    
sc_amp: float    
    The amplication fraction in the in the sine function amplitudes due to the bake out on     
    June 13-15, 2018.    
ns_incr: float    
    The fractional increase in the offset (intercept term) due to non-standard IRIS operations    
    from October 27th to December 15th, 2018.    


Parameters for Model B, C, D, E, F, etc...
==========
amp1: float    
    The amplitude of the approximately 1 year sine function.    
amp2: float    
    The amplitude of the approximately 1/2 year sine function.    
phi1: float    
    The phase of the approximately 1 year sine function in radians.    
phi2: float    
    The phase of the approximately 1/2 year sine function in radians.    
trend: float    
    The linear coefficient explaining the increase in the pedestal level.     
quad : float    
    The quadratic coefficient explaining the increase in the pedestal level.     
off:  float    
    The intercept for the quadratic and linear function    

