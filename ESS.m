classdef ESS < handle
    %ESS behaviour, for fast simulation usage
    %
    
    properties
        PInOutReal
        SOC
        CapX %current capacity Wh
        Cycles
        
        par  = struct(...
            'Timestep' , 60,...
            'Cap' , 1000,...
            'EffIn' , 0.9,...
            'EffOut' , 0.9,...
            'PmaxIn' , 1000,...
            'PmaxOut' , 1000 );
        
        % ESS parameters
        %{

        %}
    end
    
    properties (Access = protected)
    end
    
    properties (Constant)
        par0  = struct(...
            'Timestep' , 60,...
            'Cap' , 1000,...
            'EffIn' , 0.9,...
            'EffOut' , 0.9,...
            'PmaxIn' , 1000,...
            'PmaxOut' , 1000 );
        
    end
    
    properties (Dependent)
        
    end
    
    %%
    methods
        function obj = ESS(Var1)
            %ESS Construct an instance of this class
            obj.par = obj.par0;
            
            obj.PInOutReal = 0;
            obj.SOC = 0;
            obj.Cycles = 0;
            
            if nargin ==1  %import data from file
                obj.SOC=Var1;
                obj.CapX = obj.SOC* obj.par.Cap;
            end
            
        end
        
        %%
        function obj = setDef(obj)
            %set deafult parameters
            obj.par = obj.par0;
        end
        
        %%
        function obj=clearESS(obj, Var1)
            %clear ESS
            obj.Cycles=0;
            obj.SOC=Var1;
        end
        
        function [PInOutReal1, SOC1, Cycles1] = Power(obj,Pwr)
            % in/out power
            % usedPwr=0;
            
            if Pwr>0 %ESS charging
                %  disp('charging')
                Pwr1=min(  obj.par.PmaxIn  , Pwr );
                E1 = Pwr1 *obj.par.Timestep/3600 * obj.par.EffIn; %energy to bat Wh
                
                possibleE = obj.par.Cap-obj.CapX;
                if possibleE>E1 %battery still not full
                    obj.CapX = obj.CapX + E1;
                    usedPwr = E1 /obj.par.Timestep*3600 / obj.par.EffIn;
                    
                else %battery will be fully charged
                    obj.CapX = obj.par.Cap;
                    usedPwr = possibleE /obj.par.Timestep*3600  /  obj.par.EffIn;
                    %disp('bat full')
                end
                
            else %ESS discharging
                %disp('discharging')
                % Pwr<0 !
                Pwr1=min(  obj.par.PmaxOut  , abs(Pwr )  );
                E1 = Pwr1*obj.par.Timestep/3600 / obj.par.EffOut; %energy from bat Wh
                
                possibleE = obj.CapX;
                
                % E1<0 !
                if possibleE>abs(E1) %battery still not empty
                    obj.CapX = obj.CapX - abs(E1);
                    usedPwr = E1 /obj.par.Timestep*3600 * obj.par.EffOut;
                    
                else %battery will be empty
                    obj.CapX = 0;
                    usedPwr = possibleE /obj.par.Timestep*3600  *  obj.par.EffOut;
                    %disp('bat empty')
                end
            end
            
            obj.PInOutReal = usedPwr;
            SOCold=obj.SOC;
            obj.SOC = obj.CapX/obj.par.Cap;
            obj.Cycles = obj.Cycles + abs( SOCold - obj.SOC );
            
            PInOutReal1 = obj.PInOutReal;
            SOC1 = obj.SOC;
            Cycles1 = obj.Cycles;
            
        end
        
    end
    
    
end

