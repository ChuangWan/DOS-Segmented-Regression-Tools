% Create input variables
sheetNames = {'1010',...
                '1005',...
                '1014',...
                '1020',...
                '1001',...
                '1003',...
                '1002',...
                '1009',...
                '1013',...
                '1006',...
                '1007',...
                '1011',...
                '1004',...
                '1012',...
                '1015',...
                '1016',...
                '1017',...
                '1018',...
                '1019',...
                '1021',...
                '1022',...
                '1023',...
                '1025',...
                '1024',...
                '1008'};

endRows = [529
            463
            859
            463
            463
            463
            463
            529
            463
            463
            463
            397
            463
            595
            595
            331
            463
            529
            397
            463
            397
            397
            463
            529
            463];

% Create collection variables
peakVO2 = zeros(25,1);
peakRQ  = zeros(25,1);
peakHR  = zeros(25,1);

coef_HR = zeros(25,1);
coef_Work = zeros(25,1);
coef_VO2 = zeros(25,1);
coef_VCO2 = zeros(25,1);
coef_RQ = zeros(25,1);

delta_HR = zeros(25,1);
delta_Work = zeros(25,1);
delta_VO2 = zeros(25,1);
delta_VCO2 = zeros(25,1);
delta_RQ = zeros(25,1);


% File loop
for iFile = 1:25        
    % Import
    workbookFile = 'PS work rate calculations.xlsx';
    sheetName = sheetNames{iFile};
    startRow = 12;
    endRow = endRows(iFile);

    [TimeSec,HR,Work,VO2,VO2kg,VCO2,RQ,VEbtps,RTrest,Level] = ...
        importTemp(workbookFile,sheetName,startRow,endRow);


    % Flag rows for level E or "Exercise" challenge, called 'idx'
    idx = false(length(TimeSec),1);
    for iRow = 1:length(TimeSec)
        if isequal(Level{iRow},'E')
            idx(iRow) = true(1);
        end
    end

    % Take time from exercise level
    Time = TimeSec(idx);
    
    % Subset data from other variables of interest with exercise level
    exe_HR = HR(idx);
    exe_Work = Work(idx);
    exe_VO2 = VO2(idx); 
    exe_VO2_kg = VO2_kg(idx);
    exe_VCO2 = VCO2(idx);
    exe_RQ = RQ(idX);
    

    % Convert time values to decimals of exercise, simply called 'TimeSec_exe'
    TimeSec_exe = zeros(length(Time),1);
    TimeSec_formatted = cell(length(Time),1);
    for iRow = 1:length(Time)
        currentRow = datestr(Time(iRow) + 693960, 13);
        currentRow = str2double(regexp(currentRow,':','split'));
        currentRow = currentRow*[60^2;60;1];
        TimeSec_exe(iRow) = currentRow;
        TimeSec_formatted{iRow} = datestr(Time(iRow) + 693960, 13);
    end


    % Window data to remove noise
    windowlength = 20;
    windowhalflength = windowlength*0.5;
    % reinitialize windowmean collection var
    windowmean = zeros(1,length(TimeSec_exe)); 
    % sliding window
    for iRow = 1:length(TimeSec_exe) 
        if TimeSec_exe(iRow) >= windowhalflength && ...
                TimeSec_exe(iRow) <= (max(TimeSec_exe)-windowhalflength);
            lowerValue = TimeSec_exe(iRow) - windowhalflength;
            upperValue = TimeSec_exe(iRow) + windowhalflength;
            [~,idxLower] = min(abs(TimeSec_exe-lowerValue));
            [~,idxUpper] = min(abs(TimeSec_exe-upperValue));
            % Mean Time
            windowmean(iRow) = mean(exe_VO2(idxLower:idxUpper)); 
        else
            windowmean(iRow) = NaN; 
        end
    end
    
    % Get peak values
    peakVO2(iFile) = max(windowmean);
    peakRQ(iFile)  = max(RQ(idx));
    peakHR(iFile)  = max(HR);
    
    
    % Determine time at 50% VO2 peak, called 'TimeSec_exe_halfpeak'
    [~,idx_peakVO2] = max(windowmean);
    idx_halfpeakVO2 = ceil(idx_peakVO2*0.5);
    TimeSec_exe_halfpeak = TimeSec_exe(idx_halfpeakVO2);
    
    
    % Get slope of data from 0 to 50% VO2 peak
    coef_HR = polyfit(TimeSec_exe(0:idx_halfpeakVO2),...
                exe_HR(0:idx_halfpeakVO2),2);
    coef_Work = polyfit(TimeSec_exe(0:idx_halfpeakVO2),...
                    exe_Work(0:idx_halfpeakVO2),2);
    coef_VO2 = polyfit(TimeSec_exe(0:idx_halfpeakVO2),...
                    exe_VO2(0:idx_halfpeakVO2),2);                
    coef_VCO2 = polyfit(TimeSec_exe(0:idx_halfpeakVO2),...
                    exe_CVO2(0:idx_halfpeakVO2),2);
    coef_RQ = polyfit(TimeSec_exe(0:idx_halfpeakVO2),...
                    exe_RQ(0:idx_halfpeakVO2),2);
                 
                
    % Get delta value for data of interest from other variables
    delta_HR = exe_HR(idx_halfpeakVO2)-exe_HR(1);
    delta_Work = exe_Work(idx_halfpeakVO2)-exe_Work(1);
    delta_VO2 = exe_VO2(idx_halfpeakVO2)-exe_VO2(1);
    delta_VCO2 = exe_VCO2(idx_halfpeakVO2)-exe_VCO2(1);
    delta_RQ = exe_RQ(idx_healfpeakVO2)-exe_RQ(1);
    

end % end file loop