classdef Profile < handle
    % class minute Profile (timetable with 1 variable)
    % CTU UCEEB, Petr Wolf
    % Last modified: 14.06.2019
    % Version hist.: debugged mixProfile
    
    properties
        Profile1 %timetable
        
    end
    
    properties (Dependent)
        Agg_sum         %hourly, daily,monthly, annual aggregation (sum)
        % .hour, .day, .month, .year
        Agg_mean         %hourly, daily,monthly, annual aggregation (mean)
        Stat %statistics
        % .min, .max, .mean, .median, .values, .NaNs. .zeros, .negative
        
    end
    
    
    %properties (Access = protected)
    %end
    
    %properties (Constant)
    %end
    
    properties (Dependent)
    end
    
    %%
    methods
        
        %% Construct an instance of this class
        function obj = Profile(Prof1)  %
            switch nargin
                case 0
                    obj.Profile1 = timetable(); %(NaT,NaN);
                case 1
                    if istimetable(Prof1)
                        obj.Profile1=Prof1;
                    else
                        warning('Input should be timetable')
                    end
                    
                otherwise
                    warning('Too much input arguments')
            end
            
        end
        
        
        %% clears Profile1 data
        function clearProfile(obj, cmd1)
            obj.Profile1=timetable(NaT,NaN);
            
            if exist('cmd1', 'var')==1 && strcmp(cmd1,'plot')
                obj.PlotX;
            end
        end
        
        
        %% Scale to fit to minute sums
        function scaleProfile(obj, value1, type1,cmd1)
            
            V1=obj.Profile1{:,:};
            if strcmp(type1,'mean')
                obj.Profile1{:,:} =   V1 .*value1./ mean(V1(:));
            else
                obj.Profile1{:,:} =   V1 .*value1./ sum(V1(:));
            end
            
            if exist('cmd1', 'var')==1 && strcmp(cmd1,'plot')
                obj.PlotX;
            end
            
        end
        
        %% Randomly variations on Year, Month, Day, Minute in %
        function randProfile(obj, sigma1,cmd1)
            
            if issorted(obj.Profile1.Time)
                [tv(:,1),  tv(:,2), tv(:,3), tv(:,4), tv(:,5), tv(:,6)] =  datevec( obj.Profile1.Time );%create timevector
                ch_v = [ ones(1,6) ;   diff(tv)]; %change vector
                ch_v(~ch_v==0)= 1;
                sum_v = cumsum( ch_v);    %cumulative sum of years change...second change
                
                pdM = makedist('Normal','mu',0,'sigma',sigma1(5)/100);   % define distribution parameters, Minutes
                pdH = makedist('Normal','mu',0,'sigma',sigma1(4)/100);   % hourse
                pdD = makedist('Normal','mu',0,'sigma',sigma1(3)/100);   % days
                pdMM = makedist('Normal','mu',0,'sigma',sigma1(2)/100);  %months
                pdY = makedist('Normal','mu',0,'sigma',sigma1(1)/100);   %years
                
                % elements1= numel(obj.Profile1.Time(:) );
                
                M_ER = random(pdM, [ sum_v(end,5)  ,1] );
                M_vect= M_ER( sum_v(:,5));
                
                H_ER =random(pdH, [ sum_v(end,4)  ,1] );
                H_vect= H_ER( sum_v(:,4));
                
                D_ER = random(pdD, [ sum_v(end,3)  ,1] );
                D_vect= D_ER( sum_v(:,3));
                
                MM_ER = random(pdMM, [ sum_v(end,2)  ,1] );
                MM_vect= MM_ER( sum_v(:,2));
                
                Y_ER =random(pdY, [ sum_v(end,1)  ,1] );
                Y_vect= Y_ER( sum_v(:,1));
                
              
                V1=obj.Profile1{:,:}.* (1+Y_vect + MM_vect+ D_vect + H_vect+ M_vect);
                V1(V1<0)=0;
                
                if exist('cmd1', 'var')==1 && strcmp(cmd1,'plot')
                    obj.PlotX;
                end
                
                obj.Profile1{:,:} = V1;
                
            else
                disp('Data should be time sorted. Randomization aborted')
            end
            
            
        end
        
        %% sets profile based on parameters value pairs
        function obj = setProfile(obj,  hourProf1, varargin )
            % ,
            
            p=inputParser;
            numvectorType = @(x) isnumeric(x) && isvector(x) ; %vector of integer 1..7
            defFrom= datetime(  year(datetime('now')),1,1);  %datetime This year
            defTo=''; %datetime Next year
            defM= 1:12 ;
            
            addRequired(p,'hourProf1', numvectorType)
            addOptional(p,'hourProf2', ''  , numvectorType)
            % plot
            addParameter(p,'plot',0);
            
            % datenum (start date)
            addParameter(p,'from',defFrom, @isdatetime);
            % datenum (stop date)
            addParameter(p,'to',defTo, @isdatetime);
            addParameter(p,'months1',defM, numvectorType);
            
            parse(p,hourProf1, varargin{:});
            plot1 = p.Results.plot;
            
            from = p.Results.from;
            to = p.Results.to;
            months1=p.Results.months1;
            profH1 = p.Results.hourProf1;
            profH2 = p.Results.hourProf2;
            
            
            if strcmp(to,'')
                to = from + years(1);
            end
            
            if strcmp(profH2,'')
                profH2=profH1;
            end
            
            Times1 = from:duration('00:01:00'):to;
            V1=NaN( 1, numel(Times1));
            timeVec= datevec(Times1);
            dayVec=weekday(Times1);
            
            if numel(profH1)<24
                profH1=ones(1,24).*profH1(1);
            end
            
            if numel(profH2)<24
                profH2=ones(1,24).*profH2(1);
            end
            
            
            months1= [months1(:);0];
            
            for hh=0:23
                selH = any ((timeVec(:,2)' == months1(:)) ,1)& (timeVec(:,4) == hh)'  &  ( dayVec>=2 & dayVec<=7 );
                V1(selH) = profH1(hh+1); %weekdays
                
                selH = any ((timeVec(:,2)' == months1(:)),1 )& (timeVec(:,4) == hh)'  & ( dayVec==1 | dayVec==7 );
                V1(selH) = profH2(hh+1); %weekend
            end
            
            
            % combine with current table, first delete same times in
            % previous table
            
            obj.Profile1(  isnan( obj.Profile1{:,:}   )    ,:) = [];
            
            inxNaN= isnan(V1);
            Times1( inxNaN) =[];
            V1(inxNaN)=[];
            
            [~, inters, ~ ]= intersect(obj.Profile1.Time(:) ,  Times1(:));
            %   numel(inters)
            obj.Profile1(inters,:) = [];
            
            T= [obj.Profile1.Time(:) ;  Times1(:)];
            V=[obj.Profile1{:,:} ;  V1(:) ]     ;
            
            TTable = timetable(T(:),V(:));
            
            %remove NaNs
            inxNaN = isnan (TTable{:,1});
            TTable(inxNaN,:)=[];
            %
            TTable=sortrows(TTable);
            obj.Profile1= synchronize( TTable, 'regular' , 'fillwithconstant', 'TimeStep',minutes);
            
            if  plot1==1
                obj.PlotX;
            end
            
        end
        
        %% plots the Profile
        function PlotX(obj)
            plot( obj.Profile1.Time(:), obj.Profile1{:,1});
        end
        
        %% mixes data in Profile
        function obj = mixProfile( obj, type, par1, par2, cmd1  )
            % type={'days', 'minutes'}
            if exist('par1', 'var')==1
                par1=par1(:);
            end
            if exist('par1', 'var')==1
                par2=par2(:);
            end
            
            % A) days
            % par1=[1 2 2 2 2 2 1] %keep workdays and weekends
            % par1=[1 1 1 1 1 1 1] % no keeping weekdays
            % par2 =1:12 %keepmonths
            
            % B) minutes
            % par1= max random change of data
            
            prof1 = obj.Profile1;
            
            if ~issorted(prof1)  %time sort (check)
                warning('data needed to be sorted')
                prof1=sortrows(prof1);
            end
            
            switch type
                
                case 'days' % mix days
                    
                    
                    if numel(par1)==7 && numel(par2)==12 %check input parameters
                        
                        %prepare table: start row; end row; daynum; weekday; months
                        daynum1 = floor(datenum(prof1.Time));
                        [values1,inxFirst1,~]= unique(daynum1);
                        inxLast1 = [ inxFirst1(2:end)-1 ; numel(daynum1) ];
                        [~,months1,~,~,~,~]=datevec(values1);
                        
                        TableDays = [ inxFirst1, inxLast1, values1, weekday(values1), months1];
                        TableDaysFull = TableDays(   TableDays(:, 2)- TableDays(:, 1) +1 == 24*60, :  );
                        %  TableDaysParts = TableDays(  ~(TableDays(:, 2)- TableDays(:, 1) +1 == 24*60), : );
                        
                        
                        %Prepare hash to make mixes
                        %1.based on weekdays
                        groups1=unique(par1)';
                        
                        H1=1; %subhash based on weeekdays
                        for n=groups1 %for every unique in key1
                            
                            posKey1= find( n == par1);
                            positions = ismember( TableDaysFull(:,4), posKey1);%find positions
                            
                            TableDaysFull(positions,6)= H1;
                            H1=H1+1;
                            
                        end
                        
                        groups2=unique( par2  );
                        H2=1; %subhash based on months
                        for n=groups2 %for every unique in key1
                            
                            posKey2= find( n == par2);
                            positions = ismember( TableDaysFull(:,5), posKey2);%find positions
                            
                            TableDaysFull(positions,7)= H2;
                            H2=H2+1;
                            
                        end
                        
                        %full hash is based on weekdays and months
                        TableDaysFull(:,8)= TableDaysFull(:,7)*10 +TableDaysFull(:,6);
                        
                        % mix based on hash
                        TableDaysMix=TableDaysFull;
                        groups3 = unique(TableDaysMix(:,8));
                        
                        
                        for n=groups3'
                            
                            posHash= find( TableDaysMix(:,8)== n);
                            
                            %mix rows posHash
                            for nn=1: numel(posHash)
                                %changing row  posHash(nn) <> row posHash( randi    ) in TableDaysMix
                                mix=randi( numel(posHash),1);
                                pom = TableDaysMix(posHash(nn),:);
                                TableDaysMix(  posHash(nn),:)= TableDaysMix(posHash(mix),:);
                                TableDaysMix(posHash(mix),:)= pom;
                            end
                        end
                        
                        
                        %restore timetable & add not full days is not needed
                        prof2=prof1;
                        
                        for n=1:numel(TableDaysFull (:,1)) %for every row=day
                            
                            prof2 { TableDaysFull (n,1)  : TableDaysFull (n,2),:  } = prof1  { TableDaysMix (n,1) : TableDaysMix(n,2) ,:};
                        end
                        
                        obj.Profile1 =prof2;
                        
                        if exist('cmd1', 'var')==1 && strcmp(cmd1,'plot')==true
                            obj.PlotX;
                        end
                        
                    else
                        warning('mixProfile: Wrong input parameters for *days*  ')
                    end
                    
                    
                    
                case 'minutes' %mix on minutes, keeping hours
                    
                    Var1=prof1{:,:};
                    hours1=floor(datenum(prof1.Time)*24); %hours in timeline
                    
                    start_hour=min(hours1);
                    stop_hour=max(hours1);
                    
                    %find common hours1
                    for mix_hour=start_hour :stop_hour
                        inx_hour1=find( hours1 == mix_hour) ;
                        inx_hour2=inx_hour1;
                        
                        lines=numel(inx_hour1);
                        for n=1:lines %mix the indices for specific hour
                            i1=randi(lines);
                            i2=randi(lines);
                            
                            pom=inx_hour1(i1); %      inx_hour(i1) <-> inx_hour(i2)
                            inx_hour1(i1)=inx_hour1(i2);
                            inx_hour1(i2)=pom;
                        end
                        Var1(inx_hour1) = Var1(inx_hour2);
                    end
                    
                    obj.Profile1{:,1}=Var1;
                    
                    if exist('cmd1', 'var')==1 && strcmp(cmd1,'plot')==true
                        obj.PlotX;
                    end
                    
                    
                otherwise
                    warning('mixProfile: wrong parameter input mix type')
            end
            
        end
        
        %% adds data in Profiles NaNs are ommited (replaced with 0)
        function obj = plus(Prof1, Prof2, cmd1 )
            % NaNs are ommited (replaced with 0)
            
            obj = Profile();
            if isa (Prof1 ,'Profile') && isa(Prof2, 'Profile')
                disp('+')
                obj.Profile1=synchronize ([  Prof1.Profile1 ; Prof2.Profile1   ],   'minutely', 'sum'   )  ;
            else
                disp('obj = plus(Profile, Profile)')
            end
            
            if exist('cmd1', 'var')==1 && strcmp(cmd1,'plot')
                obj.PlotX;
            end
            
        end
        
        %% substract Profiles, NaNs are ommited (replaced with 0)
        function obj = minus(Prof1, Prof2, cmd1)
            %
            obj = Profile();
            P2 = timetable(  Prof2.Profile1.Time   , - Prof2.Profile1{:,:}   );
            
            if isa (Prof1 ,'Profile') && isa(Prof2, 'Profile')
                disp('-')
                obj.Profile1=synchronize ([  Prof1.Profile1 ; P2   ],   'minutely', 'sum'   )  ;
            else
                disp('obj = plus(Profile, Profile)')
            end
            
            if exist('cmd1', 'var')==1 && strcmp(cmd1,'plot')
                obj.PlotX;
            end
            
        end
        
        
        
        
        
        %% Aggregated values
        function agg = get.Agg_sum(obj)
            %agg = sum(obj.Profile1{:,:});
            agg.hourly = synchronize(obj.Profile1,   'hourly'  ,'sum'); %mean,sum,min,max,firstvalue...
            agg.daily = synchronize(obj.Profile1,   'daily'  ,'sum'); %mean,sum,min,max,firstvalue...
            agg.monthly = synchronize(obj.Profile1,   'monthly'  ,'sum'); %mean,sum,min,max,firstvalue...
            agg.yearly = synchronize(obj.Profile1,   'yearly'  ,'sum'); %mean,sum,min,max,firstvalue...
        end
        
        %% Aggregated values
        function agg = get.Agg_mean(obj)
            %agg = sum(obj.Profile1{:,:});
            agg.hourly = synchronize(obj.Profile1,   'hourly'  ,'mean'); %mean,sum,min,max,firstvalue...
            agg.daily = synchronize(obj.Profile1,   'daily'  ,'mean'); %mean,sum,min,max,firstvalue...
            agg.monthly = synchronize(obj.Profile1,   'monthly'  ,'mean'); %mean,sum,min,max,firstvalue...
            agg.yearly = synchronize(obj.Profile1,   'yearly'  ,'mean'); %mean,sum,min,max,firstvalue...
        end
        
        %%   statistics: .min, .max, .mean, .median, .values, .NaNs. .zeros, .negative
        function stat = get.Stat(obj)
            V1 = obj.Profile1{:,:};
            
            stat.min = min(V1);
            stat.max = max(V1);
            stat.mean = mean( V1, 'omitnan'  );
            stat.median = median(V1, 'omitnan');
            stat.values = numel(V1);
            stat.NaNs = numel( V1(isnan (V1) )  );
            stat.zeros = numel( V1(V1 ==0)   );
            stat.negative = numel( V1(V1 < 0)   );
        end
        
        
        
        
        
    end
    
end
