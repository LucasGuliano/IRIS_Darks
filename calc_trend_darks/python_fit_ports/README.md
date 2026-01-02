Version:
===================================

A new version is created each time the model is seperated. (~yearly)

Versions before V7 only worked with python2 (which was very outdated a long time ago). 

V7 brought up to standard of using python3. 


MODEL SEPARATION INSTRUCTIONS:
===================================

Starting in 2022, the model moved from a continues model to one with distinct segments. This was done for simplicity and to ensure proper data processing. The model is now refit every so often (annually) into distinct segments, referred to as Model (Letter), such as Model A and Model B. 

The idea is that for a set period of time, a distinct set of parameters will be used. The actual separating process is usually performed towards the start of a new year, often in March or April to get some data after the end of the newly separated model segment. For example, Model F (covering 2024/01/01 through 2025) would be locked in around March 2026 and would be calculated using data going at least 1 cycle back (so to late 2023) and a few months forward (so using the first few sets from 2026). This is done to avoid overweighting any point from a single year and improve the model fit.

Below are the steps needed when a new model segment is to be created, where we are looking to lock in the parameters for Model F (covering 2024/11/01 through 2025) and add a new model segment for Model G covering 2026 moving forward:

1.    Determine the time where the model will be separated and the new model will begin. When will we switch from Model F to Model G?
i.    This needs to be converted into the python format used by the GUI code. Record this time but don't modify any code yet. 
ii.     IDL (the format the data in the .sav file is stored in) utilizes anytim with a Jan 1st 1979 start time
iii.    Data times in the python GUI are generated with a Jan 1st 1979 start in mind
iv.    Python utilizes a Jan 1st 1970 start time, so a conversion factor is needed between the two
v.    Conversion factor in the code: self.convert = 284014800.0
vi.    To convert manually in Python, use: datetime.fromtimestamp(284014800+X).strftime("%m/%d/%Y %I:%M") to find the correct start time (you can use previous entries to test)
vii.    Start with the previous model separation time as X and iterate until correct time is found.
viii.    In this example, Model G would want to start right at 2026/01/01, which corresponds to 1.4832288e+09.

2.    In the GUI code, set the separation time to go back to the first set of data you want to use to optimize your parameters. 
i.    Don’t delete the actual separation time, we are only doing this temporarily to ‘trick’ the GUI into refitting with a bigger dataset. You can just comment out the real time and put in the temporary one. 
ii.    For model F, temporarily setting the self.seperation_F value to something like 1.42e+09 will means it looks back to data from the end of 2023 through now. 

3.    Run a normal model refit to optimize the fit FOR THE TIME PERIOD COVERED BY THE NEW MODEL!
i.    At this step, you are only looking to create a good fit for your latest segment but will be using data from outside the range actually covered by the model 
ii.    If we perform a refit in the GUI, the model on the plot will be updated from the end of 2023 all the way to the current time. But we only care about the fit of the segment over the data actually in Model F (so 2024/11/01 through the end of 2025)
iii.    You can go back and change the start time to get better results if needed to include more or less data. 

4.    Print the results and update parameters in the parameter file for the current model segment. Update these parameters in the appropriate place in the iris_dark_trend_fix.pro file. 
i.    Congrats! Model F is now locked in with optimized parameters. Never change them again. 

5.    Once the current model is locked in with optimized parameters, now we want to add a new model segment (Model G) to our code. This will start with the same optimized parameters you just created and can be updated throughout the year as we get more 2026 that Model G will be covering. 

6.    Copy the fit_ports_gui_VX.py file and create fit_ports_gui_V(X+1).py. It can technically be done in the same version, but I have been creating a new version each time the model is separated. 

7.    Copy the current model parameter file and rename for the new model segment (Copy Model_Parameters_F.txt and then rename new copy Model_Parameters_G.txt'). 

8.    Update the new version of the GUI code: 
i.    This work is pretty straight forward. Basically all you need to do is copy the previous format to shift the model segment forward. I have noted each section where changes are needed
i.    In the 'Parameter Read In Section', you need to create a new section to read in parameters and update the previous one. Copy the previous block and paste a new one below. Change references to the previous letter to the new one including the new parameters.txt file.  In the previous one, create a new dictionary with the correct letter and change the current_dict variables in the section to the LETTER_dict. See previous versions and match. The code expects the latest model to be using current_dict for the parameters. 
ii.     In the ‘Timing Section', create a new self.seperation_X variable for the start of the new model. (From step 2) Follow previous format
iii.    In the ‘Model Parameters Section', you will need to create a new set of parameters to be read in. Following the previous format, create a new set of parameters for the PREVIOUS model version following the correct letter format. (So in this example copy the parameters E section and make a parameters F section) The script is reading in the CURRENT parameters (with no letter) without needing this step, but you need to hard code in the parameters for the previous version. Just copy the previous and change the parameter names accordingly. 
iv.    In the ‘Model Trend Section', you will need to both create a new model and update the previous one to use the renamed parameters. First, copy the previous model and create a new entry. In the new entry, change all letter variables to the next one forward. (NOTE: cport variable is not part of the letter scheme and stays the same. c is also a constant, so be sure you are only updating the parameters). In the previous model, change parameter names to include letter prefix (amp1 --> F_amp1)

9.    The GUI will now have locked in parameters for Model F (covering 2024/11/01 through 2025) and will be plotting Model G with those same parameter values for now. It will be able to perform refits from the start of Model G (2026/01/01) to the current point without impacting model F at all. 
i.    If model G starts to get misaligned in say June and you go to refit, you will get a bad result as it will only be using data back to the separation point. To get a better refit, add more data to the refit by temporary moving the point of seperation_G back to incorporate more data. 

10.    Update the iris_dark_trend_fix.pro file for the new version. This is the file that will actually be used in processing the data. 
i.    Copy block of text that described the parameters for the previous model. Paste below in the same format. Update variables with new letter name and new parameter values. Copy from parameter text file. Update start time for this new segment to match model start time. 
ii.    Create a new model entry for the new model by copying and pasting the previous model. Update the parameters to use the new model (change the letters) and verify your model is of the same form (should be unless there were major changes in one of the refits)
iii.    Create a new array to determine the time that the new model will use. This works by creating arrays with 0s for times outside the model segment and 1 for times within the model segment. Then by multiplying the calculated model offsets by these arrays, we are only getting data for the correct model for the correct time. Create an array called Model_X_time with the correct letter. Modify the previous model time to end at the start of the new model. The new model time should start from that time. Follow previous formats. Add a new + (Model_X_offsets * Model_X_time) to the final offsets equation. Again, follow previous format. 
iv.    Double check that all parameter names and variables have been updated correctly. 
v.  Run test to ensure update was properly done. To do this, use the 'iris_dark_trend_fix.pro' files. You can get the offset values for a given time with each version of the file. Confirm that you are getting the expected results. Try running in each version right before and right after the model separation to confirm the difference. 

11.    You will also need to create a new version of the the iris_dark_trend_fix.pro used in our code. Just copy and paste the new and modified segments and save. 

12.    Send out new model with instructions for reprocessing.


NOTE: If better alignment is found a few months off of the end of the year in either direction, that is ok. You want to try to minimize discontinuities, so sometimes moving forward or back a month produces a better result. That is why Model F starts in November rather than at the start of the new year. It produced a better alignment that way. 

	

fit_ports_gui.py
================
A python GUI for fitting the long term pedestal trend of the IRIS CCDs. 
The program uses the sav file (offset30n.dat and offset30f.dat) created by the main IDL program. 

The python GUI imports the following modules. 

    a. matplotlib
    b. numpy
    c. sys
    e. datetime
    c. tkinter
    d. scipy
    f. fancy_plot (Module written as part of the pipeline and included as fancy_plot.py)

To run the program type the following command in a terminal window:  
> python fit_ports_gui.py  (or correct version number)


After typing the command you will be greeted with a GUI containing two plots.
The left and right plots contain the FUV and NUV, respectively, difference between the model pedestal and the measured dark
pedestal as a function of time. Both the FUV and NUV CCDs contain four ports for rapid read out of the CCD
 (port 1 = red circle, port 2 = blue square, port 3 = teal diamond, and port 4 = black triangle).
The plot also contains a model for the pedestal's evolution with the color corresponding to the port number. 
The model pedestal parameters' for CCD type and port are below their respective plots in the med row. Above and below 
the med row for each parameter is the maximum and minimum range to search for new parameters. The parameter range maybe 
set automatically by usieng the % Range text box in the bottom right of the gui.

Fortunately, deviations from the trend do not happen to all ports at the same time.
Therefore, you are sometimes only refitting a few port every three months,
which is why the GUI allow you to select the ports you want to refit.
Furthermore, the parameters not all parameters need refit every recalibration,
 which is why the GUI allows you to dynamic freeze some parameters. In the example below I only 
wanted to refit FUV port 3 for the Amplitude of the sin function. 
Selecting port and freezing parameters example below:   
[![IMAGE ALT TEXT HERE](http://img.youtube.com/vi/v3VH7uBjTJw/0.jpg)](http://www.youtube.com/watch?v=v3VH7uBjTJw)

In the above example using an infinite range worked well. Frequently, using an unrestricted range causes the 
program to find nonoptimal minimums. Therefore, I included a range box in the lower right. The range box
sets the minimum and maximum allowed value for all thawed parameters. Of course this example did not benefit from
a restricted range, but it is an outlier not the norm.
Setting parameter range example below:  
[![IMAGE ALT TEXT HERE](http://img.youtube.com/vi/1Nu14eoA0ww/0.jpg)](http://www.youtube.com/watch?v=1Nu14eoA0ww)

Finally, you will want to efficiently save new parameters. The GUI has the print button for that.
The print button print the new parameter values in a format for the iris_trend_fix program, as well as,
the initial_parameters.txt file.
Printing new parameters example below:  
[![IMAGE ALT TEXT HERE](http://img.youtube.com/vi/jC0AbvZRth8/0.jpg)](http://www.youtube.com/watch?v=jC0AbvZRth8)


initial_parameters.txt
----------------------
A file containing a list of initial parameters for the long term pedestal offset model. 
The format is the same as the format printed by fit_ports_gui.py (e.g. below).


\     Amp1      ,Amp2      ,P1             ,Phi1      ,Phi2      ,Trend               ,Quad                ,Offset    
fuv1=[ 0.16210  , 0.02622  ,  3.1504e+07   , 0.41599  , 0.09384  ,  2.819499502e-08   ,  5.705285157e-16   , -0.56933 ]  
fuv2=[ 0.25704  , 0.19422  ,  3.1568e+07   , 0.37571  , 0.89102  ,  2.832588907e-08   ,  4.108370809e-16   , -0.54180 ]  
fuv3=[ 1.46520  , 1.62863  ,  3.1522e+07   , 0.33362  , 0.87265  ,  2.618708232e-08   ,  1.219050166e-15   , -0.60404 ]  
fuv4=[ 0.27947  , 0.14585  ,  3.1383e+07   , 0.39938  , 0.90869  ,  1.880687110e-08   ,  9.619889318e-16   , -0.59357 ]  
nuv1=[ 0.55495  , 0.53251  ,  3.1782e+07   , 0.32965  , -0.07967 ,  3.995823558e-09   ,  2.297179460e-16   , -0.16966 ]  
nuv2=[ 0.73259  , 0.68243  ,  3.1841e+07   , 0.33437  , 0.92937  ,  3.278569052e-09   ,  2.743724242e-16   , -0.21646 ]  
nuv3=[ 0.26427  , 0.24439  ,  3.1696e+07   , 0.33597  , 0.91779  ,  1.004922804e-08   ,  3.098606381e-16   , -0.12297 ]  
nuv4=[ 0.41707  , 0.44189  ,  3.1642e+07   , 0.32680  , 0.90548  ,  7.943234757e-09   ,  3.284834996e-16   , -0.21366 ]  
