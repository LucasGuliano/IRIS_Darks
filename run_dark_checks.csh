#!/bin/tcsh

source $HOME/.cshrc
source $HOME/.cshrc.user

################################################

echo STARTING IRIS DARK PIPELINE 

#get output directory for level0 darks from the parameter file
#Two variables due to difference syntax used for shell and IDL calls
set tcsh_levz=`tail -1 parameter_file`
set sidl_levz="'"`tail -1 parameter_file`"'"

#Find the latest dark run, download the data, and set the dday variable (MM,YYYY)
set dday=`python find_dark_runs_no_google.py`
echo RAN DOWNLOAD SCRIPT. RESULT BELOW:
echo ${dday}

#Get formatted iday variable
set splt=( $dday:as/,/ / )
set iday=`echo $splt[2]/$splt[1]`

#Remove anything from the dummy directory for storage
rm dummydir/*

#Run as long as the output from find dark runs wasn't 'FAILED'
if ($splt[1] != 'FAILED') then

    echo FOUND DARKS! RUNNING THE PROCESSING PIPELINE

    #convert level1 darks to level0 darks for simpleb
    sswidl -e "do_lev1to0_darks,'"${iday}"/simpleB/','','',0,'dummydir/'"
    
    #Move files to file location based on the levz definition from the parameter file (line 3)
    mv dummydir/*fits ${tcsh_levz}/simpleB/${iday}/
    echo MOVED SIMPLEB L0 FILES TO ARCHIVE
    
    #convert level1 darks to level0 darks for complexA
    sswidl -e "do_lev1to0_darks,'"${iday}"/complexA/','','',0,'dummydir/'"
    
    #Move files to file location based on the levz definition from the parameter file (line 3)
    mv dummydir/*fits ${tcsh_levz}/complexA/${iday}/
    echo MOVED COMPLEXA L0 FILES TO ARCHIVE

    #Find darks with SAA contamination and write results to text file
    sswidl -e "find_con_darks_no_thread,"${dday}",type='NUV',logdir='log/',outdir='contam_txt_files/',/sim,sdir="${sidl_levz}
    sswidl -e "find_con_darks_no_thread,"${dday}",type='FUV',logdir='log/',outdir='contam_txt_files/',/sim,sdir="${sidl_levz}
    echo CONTAMINATION FILES GENERATED

    #Download and format the temperature files
    cd temps
    python get_list_of_days.py
    echo TEMPERATURE FILES DOWNLOADED

    #Run to get the current dark trend
    cd ../calc_trend_darks
    sswidl -e "dark_trend,/sim,sdir="${sidl_levz}
    echo DARK TREND PROCESSING COMPLETED

    #Make plots and generate .dat files for python refitting GUI
    sswidl -e "iris_make_dark_trend_plots"
    echo PLOTS AND DAT FILES GENERATED

    #Run the hot pixel script
    cd ../IRIS_dark_and_hot_pixel/
    sswidl -e "hot_pixel_plot_wrapper,file_loc="${sidl_levz}"+'/simpleB/'"
    echo HOT PIXEL PLOTS UPDATED

    #Give out a positive message
    echo DONE! NICE WORK DARK PROCESSOR!
    echo I AM VERY PROUD OF YOU!

endif

#Return failure message if it didn't find new darks
else echo ${dday}     
    
    

