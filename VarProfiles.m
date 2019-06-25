classdef VarProfiles< handle
    % class import data from file, preprocess and show
    % CTU UCEEB, Petr Wolf
    % Last modified: 14.06.2019
    % Version hist.:
    
    properties
        Fvs1 %= FVS% object FVS (.Irr, .Tamb, .Tcell, ->.PoutReal, .Pout)
        %   .Irr = Profile; %irradiance on module place
        %.  .Tamb = Profile; %ambient temeprature
        %   .Tcell= Profile; %cell temperature
        %   .PoutSet=Profile %setted Pout
        Fvs1Pred %= FVS %FVS predicted
        %   .PoutSet=Profile %setted Pout
        
        Grid1 %=GRID %.object GRID
        %  .PriceOut % grid price
        %  .Preal %real power out/ -in
        
        Load1 %=Profile %load
        Load1Pred %=Profile %predicted load
        Ess1 %=ESS %battery (ess)
        
        
        %ESS
        
    end
    
    properties (Dependent)
        
        
    end
    
    
    %properties (Access = protected)
    %end
    
    %properties (Constant)
    %end
    
    
    
    %%
    methods
        
        %% Construct an instance of this class
        function obj = VarProfiles()  %
            obj.Fvs1=FVS();
            obj.Fvs1Pred=FVS();
            
            obj.Grid1=GRID();
            
            obj.Load1=Profile();
            obj.Load1Pred=Profile();
            
            obj.Ess1=ESS();
            PoutReal = Profile(); % real output, possible limitation of system (e.g. battery charged) included
            
            
        end
        
        % Setting the Import selection data to varaibles for simulation
        function SetVar(obj, imp1, app) %set selected variable from loaded & adjusted profile
            
            switch str2double(app.VariableListBox.Value) %VarButton.Text
                case 1 %'Irradiance (G)'
                    app.ImportstatusLabel.Text= 'G set';
                    obj.Fvs1.Irr.Profile1=imp1.dataMin.Profile1 ;
                    
                case 2 %'Temperature ambient (Tamb)'
                    app.ImportstatusLabel.Text= 'Tamb set';
                    obj.Fvs1.Tamb.Profile1=imp1.dataMin.Profile1 ;
                    
                case 3 %'Temperature module (Tm)'
                    app.ImportstatusLabel.Text= 'Tm set';
                    obj.Fvs1.Tcell.Profile1=imp1.dataMin.Profile1  ;
                    
                case 4 % 'PVS AC output'
                    app.ImportstatusLabel.Text= 'P ac set';
                    obj.Fvs1.PoutSet.Profile1=imp1.dataMin.Profile1;
                    
                case 5 %'PVS AC output predicted'
                    app.ImportstatusLabel.Text= 'P ac predicted set';
                    obj.Fvs1Pred.PoutSet.Profile1=imp1.dataMin.Profile1;
                    
                case 6 %'Grid price'
                    app.ImportstatusLabel.Text= 'price set';
                    obj.Grid1.PriceOut.Profile1 =imp1.dataMin.Profile1;
                    
                case 7 %'Load'
                    app.ImportstatusLabel.Text= 'load set';
                    obj.Load1.Profile1= imp1.dataMin.Profile1 ;
                    
                case 8 %'Load predicted'
                    app.ImportstatusLabel.Text= 'predicted load set';
                    obj.Load1Pred.Profile1= imp1.dataMin.Profile1;
                    
                otherwise
                    disp('no selection')
                    
            end
            
        end
        
        %% Loading the variable to import selection
        function LoadVar(obj, imp1, app) %set selected variable from loaded & adjusted profile
            %VarButton = app.VariableButtonGroup.SelectedObject;
            
            switch str2double(app.VariableListBox.Value) %VarButton.Text
                case 1 %'Irradiance (G)'
                    app.ImportstatusLabel.Text= 'G loaded';
                    imp1.dataMin.Profile1 =obj.Fvs1.Irr.Profile1;
                    
                case 2 %'Temperature ambient (Tamb)'
                    app.ImportstatusLabel.Text= 'Tamb loaded';
                    imp1.dataMin.Profile1 =  obj.Fvs1.Tamb.Profile1;
                    
                case 3 %'Temperature module (Tm)'
                    app.ImportstatusLabel.Text= 'Tm loaded';
                    imp1.dataMin.Profile1 =obj.Fvs1.Tcell.Profile1;
                    
                case 4 % 'PVS AC output'
                    app.ImportstatusLabel.Text= 'P ac loaded';
                    imp1.dataMin.Profile1 =obj.Fvs1.PoutSet.Profile1;
                    
                case 5 %'PVS AC output predicted'
                    app.ImportstatusLabel.Text= 'P ac predicted loaded';
                    imp1.dataMin.Profile1 =obj.Fvs1Pred.PoutSet.Profile1;
                    
                case 6 %'Grid price'
                    app.ImportstatusLabel.Text= 'price loaded';
                    imp1.dataMin.Profile1 = obj.Grid1.PriceOut.Profile1;
                    
                case 7 %'Load'
                    app.ImportstatusLabel.Text= 'load loaded';
                    imp1.dataMin.Profile1 = obj.Load1.Profile1;
                    
                case 8 %'Load predicted'
                    app.ImportstatusLabel.Text= 'predicted load loaded';
                    imp1.dataMin.Profile1 = obj.Load1Pred.Profile1;
                    
                otherwise
                    disp('no selection')
                    
            end
           % imp1.dataMinOrig.Profile1 =imp1.dataMin.Profile1;
        end
        
        
        
        %% Button CHOOSE FILE
        %    function dataMin1 = ImportFile(obj, app)
        
        % end
        
    end
end
