#!/bin/bash
# Arguments are the process number of caller, the number of state copies
# belonging to that process, and the name of the filter_control_file for
# that process
execname=$0
process=$1
start_state=$2
end_state=$3
control_file=$4

echo $execname $process $state_state $end_state $control_file

CENTRALDIR=..
BASEWRFDIR=$CENTRALDIR/basedir

# Get unique name for temporary working directory for this process's stuff
temp_dir='advance_temp'${process}

#shortcuts
REMOVE='/bin/rm -rf'
COPY='cp -p'
MOVE='mv -f'
MKDIR='mkdir -p'


# give the filesystem time to collect itself
sleep 1

# Create a clean temporary directory and go there
\rm -rf  $temp_dir
mkdir -p $temp_dir
cd       $temp_dir

#loop from state_state to end_state numbers, and advance wrf for each state.
#The control file has entries for each state member

state=$start_state

while($state_copy <= $end_state)
   line=($(sed -n "${stat_copy}p;${state_copy}q" | tr ',' ' ))
   ensemble_member=${line[0]}
   filter_input_file=${line[1]}
   filter_input_file=${line[2]}
   wrf_input_file=${line[3]}
   wrf_output_file=${line[4]}

   element=$ensemble_member

   echo "starting ${myname} for ens member $element at "`date`
   echo "CENTRALDIR is ${CENTRALDIR}"
   echo "temp_dir is ${temp_dir}"

   #we're inside the advance_temp directory
   #link the base directory into here.
   ln -sf ${BASERWFDIR}/* .
   #bring in the updated namelist
   pmo update-wrf-time namelist.input.orig ${CENTRALDIR}/wrf.info namelist.input

   # WGL :: need to zero-pad ensemble number to fit [.####]
   ENS_NUM=`printf %4.4i $element`

   ${MOVE} ${CENTRALDIR}/wrfout_d0?_*.${ENS_NUM} .
    if ( $status ) then
	     echo "error with wrfout_d0?"
	     echo ${ENS_NUM} ${CENTRALDIR}
	     ls ${CENTRALDIR}/wrfout_d0?_*.${ENS_NUM} .
	     exit(1)
    fi
   # WGL :: for now just move the d01 file over -- for robustness, we should check for
   #          other present domains
   ${MOVE} wrfout_d01_* wrfinput_d01
    if ( $status ) then
	     echo "error with wrfout_d01"
	      exit(1)
    endif

   ${MOVE} ${CENTRALDIR}/$input_file dart_wrf_vector # ICs for run
   if ( $status ) then
	    echo "error with input_file"
	    exit(1)
    endif
   # Convert DART to wrfinput
   ${CENTRALDIR}/dart_to_wrf > out.dart_to_wrf 2>&1

   #WGL
   sleep 1

   # If model blew up in the previous cycle, the member is now likely an outlier.

   if ( -e ${CENTRALDIR}/blown_${wrfdays}_${wrfsecs}.out ) then
      set MBLOWN = `cat ${CENTRALDIR}/blown_${wrfdays}_${wrfsecs}.out`
      set NBLOWN = `cat ${CENTRALDIR}/blown_${wrfdays}_${wrfsecs}.out | wc -l`
      set BLOWN = 0
      set imem = 1
      while ( $imem <= $NBLOWN )
         if ( $MBLOWN[$imem] == $element ) then
            set BLOWN = `expr $BLOWN \+ 1`
         endif
         set imem = `expr $imem \+ 1`
      end
   endif

   #Extract the required info from wrf.info
   MY_NUM_DOMAINS=`head -4 wrf.info | tail -1`
   ADV_MOD_COMMAND=`head -5 wrf.info | tail -1`

      if ( -e rsl.out.integration ) then
         ${REMOVE} rsl.*
      endif

      # Set off WRF integration
      ${ADV_MOD_COMMAND} >>&! rsl.out.integration
      if ( -e rsl.out.0000 ) cat rsl.out.0000 >> rsl.out.integration
      ${COPY} rsl.out.integration ${CENTRALDIR}/wrf.out_${targdays}_${targsecs}_${element}
      sleep 1

      set SUCCESS = `grep "wrf: SUCCESS COMPLETE WRF" rsl.* | cat | wc -l`
      if ($SUCCESS == 0) then
         echo $element >> ${CENTRALDIR}/blown_${targdays}_${targsecs}.out
         echo "Model failure! Check file " ${CENTRALDIR}/blown_${targdays}_${targsecs}.out
         echo "for a list of failed elements, and check here for the individual output files:"
         echo " ${CENTRALDIR}/wrf.out_${targdays}_${targsecs}_${element}  "
         exit -1
      endif

      set dn = 1
      while ( $dn <= $MY_NUM_DOMAINS )
         ${COPY} wrfout_d0${dn}_${END_YEAR}-${END_DAY}_${END_HOUR}:${END_MIN}:${END_SEC} wrfinput_d0${dn}
         ${MOVE} wrfout_d0${dn}_${END_YEAR}-${END_DAY}_${END_HOUR}:${END_MIN}:${END_SEC} wrfout_d0${dn}_${END_YEAR}-${END_DAY}_${END_HOUR}:${END_MIN}:${END_SEC}.${ENS_NUM}
         set dn = `expr $dn \+ 1`
      end

      # WGL :: get rid of initial wrfout and move unique wrfout files up to work/ directory
#      ${REMOVE} wrfout_d0${dn}_${START_YEAR}-${START_DAY}_${START_HOUR}:${START_MIN}:${START_SEC}
      ${MOVE} wrfout_d0* ${CENTRALDIR}/.


   ##############################################
   # At this point, the target time is reached. #
   ##############################################

   # create new input to DART (taken from "wrfinput")
   ${CENTRALDIR}/wrf_to_dart > out.wrf_to_dart  2>&1

#WGL
sleep 1

   ${MOVE} dart_wrf_vector ${CENTRALDIR}/$output_file

   set state_copy = `expr $state_copy \+ 1`
   set ensemble_member_line = `expr $ensemble_member_line \+ 3`
   set input_file_line = `expr $input_file_line \+ 3`
   set output_file_line = `expr $output_file_line \+ 3`
end



# Change back to working directory and get rid of temporary directory
cd ${CENTRALDIR}
echo ${REMOVE} ${temp_dir}
${REMOVE} ${temp_dir}

# Remove the filter_control file to signal completeion
# Is there a need for any sleeps to avoid trouble on completing moves here?
\rm -rf $control_file
