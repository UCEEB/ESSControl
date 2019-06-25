classdef Sim< handle
    % class SIMULATE based on predictive algorithm
    % CTU UCEEB, Petr Wolf
    % Last modified: 14.06.2019
    % Version hist.:
    
    
    properties
        %SimTable =ProfileN %ProfileN (timetable data class of more profiles)
        
        % system parameters
        sysPar
        %.ess   energy storage parameters
        %   .Cap        battery capacity
        %   .Min        minimal battery cap
        %   .Max        maximal battery cap
        %   .Init       initial state cap
        %   .Power      maximal battery power
        
        %.sim           simulation parameters
        %   .Hor        simulation horizon
        %   .TimeStep   minute timestep simualtion interval
        
        %.grid          grid parameters
        %   .Lim        grid power limit
        
        % operating parameters
        LoadPred        %predicted load
        PVpred          %predicted PV power
        gridPrice       %grid price
        
        resultSim       %simulation result
        timeVar         %vector time data
        
    end
    
    
    properties (Constant, Access=private)
        ess=struct(...
            'Cap', 10,...
            'Min', 1,...
            'Max', 6,...
            'Init',5,...
            'Power',10);
        
        sim=struct(...
            'Hor',10,...
            'TimeStep', 1 /60);
        
        PowerGrid=struct(...
            'Lim',20);
        
        
        
    end
    
    properties (Dependent)
    end
    
    
    methods
        function obj = Sim()
            %SIMULATE Construct an instance of this class
            %   Detailed explanation goes here
            %obj.Property1 =
            %obj.SimTable =ProfileN();
            obj.resultSim=[];
            
            
            sysPar0 = struct(...
                'ess' , obj.ess,...
                'sim' , obj.sim,...
                'PowerGrid' , obj.PowerGrid );
            
            
            obj.sysPar = sysPar0; %initial parameters
            
        end
        
        
        function resultSim1=Simulate1(obj)
            
            resultSim1=[];
            
            %%Predictive algorithm, long term solution search
            %init
            gridInProf= zeros(obj.sysPar.sim.Hor,1); %grid demand profile
            socProf= NaN(obj.sysPar.sim.Hor,1); %SOC of battery profile
            essProf= NaN(obj.sysPar.sim.Hor,1); %ESS (battery) power profile
            
            SOC1=obj.sysPar.ess.Init; %current SOC
            
            
            n=1;
            while n<=obj.sysPar.sim.Hor  %proceed until whole prediction horizon succesfully reached
                
               
                bilance= obj.PVpred(n)   - obj.LoadPred(n)  + gridInProf(n) ; %kW
                
                nedostatek=0;
                if bilance>0 %access energy
                    %charge priority
                    nabijeni= min( [  obj.ess.Power(:)*obj.sim.TimeStep ; obj.sysPar.ess.Max(:)-SOC1; bilance(:)*obj.sysPar.sim.TimeStep ]); %kWh
                    SOC1=SOC1+nabijeni; %kWh
                    essProf(n)=-nabijeni/ obj.sim.TimeStep;
                    pretok=bilance-nabijeni/ obj.sysPar.sim.TimeStep; %kW, excess pwoer
                    
                else % otherwise discharge
                    vybijeni = min( [  obj.ess.Power(:)*obj.sysPar.sim.TimeStep; SOC1-obj.sysPar.ess.Min(:);-bilance(:)*obj.sysPar.sim.TimeStep ]); %kWh
                    SOC1=SOC1-vybijeni; %kWh
                    essProf(n)=+vybijeni/ obj.sysPar.sim.TimeStep;
                    nedostatek = -bilance -vybijeni/ obj.sysPar.sim.TimeStep; %kW, lack of power in simulation step
                end
                
                socProf(n)=SOC1; %soc profile = current soc in simulation step
                
                if nedostatek>0 %lack of energy in current simulation step
                    % this is a problem by control algorithm, simulation
                    % needs to by restarted
                    %find a step (between SOC=100% and step n included) with minimal energy price where there is not grid power exceeded
                    % increase by min(bilance,grid power limit), restart simulation
                    
                    % disp(['Simulation halted- grid has to be increased in step: ', num2str(n) ])
                    
                    %
                    %   steps wehre there is possible to increase grid power based on SOC (nn:1:n)
                    nn=n;
                    while nn>1 && socProf(nn)<obj.sysPar.ess.Max %steps between currrent step and SOC max reached
                        nn=nn-1;
                    end
                    if socProf(nn)==obj.sysPar.ess.Max
                        nn=nn+1;
                    end
                    kroky=[];
                    for x=nn:1:n   %filtering where the power can be increased based on grid limit
                        if gridInProf(x)< obj.sysPar.PowerGrid.Lim
                            kroky=[kroky  x ]; %array of indices where grid power can be increased
                        end
                    end
                    
                    %find indeex of lowest grid price (i)
                    i=find(  obj.gridPrice (kroky) == min (obj.gridPrice (kroky))); % i = jsou indexy v poli indexu kroku ('kroky') s minimalni cenou
                    
                    if isempty(i)
                        warning('Can not find a solution. Possible solution:increase grid limit')
                        resultSim1.status='solution not found';
                        return  %end
                    end
                    
                    
                    
                    if  any (   obj.PVpred ( kroky(i) )   - obj.LoadPred ( kroky(i) ) +  gridInProf(  kroky(i)  )  < 0 ) ==true %existuje nejaky krok kdy je bilance zaporna,tudiz se vybiji akku a je vhodne odebrat ze site vice?
                        pom=find(    obj.PVpred( kroky(i) )   - obj.LoadPred  ( kroky(i) )  +  gridInProf(  kroky(i)  )  < 0 ) ; %index v 'kroky' kdy je bilance zaporna
                        ii=kroky(  pom(end)) ;  %uvaha: vyrovnej az tesne pred problemem.vyhodne pokud problem neneastane. ale muze tez byt nedostatecne. lze tedy i co nejdrive kroky(1)
                        %      disp('oprava vyrovnanim site')
                        
                        gridInProf(  ii  ) = min ( obj.sysPar.PowerGrid.Lim(:) ,   obj.LoadPred  (ii)   - obj.PVpred (ii)  );
                        
                        
                    else
                        ii = kroky(  i(end) ) ;%uvaha: vyrovnej az tesne pred problemem.vyhodne pokud problem neneastane. ale muze tez byt nedostatecne. lze tedy i co nejdrive kroky(1)
                        %     disp('oprava nabijenim baterie')
                        gridInProf(  ii  ) = min ( obj.sysPar.PowerGrid.Lim(:) , gridInProf(   ii ) + -bilance(:)); %odber e site je omezen limitem site a pozadavkem odberu pro vyreseni problemu (nedostatku energie)
                    end
                    
                    n=1;
                    SOC1=obj.ess.Init;
                    % disp('opakuji simulaci...') %simulation needs to be restarted
                   
                    
                else
                    
                    n=n+1;
                end
                
                resultSim1.status='OK';
                
                resultSim1.data.bilance=obj.PVpred (1:obj.sim.Hor)   - obj.LoadPred (1:obj.sim.Hor);
                resultSim1.data.ess=essProf;
                resultSim1.data.soc=socProf;
                resultSim1.data.gridIn=gridInProf;
                
                obj.resultSim = resultSim1;
                
            end
            
            
            
        end
        
        
        function PlotResult1(obj, axes1,timeVar1, plotVar)
            %plots final solution, graph of Power
            if ~isempty(obj.resultSim)
                
                if exist('axes1','var')==true && ~isempty(axes1) %no axes parameter
                else
                    figure;
                    axes1=gca;
                end
                
                cla(axes1);
                
                if exist('timeVar1','var')==true && ~isempty(timeVar1)% timeVar1 parameter
                    elm1=1:1: min( numel(timeVar1), numel(obj.resultSim.data.soc) );
                    
                    if exist('plotVar','var')==true && plotVar(1)==true% plot variable
                        plot(axes1, timeVar1(elm1), obj.PVpred(elm1) , '-o'); %PV power
                    end
                    
                    hold (axes1, 'on');
                    if exist('plotVar','var')==true && plotVar(2)==true% plot variable
                        plot(axes1, timeVar1(elm1), obj.resultSim.data.gridIn(elm1),'-d'); %grid power
                    end
                    
                    if exist('plotVar','var')==true && plotVar(3)==true% plot variable
                        plot(axes1, timeVar1(elm1), obj.resultSim.data.ess(elm1)) %ess power
                    end
                    
                    if exist('plotVar','var')==true && plotVar(4)==true% plot variable
                        plot(axes1, timeVar1(elm1), obj.LoadPred(elm1)) %load power
                    end
                    hold (axes1, 'off');
                    
                else
                    plot(axes1, obj.PVpred , '-o'); %PV power
                    hold (axes1, 'on');
                    
                    plot(axes1, obj.resultSim.data.gridIn,'-d'); %grid power
                    plot(axes1, obj.resultSim.data.ess) %ess power
                    plot(axes1, obj.LoadPred) %load power
                    hold (axes1, 'off');
                end
                %'PV','Grid', 'ESS', 'Load'
                if exist('plotVar','var')==true
                entry1=0;
                legEntries=[];
                    if plotVar(1)==true
                    entry1=entry1+1;
                    legEntries{entry1}='PV';
                    end
                    if plotVar(2)==true
                    entry1=entry1+1;
                    legEntries{entry1}='Grid';
                    end
                    if plotVar(3)==true
                    entry1=entry1+1;
                    legEntries{entry1}='ESS';
                    end
                    if plotVar(4)==true
                    entry1=entry1+1;
                    legEntries{entry1}='Load';
                    end
                end
                                 
                legend(axes1, legEntries);
                xlim(axes1,'auto')
                grid (axes1, 'on')
                
            else
                disp('no result data');
            end
            
        end
        
        function PlotResult2(obj, axes1,timeVar1)
            %plots final solution, graph of SOC
            if ~isempty(obj.resultSim)
                
                if exist('axes1','var')==true && ~isempty(axes1) %no axes parameter
                else
                    figure;
                    axes1=gca;
                end
                cla(axes1);
                
                if exist('timeVar1','var')==true && ~isempty(axes1)% timeVar1 parameter
                    
                    elmPrice=min( numel(timeVar1), numel(obj.gridPrice) );
                    elmSoc=min( numel(timeVar1), numel(obj.resultSim.data.soc) );
                    elm=1:1:min(elmPrice,elmSoc);
                    
                    yyaxis(axes1, 'left')
                    plot(axes1, timeVar1(elm), obj.resultSim.data.soc(elm), '-x' ); %soc
                    
                    yyaxis(axes1, 'right')
                    plot(axes1, timeVar1(elm), obj.gridPrice(elm), '-o' ); %grid price
                    
                    
                    
                else
                    yyaxis(axes1, 'left')
                    plot(axes1, obj.resultSim.data.soc,'-x' ); %soc
                    plot(axes1, obj.gridPrice, '-o' ); %grid price
                    
                end
                xlim(axes1,'auto')
                legend(axes1,'SOC', 'Grid Price');
                grid (axes1, 'on')
                
                
            else
                disp('no result data');
            end
            
        end
        
        
        
    end
end

