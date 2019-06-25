classdef GRID < handle
    % class POWER GRID behaviour
    % CTU UCEEB, Petr Wolf
    % Last modified: 14.06.2019
    % Version hist.: 
    
    
    properties
        %grid limit
        MaxPin %maximal power in
        MaxPout %maximal power out
        ProfileMaxPin 
        ProfileMaxPout
        
        %grid price
        PriceIn %maximal power in
        PriceOut%maximal power out
        ProfilePriceIn 
        ProfilePriceOut
        
        Preal  % real power from (- = to) grid
        PoutReal  % real power from grid
        PinReal  % real power to grid (grid injection)
        
    end
    
    properties (Access = protected)
    end
    
    properties (Constant)
        
    end
    
    properties (Dependent)
        
    end
    
    methods
        function obj = GRID()
            %GRID Construct an instance of this class
            
            obj.PriceOut=Profile();
            
            
            if nargin ==0  %import data from file
                %
            end
        end
        
        %%
        
    end
    
end

