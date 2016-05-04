%% Reads ECG recording in HL7a format
% Reads ECG recordings in Hl7a format from the Chinese database (CCDD). Implements the
% standard "HL7 aECG Implementation Guide - March 21, 2005" available in: 
% 
% https://www.hl7.org/documentcenter/public_temp_75706E59-1C23-BA17-0C25A0CC0545890C/wg/rcrim/annecg/aECG%20Implementation%20Guide%202005-03-21%20final%203.pdf
% 
% Arguments:
%   + filename: recording to be read.
%   + start_sample: (opt) start sample to read. Default 1.
%   + end_sample: (opt) end sample to read. Default min(All recording, ECG block of 200 Mbytes)
% 
% Output:
%   + ECG: the ECG block
%   + heasig: header with the ECG properties. 
%   + ann: annotations for the ECG recordings.
% 
% Limits:
% This routine is limited to read blocks smaller than 200 Mbytes for
% performance reasons. You can disable this limit by doing:
% MaxIOread = Inf; %megabytes
% 
% See also read_ishne_ann, read_ishne_header, read_ECG, ECGwrapper
% 
% Author: Mariano Llamedo Soria
% <matlab:web('mailto:llamedom@electron.frba.utn.edu.ar','-browser') (email)> 
% Version: 0.1 beta
% Birthdate: 02/05/2016
% Last update: 02/05/2016
% Copyright 2008-2016
% 
function [ ECG, heasig, ann, last_sample ] = read_hl7a_format(filename, start_sample, end_sample)

%% Tables

%% Lead Names
cLeadNamesHL7a = { ...
                    'MDC_ECG_LEAD_CONFIG', 'Unspecified lead', 'Unspecified lead'; ...
                    'MDC_ECG_LEAD_I', 'Lead I', 'Lead I'; ...
                    'MDC_ECG_LEAD_II', 'Lead II', 'Lead II'; ...
                    'MDC_ECG_LEAD_V1', 'Lead V1', 'V1'; ...
                    'MDC_ECG_LEAD_V2', 'Lead V2', 'V2'; ...
                    'MDC_ECG_LEAD_V3', 'Lead V3', 'V3'; ...
                    'MDC_ECG_LEAD_V4', 'Lead V4', 'V4'; ...
                    'MDC_ECG_LEAD_V5', 'Lead V5', 'V5'; ...
                    'MDC_ECG_LEAD_V6', 'Lead V6', 'V6'; ...
                    'MDC_ECG_LEAD_V7', 'Lead V7', 'V7'; ...
                    'MDC_ECG_LEAD_V2R', 'Lead V2R', 'V2R'; ...
                    'MDC_ECG_LEAD_V3R', 'Lead V3R', 'V3R'; ...
                    'MDC_ECG_LEAD_V4R', 'Lead V4R', 'V4R'; ...
                    'MDC_ECG_LEAD_V5R', 'Lead V5R', 'V5R'; ...
                    'MDC_ECG_LEAD_V6R', 'Lead V6R', 'V6R'; ...
                    'MDC_ECG_LEAD_V7R', 'Lead V7R', 'V7R'; ...
                    'MDC_ECG_LEAD_X', 'Lead X', 'X'; ...
                    'MDC_ECG_LEAD_Y', 'Lead Y', 'Y'; ...
                    'MDC_ECG_LEAD_Z', 'Lead Z', 'Z'; ...
                    'MDC_ECG_LEAD_CC5', 'Lead CC5', 'CC5 per V5 and V5R placement'; ...
                    'MDC_ECG_LEAD_CM5', 'Lead CM5', 'CM5 per V5 placement'; ...
                    'MDC_ECG_LEAD_LA', 'Lead LA', 'Left Arm'; ...
                    'MDC_ECG_LEAD_RA', 'Lead RA', 'Right Arm'; ...
                    'MDC_ECG_LEAD_LL', 'Lead LL', 'Left Leg'; ...
                    'MDC_ECG_LEAD_fI', 'Lead I', 'I'; ...
                    'MDC_ECG_LEAD_fE', 'Lead E', 'E'; ...
                    'MDC_ECG_LEAD_fC', 'Lead C', 'C'; ...
                    'MDC_ECG_LEAD_fA', 'Lead A', 'A'; ...
                    'MDC_ECG_LEAD_fM', 'Lead M', 'M'; ...
                    'MDC_ECG_LEAD_fF', 'Lead F', 'F'; ...
                    'MDC_ECG_LEAD_fH', 'Lead H', 'H'; ...
                    'MDC_ECG_LEAD_III', 'Lead III', 'III'; ...
                    'MDC_ECG_LEAD_AVR', 'Lead aVR', 'aVR augmented voltage right'; ...
                    'MDC_ECG_LEAD_AVL', 'Lead aVL', 'aVL augmented voltage left'; ...
                    'MDC_ECG_LEAD_AVF', 'Lead aVF', 'aVF augmented voltage foot'; ...
                    'MDC_ECG_LEAD_AVRneg', 'Lead aVR', '?aVR'; ...
                    'MDC_ECG_LEAD_V8', 'Lead V8', 'V8'; ...
                    'MDC_ECG_LEAD_V9', 'Lead V9', 'V9'; ...
                    'MDC_ECG_LEAD_V8R', 'Lead V8R', 'V8R'; ...
                    'MDC_ECG_LEAD_V9R', 'Lead V9R', 'V9R'; ...
                    'MDC_ECG_LEAD_D', 'Lead D', 'D (Nehb  Dorsal)'; ...
                    'MDC_ECG_LEAD_A', 'Lead A', 'A (Nehb  Anterior)'; ...
                    'MDC_ECG_LEAD_J', 'Lead J', 'J (Nehb  Inferior)'; ...
                    'MDC_ECG_LEAD_DEFIB', 'Lead Defib', 'Defibrillator lead: anterior-lateral'; ...
                    'MDC_ECG_LEAD_EXTERN', 'Lead Extern', 'External pacing lead: anterior-posterior'; ...
                    'MDC_ECG_LEAD_A1', 'Lead A1', 'A1 (Auxiliary unipolar lead #1)'; ...
                    'MDC_ECG_LEAD_A2', 'Lead A2', 'A2 (Auxiliary unipolar lead #2)'; ...
                    'MDC_ECG_LEAD_A3', 'Lead A3', 'A3 (Auxiliary unipolar lead #3)'; ...
                    'MDC_ECG_LEAD_A4', 'Lead A4', 'A4 (Auxiliary unipolar lead #4)'; ...
                    'MDC_ECG_LEAD_C', 'Lead Chest', 'Chest lead'; ...
                    'MDC_ECG_LEAD_V', 'Lead V', 'Precordial lead'; ...
                    'MDC_ECG_LEAD_VR', 'Lead VR', 'VR nonaugmented voltage vector of RA'; ...
                    'MDC_ECG_LEAD_VL', 'Lead VL', 'VL nonaugmented voltage vector of LA'; ...
                    'MDC_ECG_LEAD_VF', 'Lead VF', 'VF nonaugmented voltage vector of LL'; ...
                    'MDC_ECG_LEAD_MCL', 'Lead MCL', 'Modified chest lead (left arm indifferent)'; ...
                    'MDC_ECG_LEAD_MCL1', 'Lead MCL1', 'MCL per V1 placement'; ...
                    'MDC_ECG_LEAD_MCL2', 'Lead MCL2', 'MCL per V2 placement'; ...
                    'MDC_ECG_LEAD_MCL3', 'Lead MCL3', 'MCL per V3 placement'; ...
                    'MDC_ECG_LEAD_MCL4', 'Lead MCL4', 'MCL per V4 placement'; ...
                    'MDC_ECG_LEAD_MCL5', 'Lead MCL5', 'MCL per V5 placement'; ...
                    'MDC_ECG_LEAD_MCL6', 'Lead MCL6', 'MCL per V6 placement'; ...
                    'MDC_ECG_LEAD_CC', 'Lead CC', 'Chest lead (symmetric placement)'; ...
                    'MDC_ECG_LEAD_CC1', 'Lead CC1', 'CC1 per V1 and V1R placement'; ...
                    'MDC_ECG_LEAD_CC2', 'Lead CC2', 'CC2 per V2 and V2R placement'; ...
                    'MDC_ECG_LEAD_CC3', 'Lead CC3', 'CC3 per V3 and V3R placement'; ...
                    'MDC_ECG_LEAD_CC4', 'Lead CC4', 'CC4 per V4 and V4R placement'; ...
                    'MDC_ECG_LEAD_CC6', 'Lead CC6', 'CC6 per V6 and V6R placement'; ...
                    'MDC_ECG_LEAD_CC7', 'Lead CC7', 'CC7 per V7 and V8R placement'; ...
                    'MDC_ECG_LEAD_CM', 'Lead CM', 'Chest-manubrium'; ...
                    'MDC_ECG_LEAD_CM1', 'Lead CM1', 'CM1 per V1 placement'; ...
                    'MDC_ECG_LEAD_CM2', 'Lead CM2', 'CM2 per V2 placement'; ...
                    'MDC_ECG_LEAD_CM3', 'Lead CM3', 'CM3 per V3 placement'; ...
                    'MDC_ECG_LEAD_CM4', 'Lead CM4', 'CM4 per V4 placement'; ...
                    'MDC_ECG_LEAD_CM6', 'Lead CM6', 'CM6 per V6 placement'; ...
                    'MDC_ECG_LEAD_CM7', 'Lead CM7', 'CM7 per V7 placement'; ...
                    'MDC_ECG_LEAD_CH5', 'Lead CH5', '-'; ...
                    'MDC_ECG_LEAD_CS5', 'Lead CS5', 'negative: right infraclavicular fossa'; ...
                    'MDC_ECG_LEAD_CB5', 'Lead CB5', 'negative: low right scapula'; ...
                    'MDC_ECG_LEAD_CR5', 'Lead CR5', '-'; ...
                    'MDC_ECG_LEAD_ML', 'Lead ML', 'ML modified limb lead ~ Lead II'; ...
                    'MDC_ECG_LEAD_AB1', 'Lead AB1', 'AB1 (auxiliary bipolar lead #1)'; ...
                    'MDC_ECG_LEAD_AB2', 'Lead AB2', 'AB2 (auxiliary bipolar lead #2)'; ...
                    'MDC_ECG_LEAD_AB3', 'Lead AB3', 'AB3 (auxiliary bipolar lead #3)'; ...
                    'MDC_ECG_LEAD_AB4', 'Lead AB4', 'AB4 (auxiliary bipolar lead #4)'; ...
                    'MDC_ECG_LEAD_ES', 'Lead ES', 'EASI ES'; ...
                    'MDC_ECG_LEAD_AS', 'Lead AS', 'EASI AS'; ...
                    'MDC_ECG_LEAD_AI', 'Lead AI', 'EASI AI'; ...
                    'MDC_ECG_LEAD_S', 'Lead S', 'EASI upper sternum lead'; ...
                    'MDC_ECG_LEAD_dI', 'Lead dI', 'derived lead I'; ...
                    'MDC_ECG_LEAD_dII', 'Lead dII', 'derived lead II'; ...
                    'MDC_ECG_LEAD_dIII', 'Lead dIII', 'derived lead III'; ...
                    'MDC_ECG_LEAD_daVR', 'Lead daVR', 'derived lead aVR'; ...
                    'MDC_ECG_LEAD_daVL', 'Lead daVL', 'derived lead aVL'; ...
                    'MDC_ECG_LEAD_daVF', 'Lead daVF', 'derived lead aVF'; ...
                    'MDC_ECG_LEAD_dV1', 'Lead dV1', 'derived lead V1'; ...
                    'MDC_ECG_LEAD_dV2', 'Lead dV2', 'derived lead V2'; ...
                    'MDC_ECG_LEAD_dV3', 'Lead dV3', 'derived lead V3'; ...
                    'MDC_ECG_LEAD_dV4', 'Lead dV4', 'derived lead V4'; ...
                    'MDC_ECG_LEAD_dV5', 'Lead dV5', 'derived lead V5'; ...
                    'MDC_ECG_LEAD_dV6', 'Lead dV6', 'derived lead V6'; ...
                    'MDC_ECG_LEAD_RL', 'Lead RL', 'right leg'; ...
                    'MDC_ECG_LEAD_CV5RL', 'Lead CV5RL', 'Canine fifth right intercostals space near the edge of the sternum at the most curved part of the costal cartilage'; ...
                    'MDC_ECG_LEAD_CV6LL', 'Lead CV6LL', 'Canine sixth left intercostals space near the edge of the sternum at the most curved part of the costal cartilage'; ...
                    'MDC_ECG_LEAD_CV6LU', 'Lead CV6LU', 'Canine sixth left intercostals space at the costochondral junction'; ...
                    'MDC_ECG_LEAD_V10', 'Lead V10', 'Canine over dorsal spinous process of the seventh thoracic vertebra'; ...
                    };

%% Wave Names

cWaveNamesHL7a = { ...
                    'MDC_ECG_WAVC_PWAVE', 'P wave', 'P wave'; ...
                    'MDC_ECG_WAVC_PPWAVE', 'P wave', 'P wave (second deflection in P wave) (P and P waves have opposite signs)'; ...
                    'MDC_ECG_WAVC_PPPWAVE', 'P wave', 'P wave (third deflection in P wave) (P and P waves have opposite signs)'; ...
                    'MDC_ECG_WAVC_QWAVE', 'Q wave', 'Q wave'; ...
                    'MDC_ECG_WAVC_QSWAVE', 'QS wave', 'QS wave'; ...
                    'MDC_ECG_WAVC_RWAVE', 'R wave', 'R wave'; ...
                    'MDC_ECG_WAVC_RRWAVE', 'R wave', 'R wave (second deflection in R Wave) (R and R have same sign)'; ...
                    'MDC_ECG_WAVC_RRRWAVE', 'R wave', 'R wave (third deflection in R Wave) (R, R and R have same sign)'; ...
                    'MDC_ECG_WAVC_NOTCH', 'Notch Notch,', 'a slight but distinct change in the direction of a WAVC deflection, contained entirely within that deflection. Typically associated with Q-, R- and/or S-wave.'; ...
                    'MDC_ECG_WAVC_SWAVE', 'S wave', 'S wave (S and R/R waves have opposite signs)'; ...
                    'MDC_ECG_WAVC_SSWAVE', 'S wave', 'S wave (second deflection in S Wave) (S and R/R waves have opposite signs)'; ...
                    'MDC_ECG_WAVC_SSSWAVE', 'S wave', 'S wave (third deflection in S Wave) (S and R/R waves have opposite signs)'; ...
                    'MDC_ECG_WAVC_TWAVE', 'T wave', 'T wave'; ...
                    'MDC_ECG_WAVC_TTWAVE', 'T wave', 'T wave (second deflection in T Wave) (T and T waves have opposite signs)'; ...
                    'MDC_ECG_WAVC_UWAVE', 'U wave', 'U wave'; ...
                    'MDC_ECG_WAVC_DELTA', 'Delta wave', 'Delta wave'; ...
                    'MDC_ECG_WAVC_IWAVE', 'I wave', 'Isoelectric region between global QRS onset and actual onset of QRS in given lead'; ...
                    'MDC_ECG_WAVC_KWAVE', 'K wave', 'Isoelectric region between actual offset of QRS in given lead and global QRS offset'; ...
                    'MDC_ECG_WAVC_JWAVE', 'J wave', 'Osborne wave, late and typically upright terminal deflection of QRS complex; amplitude increases as temperature declines. ECG finding typically associated with hypothermia.'; ...
                    'MDC_ECG_WAVC_PQRSTWAVE', 'PQRST wave', 'Entire Beat (Pon to Toff, excluding U)'; ...
                    'MDC_ECG_WAVC_QRSTWAVE', 'QRST wave', 'Entire Beat (Qon to Toff, excluding P and U)'; ...
                    'MDC_ECG_WAVC_QRSWAVE', 'QRS wave', 'Entire QRS (excluding P, T and U)'; ...
                    'MDC_ECG_WAVC_TUWAVE', 'TU wave', 'TU fused wave'; ...
                    'MDC_ECG_WAVC_VFLWAVE', 'V flutter', 'wave Ventricular flutter wave (optional) (the appropriate ventricular rhythm call is mandatory)'; ...
                    'MDC_ECG_WAVC_AFLWAVE', 'Atrial flutter', 'wave Atrial flutter wave (optional) (the appropriate atrial rhythm call is mandatory)'; ...
                    'MDC_ECG_WAVC_ISO', 'Isoelectric point', 'Isoelectric point or segment'; ...
                    'MDC_ECG_WAVC_PRSEG', 'PR Segment', 'PR Segment'; ...
                    'MDC_ECG_WAVC_STSEG', 'ST Segment', 'ST Segment'; ...
                    'MDC_ECG_WAVC_STJ', 'J-point', 'J-point'; ...
                    'MDC_ECG_WAVC_STM', 'ST meas', 'point ST measurement point'; ...
                    'MDC_ECG_WAVC_ARFCT', 'Artifact Isolated', 'qrs-like artifact'; ...
                    'MDC_ECG_WAVC_CALP', 'Calibration pulse', 'Calibration pulse (individual pulse)'; ...
                    'MDC_ECG_WAVC_STCH', 'ST change', 'ST change'; ...
                    'MDC_ECG_WAVC_TCH', 'T-wave change', 'T-wave change'; ...
                    'MDC_ECG_WAVC_VAT', 'Ventricular Activation', 'Time Ventricular Activation Time also termed the intrinsic (or intrinsicoid) deflection onset to peak of depolarization wave.'; ...
                    };

%% Beat types

% The second column is an arbitrary asignation of HL7a beats to AAMI EC-57
% standard.
cBeatTypesHL7a = { ...
                    'MDC_ECG_BEAT', 'Q', 'Any beat (unspecified; included in heart rate)'; ...
                    'MDC_ECG_BEAT_NORMAL', 'N', 'Normal Beat Normal beat (sinus beat normal conduction)'; ...
                    'MDC_ECG_BEAT_ABNORMAL', 'Q', 'Abnormal Beat Abnormal beat'; ...
                    'MDC_ECG_BEAT_DOMINANT', 'Q', 'Dominant Beat Dominant beat (typically normal but may not be) (predominant morphology typically used for ST measurement)'; ...
                    'MDC_ECG_BEAT_SV_P_C', 'S', 'Supraventricular premature contraction Supraventricular premature contraction (atrial or nodal premature beat with normal QRS morphology)'; ...
                    'MDC_ECG_BEAT_ATR_P_C', 'S', 'Atrial Premature contraction Atrial premature contraction (beat)'; ...
                    'MDC_ECG_BEAT_JUNC_P_C', 'S', 'Junctional premature contraction Junctional (nodal) premature contraction'; ...
                    'MDC_ECG_BEAT_ATR_P_C_ABER', 'S', 'Aberrated atrial premature beat Aberrated atrial premature beat (Ashman beat) (atrial premature beat with abnormal QRS morphology)'; ...
                    'MDC_ECG_BEAT_R', 'S', 'Aberrated atrial premature beat Aberrated atrial premature beat (Ashman beat) (atrial premature beat with abnormal QRS morphology)'; ...
                    'MDC_ECG_BEAT_ATR_PWAVE_B', 'Q', 'Non-conducted p-wave Non-conducted p-wave (blocked)'; ...
                    'MDC_ECG_BEAT_LK', 'Q', 'Non-conducted p-wave Non-conducted p-wave (blocked)'; ...
                    'MDC_ECG_BEAT_V_P_C', 'V', 'Ventricular premature contraction Ventricular premature contraction (beat)'; ...
                    'MDC_ECG_BEAT_V_P_C_FUSION', 'F', 'Fusion of ventricular and normal beat Fusion of ventricular and normal beat'; ...
                    'MDC_ECG_BEAT_V_P_C_RonT', 'V', 'R-on-T premature ventricular beat R-on-T premature ventricular beat'; ...
                    'MDC_ECG_BEAT_SV_ESC', 'S', 'Supraventricular escape beat (least specific)'; ...
                    'MDC_ECG_BEAT_ATR_ESC', 'S', 'Atrial escape beat'; ...
                    'MDC_ECG_BEAT_JUNC_ESC', 'S', 'Junctional (nodal) escape beat'; ...
                    'MDC_ECG_BEAT_V_ESC', 'V', 'Ventricular escape beat'; ...
                    'MDC_ECG_BEAT_BB_BLK', 'N', 'bundle branch block beat (unspecified)'; ...
                    'MDC_ECG_BEAT_LBB_BLK_COMP', 'N', 'left bundle branch block beat'; ...
                    'MDC_ECG_BEAT_LBB_BLK_INCOMP', 'N', 'incomplete left bundle branch block beat'; ...
                    'MDC_ECG_BEAT_RBB_BLK_COMP', 'N', 'right bundle branch block beat'; ...
                    'MDC_ECG_BEAT_RBB_BLK_INCOMP', 'N', 'incomplete right bundle branch block beat'; ...
                    'MDC_ECG_BEAT_BLK_ANT_L_HEMI', 'N', 'left anterior fascicular block beat (common)'; ...
                    'MDC_ECG_BEAT_BLK_POS_L_HEMI', 'N', 'left posterior fascicular block beat (rare)'; ...
                    'MDC_ECG_BEAT_BLK_BIFASC', 'N', 'bifascicular block beat'; ...
                    'MDC_ECG_BEAT_BLK_TRIFASC', 'N', 'trifascicular block beat'; ...
                    'MDC_ECG_BEAT_BLK_BILAT', 'N', 'bilateral bundle-branch block beat'; ...
                    'MDC_ECG_BEAT_BLK_IVCD', 'N', 'intraventricular conduction disturbance (non-specific block)'; ...
                    'MDC_ECG_BEAT_PREX', 'Q', 'pre-excitation (least specific)'; ...
                    'MDC_ECG_BEAT_WPW_UNK', 'Q', 'Wolf-Parkinson-White syndrome (less specific)'; ...
                    'MDC_ECG_BEAT_WPW_A', 'Q', 'Wolf-Parkinson type A'; ...
                    'MDC_ECG_BEAT_WPW_B', 'Q', 'Wolf-Parkinson type B'; ...
                    'MDC_ECG_BEAT_LGL', 'Q', 'Lown-Ganong-Levine syndrome'; ...
                    'MDC_ECG_BEAT_PACED', 'Q', 'Paced beat (with ventricular capture)'; ...
                    'MDC_ECG_BEAT_PACED_FUS', 'Q', 'Pacemaker Fusion beat'; ...
                    'MDC_ECG_BEAT_UNKNOWN', 'Q', 'Unclassifiable beat'; ...
                    'MDC_ECG_BEAT_LEARN', 'Q', 'Learning (beat during initial learning phase)'; ...
                    };

%% Code
%No leer bloques mas grandes de 200 megabytes
MaxIOread = 200; %megabytes

if( nargin < 2 || isempty( start_sample ) )
    start_sample = 1;
else
    start_sample = max(1,start_sample);
end

ann = [];
heasig = [];
ECG = [];
last_sample = [];

if( nargout > 1 )
    bHeaderRequired = true;
else
    bHeaderRequired = false;
end

if( nargout > 2 )
    bAnnRequired = true;
else
    bAnnRequired = false;
end

try
   xDoc = xmlread(filename);
catch
    error('read_hl7a_format:ReadError', 'Failed to read XML file %s.\n', filename);
end

% get series in the file
allSeries = xDoc.getElementsByTagName('series');

if(allSeries.getLength == 0)
    error('read_hl7a_format:NoSeries', 'No series found in %s.\n', filename);
elseif(allSeries.getLength > 1)
    warning('read_hl7a_format:MoreSeries', 'More than one serie in %s. Reading only the first one.\n', filename);
end

allSeries = allSeries.item(0);

if(bHeaderRequired)

    [~, heasig.recname ] = fileparts(filename);

    etime = allSeries.getElementsByTagName('effectiveTime');
    etime = etime.item(0);

    loww = etime.getElementsByTagName('low');
    loww = loww.item(0);
    la = loww.getAttributes;
    la = la.item(0);
    low_val = char(la.getValue);

    loww = etime.getElementsByTagName('high');
    loww = loww.item(0);
    la = loww.getAttributes;
    la = la.item(0);
    high_val = char(la.getValue);

    if( length(low_val) == 14 )
        heasig.bdate = [ low_val(1:4) '/' low_val(5:6) '/' low_val(7:8) ];
        heasig.btime = [ low_val(9:10) ':' low_val(11:12) ':' low_val(13:14) ];
    else
        % unknown generic date
        heasig.btime = '00:00:00';
        heasig.bdate = '01/01/2000';
    end
    
end
    
%% Signal Parsing

sequenceSet = allSeries.getElementsByTagName('sequenceSet');
sequenceSet = sequenceSet.item(0);

allComponents = sequenceSet.getElementsByTagName('component');

heasig.nsig = allComponents.getLength-1;
heasig.desc = cell(heasig.nsig,1);
heasig.adczero = zeros(heasig.nsig,1);
heasig.gain = ones(heasig.nsig,1);
heasig.units = cell(heasig.nsig,1);

lead_idx = 1;

for ii = 0:(allComponents.getLength-1)

    thisComp = allComponents.item(ii);
    
    allVals = thisComp.getElementsByTagName('value');
    
    thisVal = allVals.item(0);
    
    thisVal_att = thisVal.getAttributes;
    
    for jj = 0:(thisVal_att.getLength-1)
       
        this_att = thisVal_att.item(jj);

        aux_val = char(this_att.getValue);
        
        if( strcmpi(aux_val, 'SLIST_PQ') )
        %% ECG leads
            
            if(bHeaderRequired)
        
                %% ADC level
                thisOrig = thisVal.getElementsByTagName('origin');
                thisOrig = thisOrig.item(0);

                thisOrig_att = thisOrig.getAttributes;

                for kk = 0:(thisOrig_att.getLength-1)

                    this_att = thisOrig_att.item(kk);
                    heasig.adczero(lead_idx) = 1;

                    aux_val = this_att.getName;

                    if( strcmpi(aux_val, 'value') )
                        heasig.adczero(lead_idx) = heasig.adczero(lead_idx) * str2double(char(this_att.getValue));

                    elseif( strcmpi(aux_val, 'unit') )

                        aux_val = char(this_att.getValue);

                        switch(aux_val)
                            case 'V'
                                heasig.adczero(lead_idx) = heasig.adczero(lead_idx) ;
                            case 'mV'
                                heasig.adczero(lead_idx) = heasig.adczero(lead_idx) * 1e-3;
                            case 'uV'
                                heasig.adczero(lead_idx) = heasig.adczero(lead_idx) * 1e-6;
                            otherwise
                                error('read_hl7a_format:ParseError', 'Parse error at %s. Check lead %d <origin unit = %s\n', filename, lead_idx, aux_val);
                        end
                    else
                        error('read_hl7a_format:ParseError', 'Parse error at %s. Check lead %d, attribute %s:%s\n', filename, lead_idx, char(this_att.getName), char(this_att.getValue));
                    end

                end            

                %% ADC Gain

                thisScale = thisVal.getElementsByTagName('scale');
                thisScale = thisScale.item(0);

                thisScale_att = thisScale.getAttributes;        

                thisScale_att = thisScale.getAttributes;

                for kk = 0:(thisScale_att.getLength-1)

                    this_att = thisScale_att.item(kk);
                    heasig.gain(lead_idx) = 1;

                    aux_val = this_att.getName;

                    if( strcmpi(aux_val, 'value') )
                        heasig.gain(lead_idx) = heasig.gain(lead_idx) * 1/str2double(this_att.getValue);

                    elseif( strcmpi(aux_val, 'unit') )

                        aux_val = char(this_att.getValue);
                        heasig.units{lead_idx} = aux_val;

    %                     switch(aux_val)
    %                         case 'V'
    %                             heasig.gain(lead_idx) = heasig.gain(lead_idx) ;
    %                         case 'mV'
    %                             heasig.gain(lead_idx) = heasig.gain(lead_idx) * 1e-3;
    %                         case 'uV'
    %                             heasig.gain(lead_idx) = heasig.gain(lead_idx) * 1e-6;
    %                         case 'nV'
    %                             heasig.gain(lead_idx) = heasig.gain(lead_idx) * 1e-9;
    %                         otherwise
    %                             error('read_hl7a_format:ParseError', 'Parse error at %s. Check lead %d <scale unit = %s\n', filename, lead_idx, aux_val);
    %                     end
                    else
                        error('read_hl7a_format:ParseError', 'Parse error at %s. Check lead %d, attribute %s:%s\n', filename, lead_idx, char(this_att.getName), char(this_att.getValue));
                    end

                end                     

    %             <origin value="0" unit="uV" />
    %             <scale value="4.76837" unit="uV" />
    %             digits

                %% Lead name

                thisCode = thisComp.getElementsByTagName('code');
                thisCode = thisCode.item(0);

                thisCode_att = thisCode.getAttributes;        

                for kk = 0:(thisCode_att.getLength-1)

                    this_att = thisCode_att.item(kk);

                    aux_val = this_att.getName;

                    if( strcmpi(aux_val, 'code') )
                        [aux_val, aux_idx ]= intersect(upper(cLeadNamesHL7a(:,1)), upper(char(this_att.getValue)));

                        if( isempty(aux_idx) )
                            error('read_hl7a_format:ParseError', 'Unknown lead name at %s. Check lead %s.\n', filename, char(this_att.getValue));
                        else
                            heasig.desc(lead_idx) = cLeadNamesHL7a(aux_idx,2);
                        end
                    end

                end                     

            end
            %% Data samples
            
            thisDigits = thisVal.getElementsByTagName('digits');
            thisDigits = thisDigits.item(0);            

            if( isempty(ECG) )
                ECG(:,lead_idx) = colvec(str2num(thisDigits.getTextContent));
                heasig.nsamp = size(ECG,1);
            else
                ECG(1:heasig.nsamp,lead_idx) = colvec(str2num(thisDigits.getTextContent));
            end
            
            lead_idx = lead_idx + 1;
            
        elseif( strcmpi(aux_val, 'GLIST_TS') )
        %% time sequence -> sampling rate
            if(bHeaderRequired)
        
                thisInc = thisVal.getElementsByTagName('increment');
                thisInc = thisInc.item(0);

                thisInc_att = thisInc.getAttributes;

                for kk = 0:(thisInc_att.getLength-1)

                    this_att = thisInc_att.item(kk);
                    heasig.freq = 1;

                    aux_val = char(this_att.getName);

                    if( strcmpi(aux_val, 'value') )
                        heasig.freq = 1/str2double(this_att.getValue);
                    elseif( strcmpi(aux_val, 'unit') )
                        aux_val = char(this_att.getValue);
                        switch(aux_val)
                            case 's'
                                heasig.freq = heasig.freq;
                            case 'ms'
                                heasig.freq = heasig.freq * 1e3;
                            case 'us'
                                heasig.freq = heasig.freq * 1e6;
                            otherwise
                                error('read_hl7a_format:ParseError', 'Parse error at %s. Check unit = %s\n', filename, aux_val);
                        end
                    else
                        error('read_hl7a_format:ParseError', 'Parse error at %s. Check %s:%s\n', filename, aux_val, char(this_att.getValue));
                    end

                end
            end
        end
        
    end
    
end

heasig.desc = char(heasig.desc);
heasig.units = char(heasig.units);

%% Annotations parsing

if(bAnnRequired)
    
end

