classdef ImportF< handle
    % class import data from file, preprocess and show
    % CTU UCEEB, Petr Wolf
    % Last modified: 14.06.2019
    % Version hist.:
    
    
    properties
        
        dataTT %original loaded data timetable
        dataMin = Profile % object Profile  imported data adjusted to minutes
        dataMinOrig = Profile% keep original imported data adjusted to minutes
        %Sel1=1 %All, Weekends,Weekdays
        %Sel2='hours' %Aggregate Original,Minutes,Hours,Days,Months
        %Sel3 ='mean' %aggregate type: mean,sum
        
        
    end
    
    properties (Dependent)
        %  Agg_sum         %hourly, daily,monthly, annual aggregation (sum)
        
    end
    
    
    %properties (Access = protected)
    %end
    
    %properties (Constant)
    %end
    
    
    
    %%
    methods
        
        %% Construct an instance of this class
        function obj = ImportF()  %
            % obj.Profile1 = timetable(); %(NaT,NaN);
            obj.dataMin = Profile(); % object Profile  imported data adjusted to minutes
            obj.dataMinOrig = Profile(); % keep original imported data adjusted to minutes
            
        end
        
        
        
        
        
        %% Button CHOOSE FILE
        function dataMin1 = ImportFile(obj, app)
            
            data1=[];
            statTxt1=[];
            try
                [file1,path1 ]= uigetfile(['pwd', '\*.*' ],'Choose import data file') ;% choose directory
                %selpath ='C:\Users\wolf\Documents\MATLAB\ENEWI\OOP_test\ELoadsData' ;
                pathFile=[path1, file1];
                
                fileID = fopen(pathFile);
                
                data1=textscan(fileID, '%f') ;%reads only numerical data
                data1=data1{:};
                
                fclose(fileID);
                
                
                statTxt1= ['File: ', file1,  ' Number of numeric data read: ' , num2str(numel(data1)) ];
                app.ImportstatusLabel.Text= statTxt1;
                
            catch %ProblemOccured
                warning('Problem reading the file')
                %import status:
                statTxt1= 'Problem reading the file';
                app.ImportstatusLabel.Text= statTxt1;
                
                data1=[];
            end
            
            %import status:
            disp(statTxt1)
            
            % data1 = data from file row vector
            
            %% time resolution. Radio button: seconds, minutes, hours
            try
            start_datetime= datetime ( app.StartdatetimeEditField.Value,  'InputFormat', 'dd/MM/yyyy HH:mm:ss');   %app.StartdatetimeEditField.  %datetime ('24/09/2014 12:45:50', 'InputFormat', 'dd/MM/yyyy HH:mm:ss');
            catch % wrong input datetime format
               start_datetime=  datetime ( 'now',  'InputFormat', 'dd/MM/yyyy HH:mm:ss');
            end
                
            if app.SecondsButton.Value==true
                TimeResolution = 1;
            elseif app.MinutesButton.Value==true
                TimeResolution = 2;
            elseif app.HoursButton.Value==true
                TimeResolution = 3;
            elseif app.HoursLinButton.Value==true
                TimeResolution = 4;
            else
                warning('no selection')
                
            end
            
            
            switch TimeResolution
                
                case 1 % seconds> aggregation mean
                    start_datetime= dateshift(start_datetime, 'start', 'minute', 'previous');
                    elements= numel(data1);
                    duration1=seconds;%seconds, minutes, hours
                    times1 = start_datetime:duration1: start_datetime+duration1*(elements-1);
                    dataTT1=  timetable(times1', data1); %data timetable
                    dataMin1= synchronize(dataTT1,  'regular',  'mean','TimeStep',minutes) ;%fits to exact minutes, mean
                    
                case 2 %minutes> no change
                    start_datetime= dateshift(start_datetime, 'start', 'minute', 'nearest');
                    elements= numel(data1);
                    duration1=minutes;%seconds, minutes, hours
                    times1 = start_datetime:duration1: start_datetime+duration1*(elements-1);
                    dataTT1=  timetable(times1', data1); %data timetable
                    dataMin1= dataTT1;  %  synchronize(dataTT,  'regular',  'nearest','TimeStep',minutes) %fits to exact minutes, neares minute neighbor
                    
                case 3 %hours rep> replicate
                    start_datetime= dateshift(start_datetime, 'start', 'hour', 'previous');
                    elements= numel(data1);
                    duration1=hours;%seconds, minutes, hours
                    times1 = start_datetime:duration1: start_datetime+duration1*(elements-1);
                    dataTT1=  timetable(times1', data1); %data timetable
                    dataMin1= synchronize(dataTT1,  'regular',  'previous','TimeStep',minutes); %fits to exact minutes, neares minute neighbor
                    
                    
                case 4 %hours linfit> linear fit
                    start_datetime= dateshift(start_datetime, 'start', 'hour', 'previous');
                    elements= numel(data1);
                    duration1=hours;%seconds, minutes, hours
                    times1 = start_datetime:duration1: start_datetime+duration1*(elements-1);
                    dataTT1=  timetable(times1', data1); %data timetable
                    dataMin1= synchronize(dataTT1,  'regular',  'linear','TimeStep',minutes) ;%fits to exact minutes, linear fit
                    
            end
            
            obj.dataTT=dataTT1;
            
            obj.dataMin.Profile1 = dataMin1; % OUTPUT OBJECT VARIABLE
            obj.dataMinOrig.Profile1=dataMin1; % OUTPUT OBJECT VARIABLE TO RESTORE ORIGINAL VALUES
            
            
            
        end
        
        %% Data preprocessing
        function AddK(obj,K)
            obj.dataMin.Profile1{:,1} = obj.dataMin.Profile1{:,1} +K; % add K
        end
        
        function MultiplyK(obj,K)
            obj.dataMin.Profile1{:,1} = obj.dataMin.Profile1{:,1} .*K; % multiply by K
        end
        
        function RestoreOrig(obj)
            obj.dataMin.Profile1 =obj.dataMinOrig.Profile1;
            
        end
        
        function FilterFrom(obj, from1)
            obj.dataMin.Profile1 = obj.dataMin.Profile1 ( obj.dataMin.Profile1.Time>=from1, :);
        end
        
        function FilterTo(obj, from1)
            obj.dataMin.Profile1 = obj.dataMin.Profile1 ( obj.dataMin.Profile1.Time<=from1, :);
        end
        
        function FilterGreaterThan(obj, k,repl)
            sel = (obj.dataMin.Profile1{:,1}>k);
            obj.dataMin.Profile1{sel,1} = repl;
        end
        
        function FilterLessThan(obj, k,repl)
            sel = (obj.dataMin.Profile1{:,1}<k);
            obj.dataMin.Profile1{sel,1} = repl;
        end
        
        %% reset Data
        function ResetData(obj)
            obj.dataMin.Profile1 =timetable();
        end
        
        
        %% Data plot SHOW1
        function Show1(obj, app)
            %prepare the data
            cla(app.UIAxesImp)
            if ~isempty(obj.dataMin.Profile1)
            
            %timeScale= original, minutes, hours, days, months
            if app.OriginalButton_2.Value==true
                timeScale = 'original';
            elseif app.MinutesButton_2.Value==true
                timeScale = 'minutely';
            elseif app.HoursButton_2.Value==true
                timeScale ='hourly';
            elseif app.DaysButton_2.Value==true
                timeScale = 'daily';
            else
                timeScale = 'monthly' ; % months;
                
            end
            
            %daySelect = all, weekdays, weekends
            %function1= min, max, average,sum, median
            
            plotTT =   obj.dataMin.Profile1; % {:,1}
            % filter From - To
            from1=datetime (  app.FromEditField_2.Value,  'InputFormat', 'dd/MM/yyyy HH:mm:ss');   %
            to1=datetime (  app.ToEditField_2.Value,  'InputFormat', 'dd/MM/yyyy HH:mm:ss');   %

            plotTT( plotTT.Time<from1,:)=[];
            plotTT( plotTT.Time>to1,:)=[];
            
            % selekce weekdays...
            
            if app.WeekdaysButton.Value ==true %weekdays only
                Wd = weekday(plotTT.Time);
                plotTT=plotTT( Wd>1 & Wd<6   ,:  );
            end
            
            if app.WeekendsButton.Value ==true %weekdays only
                Wd = weekday(plotTT.Time);
                plotTT=plotTT( Wd==1 | Wd==6   ,:  );
            end
            
            %
            
            try
                cla(app.UIAxesImp)
                
                if ~isempty(plotTT) %there is some data to plot
                    
                    if app.MinCheckBox.Value==true
                        if strcmp(timeScale,'original') == true
                            plotTTx= plotTT;
                        else
                            plotTTx=  synchronize(plotTT,  timeScale ,'min'); %mean,sum,min,max,firstvalue...
                        end
                        plot(app.UIAxesImp, plotTTx.Time, plotTTx{:,1},app.EditField_Pt1.Value );
                        hold (app.UIAxesImp, 'on')
                    end
                    
                    if app.MaxCheckBox.Value==true
                        if strcmp(timeScale,'original') == true
                            plotTTx= plotTT;
                        else
                            plotTTx=  synchronize(plotTT,  timeScale ,'max'); %mean,sum,min,max,firstvalue...
                        end
                        plot(app.UIAxesImp, plotTTx.Time, plotTTx{:,1},app.EditField_Pt2.Value );
                        hold (app.UIAxesImp, 'on')
                    end
                    
                    if app.AverageCheckBox.Value==true
                        if strcmp(timeScale,'original') == true
                            plotTTx= plotTT;
                        else
                            plotTTx=  synchronize(plotTT,  timeScale ,'mean'); %mean,sum,min,max,firstvalue...
                        end
                        plot(app.UIAxesImp, plotTTx.Time, plotTTx{:,1},app.EditField_Pt3.Value );
                        hold (app.UIAxesImp, 'on')
                    end
                    
                    if app.MedianCheckBox.Value==true
                        if strcmp(timeScale,'original') == true
                            plotTTx= plotTT;
                        else
                            plotTTx=  synchronize(plotTT,  timeScale ,@median); %mean,sum,min,max,firstvalue...
                        end
                        plot(app.UIAxesImp, plotTTx.Time, plotTTx{:,1},app.EditField_Pt4.Value );
                        hold (app.UIAxesImp, 'on')
                    end
                    
                end
                
            catch
                warning('Wrong plot parameters')
            end
            
            end

            
        end
        
        
        function saveFig(obj) % save fig
            [file1,path1 ]= uiputfile(['pwd', '\*.fig' ],'Choose save file .fig') % choose directory
            saveas(gcf,[path1, file1]);
        end
        
        function saveJPG(obj)  % save jpg
            [file1,path1 ]= uiputfile(['pwd', '\*.jpg' ],'Choose save file .jpg') % choose directory
            saveas(gcf,[path1, file1]);
        end
        
        function saveCSV(obj) % save data
            [file1,path1 ]= uiputfile(['pwd', '\*.csv' ],'Choose save file .csv') % choose directory
            
            %  tableFile = timetable2table(dataMinPrep) ;
            writetable(tableFile, [path1, file1] );
            fclose('all');
        end
        
        
    end
    
end
