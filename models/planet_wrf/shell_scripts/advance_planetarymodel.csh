#!/bin/csh
# Arguments are the process number of caller, the number of state copies
# belonging to that process, and the name of the filter_control_file for
# that process
#set echo
set process = $1
set num_states = $2
set control_file = $3
set output_directory = $4

set myname = $0
#echo $0 $1 $2 $3 $4
set CENTRALDIR = ..
set BASEWRFDIR = ${CENTRALDIR}/basedir

# Get unique name for temporary working directory for this process's stuff
set temp_dir = 'advance_temp'${process}

set REMOVE = '/bin/rm -f'
set REMOVEDIR = '/bin/rm -rf'
set   COPY = 'cp -p'
set   MOVE = 'mv -f'
   
# give the filesystem time to collect itself
sleep 1

# Create a clean temporary directory and go there
\rm -rf  $temp_dir
mkdir -p $temp_dir
cd       $temp_dir

if ( ! -e ${output_directory}/wrflogs ) mkdir -p ${output_directory}/wrflogs
if ( ! -e ${output_directory}/wrfout ) mkdir -p ${output_directory}/wrfout

# link the files from the base directory into this directory
ln -s ${CENTRALDIR}/input.nml .
ln -s ${BASEWRFDIR}/* .
    

# Each parallel task may need to advance more than one ensemble member.
# This control file has the actual ensemble number, the input filename,
# and the output filename for each advance.  Be prepared to loop and
# do the rest of the script more than once.
set state_copy = 1
foreach state_copy ( `seq $num_states` )
    #Each ensemble member follow the path
    #1. (dart_input_file) -> [filter] -> (dart_output_file)
    #2. (dart_output_file) -> [dart_to_wrf] -> (wrf_input_file)
    #3. (wrf_input_file) -> [wrf] -> (wrf_output_file)
    #4. (wrf_output_file -> [wrf_to_dart] -> (dart_input_file)
    
    #while it seems logically bad, we are responsible for 2-4 in this loop.
    #read the wrf info file for dart output and input file
    set line=`sed -ne "${state_copy}p;${state_copy}q" ${CENTRALDIR}/$control_file | tr ',' ' '`
    
    set ensemble_member = $line[1]
    set dart_input_file = $line[2]
    set dart_output_file = $line[3]
    
    set element = $ensemble_member
   
    # Shell script to run the WRF model from DART input.
    # where the model advance is executed as a separate process.
   
    #echo "starting ${myname} for ens member $element at "`date`
    #echo "CENTRALDIR is ${CENTRALDIR}"
    #echo "temp_dir is ${temp_dir}"
    
    cp ${CENTRALDIR}/wrf.info .
    pmo update-wrf-time namelist.input.orig wrf.info namelist.input
    pmo wrf-info wrf.info --csh
    source wrf.info.csh
    #
    #set my_num_domains = `head -6 wrf.info | tail -1`
    #set adv_mod_command = `head -7 wrf.info | tail -1`
    #set target_time = `head -2 wrf.info | tail -1 | tr ',' ' '`
    #set wrf_future = `pmo wrf-info wrf.info --future --wrf`
    #set wrf_current = `pmo wrf-info wrf.info --current --wrf`
    
    #zero pad the ensemble member number
    set ENS_NUM = `printf %4.4i $element`
    # WGL :: move the wrfout files for all domains corresponding to this ensemble member
    #echo ${MOVE} ${CENTRALDIR}/wrfout_d0?_${wrf_current}.${ENS_NUM} .
    ${MOVE} ${CENTRALDIR}/wrfout_d0?_${wrf_current}.${ENS_NUM} .
    if ( $status ) then
        echo "error with wrfout_d0?"
        echo ${ENS_NUM} ${CENTRALDIR}
        ls ${CENTRALDIR}/wrfout_d0?_*.${ENS_NUM} .
        exit(1)
    endif
   
    # WGL :: for now just move the d01 file over -- for robustness, we should check for
    #          other present domains
    ${MOVE} wrfout_d01_* wrfinput_d01
    if ( $status ) then
        echo "error with wrfout_d01"
        exit(1)
    endif
   
    ${MOVE} ${CENTRALDIR}/$dart_output_file . # ICs for run
    if ( $status ) then
        echo "error with input_file"
        exit(1)
    endif
   
   # Convert DART to wrfinput
   ${CENTRALDIR}/dart_to_wrf $dart_output_file wrfinput_d01 input.nml
   
   #WGL
   sleep 1
   if ( -e $dart_output_file ) ${REMOVE} $dart_output_file
   
   
   ###################################################
   # Advance the model until target time is reached. #
   ###################################################
   ls rsl.* >& /dev/null
   if ( ! $status ) then
      ${REMOVE} rsl.*
   endif
   
   # WRF integration
   sleep 1
   ${adv_mod_command}  >>&! rsl.out.integration
   if ( -e rsl.out.0000 ) cat rsl.out.0000 >> rsl.out.integration
   if ( ! -e ${output_directory}/wrflogs ) mkdir -p ${output_directory}/wrflogs
   ${COPY} rsl.out.integration ${output_directory}/wrflogs/wrf.out_${dart_future}_${element}  
   
   set SUCCESS = `grep "wrf: SUCCESS COMPLETE WRF" rsl.* | cat | wc -l`
   if ($SUCCESS == 0) then
       echo $element >> ${output_directory}/blown_${dart_future}.out
       echo "Model failure! Check file " ${output_directory}/blown_${dart_future}.out
       echo "for a list of failed elements, and check here for the individual output files:"
       echo " ${output_directory}/wrflogs/wrf.out_${dart_future}_${element}  "
       exit -1
    endif

   
# WGL :: reuse ENS_NUM defined above to give wrfout files unique names
   set dn = 1
   foreach dn ( `seq $my_num_domains` )
       ${COPY} wrfout_d0${dn}_${wrf_future} wrfinput_d0${dn}
       ${MOVE} wrfout_d0${dn}_${wrf_future} wrfout_d0${dn}_${wrf_future}.${ENS_NUM} 
       ${REMOVE} wrfout_d0${dn}_${wrf_current}
       
       # create new input to DART
       ${CENTRALDIR}/wrf_to_dart wrfout_d0${dn}_${wrf_future}.${ENS_NUM} $dart_input_file input.nml >& out.wrf_to_dart
   end

   ##############################################
   # At this point, the target time is reached. #
   ##############################################
      
   ${COPY} wrfout_d0${dn}_${wrf_future}.${ENS_NUM} ${CENTRALDIR}/wrfinput_d01
   ${COPY} wrfout_d0${dn}_${wrf_future}.${ENS_NUM} ${output_directory}/wrfout
   ${MOVE} wrfout_d0* ${CENTRALDIR}/.
   
   #WGL
   sleep 1

   ${MOVE} $dart_input_file ${CENTRALDIR}/

end


# Change back to working directory and get rid of temporary directory
cd ${CENTRALDIR}
${REMOVEDIR} ${temp_dir}

# Remove the filter_control file to signal completeion
# Is there a need for any sleeps to avoid trouble on completing moves here?
\rm -rf $control_file


