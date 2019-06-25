classdef FVS < handle
    % class PV system behaviour
    % CTU UCEEB, Petr Wolf
    % Last modified: 14.06.2019
    % Version hist.: added PoutSet
    
    
    properties
        Irr ; %irradiance on module place
        Tamb  %ambient temeprature
        Tcell %cell temperature
        
        PoutReal  % real output, possible limitation of system (e.g. battery charged) included
        PoutSet  %overwriting output power
        
        par
        % PV system properties
        %{
    .Pinst      installed power
    .Kt           temperature coeff. of power
    .Eff          overall efficiency
    .Plim       limitation on output power by FVS (e.g. by inverter)
    .IrrLim     irradiation limit
    .Noct  nominal operating cell temeprature of module
    .Nambt  nominal ambient temperature
        
        %}
    end
    
    properties (Access = protected)
    end
    
    properties (Constant)
        par0 = struct(...
            'Pinst' , 1000,...
            'Kt' , -0.4,...
            'Eff' , 0.94,...
            'Plim' , Inf,...
            'IrrLim' , 1000,...
            'Noct' , 48,...
            'Nambt',15  );
        
    end
    
    properties (Dependent)
        PVTable ; %synchronized data timetable, [Time, Irr, Tamb, Tcell, Power]
        Pout= Profile; % output power
    end
    
    methods
        function obj = FVS()
            %PVsystem Construct an instance of this class
            obj.Irr = Profile(); %irradiance on module place
            obj.Tamb = Profile(); %ambient temeprature
            obj.Tcell= Profile(); %cell temperature
            
            obj.PoutReal = Profile(); % real output, possible limitation of system (e.g. battery charged) included
            obj.PoutSet = Profile(); %overwriting output power
            
            obj.par = obj.par0;
            
        end
        
        %%
        function obj = setDef(obj)
            %set deafult parameters
            obj.par = obj.par0;
        end
        
        
        %%
        function PVTable1 = get.PVTable(obj)
            
            if ~isempty(obj.Irr.Profile1) %irrad data loaded
                
                if isempty(obj.Tamb.Profile1)
                    TAMB = timetable(  obj.Irr.Profile1.Time(1)  , NaN);
                else
                    TAMB=obj.Tamb.Profile1;
                end
                
                if isempty(obj.Tcell.Profile1)
                    TCELL = timetable(  obj.Irr.Profile1.Time(1)  , NaN);
                else
                    TCELL=obj.Tcell.Profile1;
                end
                
                POWER =    timetable(  obj.Irr.Profile1.Time(1)  , NaN);
                %}
                %Irr limits
                
                
                IRR = obj.Irr.Profile1;
                
                
                
                
                if isfloat(obj.par.IrrLim) && ~isnan(obj.par.IrrLim) && ~isempty(obj.par.IrrLim)
                    IRR { IRR{:,1} > obj.par.IrrLim,: } = obj.par.IrrLim;
                end
                
                PVTable1 = synchronize ( IRR,TAMB , TCELL , POWER ) ;
                PVTable1.Properties.VariableNames = {'Irr','Tamb', 'Tcell', 'Power'};
                
                
                
                
                %Calculate Tcell1
                % 1.using direct defined values
                Tcell1= PVTable1.Tcell;
                
                % 2.using Tamb or Ttypical
                Tamb1=PVTable1.Tamb;
                Tamb1( ~isfloat(Tamb1) | isnan(Tamb1)   ) = obj.par.Nambt;
                Tcell1(~isfloat(Tcell1) | isnan(Tcell1) )= Tamb1 (~isfloat(Tcell1) | isnan(Tcell1) ) ...
                    + (obj.par.Noct - 20) ./800 .* PVTable1.Irr(~isfloat(Tcell1) | isnan(Tcell1))  ;
                
                % Kt
                if isempty(obj.par.Kt)
                    Kt1=obj.par0.Kt;
                else
                    Kt1=obj.par.Kt;
                end
                
                if ~isempty(obj.par.Pinst)
                    
                    PVTable1.Power(:) =  obj.par.Pinst* obj.par.Eff  * PVTable1.Irr(:)  ./ 1000 .*( 1   -  (25 - Tcell1) .* Kt1/100     );
                    
                    % power limit
                    if isfloat(obj.par.Plim) &&  ~isnan(obj.par.Plim) && ~isempty(obj.par.Plim)
                        PVTable1.Power (PVTable1.Power > obj.par.Plim) = obj.par.Plim;
                    end
                    
                else
                    %  warning('Pinst not defined')
                end
                %close all
                %stackedplot(obj.PVTable)
                %   PVTable1=obj.Irr.Stat;
                
                
            else %irrad data not loaded
                PVTable1 = timetable(); %(NaT,NaN,NaN,NaN,NaN);
                
            end
            
            
            
        end
        
        %%
        function Pout1 = get.Pout(obj) %calculate the output power
            
            if ~isempty(obj.PVTable)
                
                Pout1=Profile();
                if isempty (obj.PoutSet.Profile1 )
                    Pout1.Profile1  = timetable( obj.PVTable.Time(:), obj.PVTable{:,4} );
                else %Pout was overwritten
                    Pout1.Profile1  = obj.PoutSet.Profile1;
                end
                
                
            else
                Pout1=Profile();
                
            end
            %  Pout1 = 1;
        end
        
        
        
    end
    
end
