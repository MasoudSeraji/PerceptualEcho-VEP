classdef echoDriver < neurostim.stimulus
    % Draws a flickering circle 
    % Stimulus is showing to the subjects in the different lumiances.
    % the lumiances are differing from white to black based on a random
    % numbers.
    % Note: if 'min' is greater than 0, then distribution of luminance values will
    % be right-skewed
    
    % MS -Aug 2019
    
    properties
        nrFramesPreCalc;
    end
    
    methods (Access = public) 
        function o = echoDriver(c,name)
            o = o@neurostim.stimulus(c,name);
            o.addProperty('radius',3,'validate',@isnumeric);
            
            %Properties for flickering the stimulus
            o.addProperty('frequency',0,'validate',@isnumeric); % Hz
            o.addProperty('min',0,'validate',@isnumeric); % minimum lumiance for white
            o.addProperty('max',0,'validate',@isnumeric); % maximum lumiance for black
            o.addProperty('colorPerFrame',[],'validate',@isnumeric)% color(this is very important for this experiment. Make sure i'll be save correctely)
        end
        
        function beforeTrial(o)
            o.nrFramesPreCalc = round((o.duration/1000)*o.cic.screen.frameRate);
            normRandPerFrame = o.min + rand([o.nrFramesPreCalc 1]);% Random number to have random colors between black and white
            fourierPerFrame=fft(normRandPerFrame,[],1);% Fourier transform for normalization
            normalizedFourierPerFrame=fourierPerFrame./abs(fourierPerFrame);% normalization
            normalizedRandPerFrame=ifft(normalizedFourierPerFrame,[],1);% invers fourier to return to the time domain
            zRandPerFrame=(normalizedRandPerFrame-repmat(mean(normalizedRandPerFrame,1),[size(normalizedRandPerFrame,1) 1]))./repmat(std(normalizedRandPerFrame,[],1),[size(normalizedRandPerFrame,1) 1]);
            
            SCALE = 1.7;
            colPerFrame = o.max/2+o.max/2*(zRandPerFrame/SCALE); %compress/stretch fluctuations by a scale factor such that most values are within the o.min-o.max range (1.7 ~norminv(0.95) , but z is not quite Gaussian).           
            colPerFrame(colPerFrame<o.min)=o.min; % turning the random numbers that are out of the rang to the minimum or maximum
            colPerFrame(colPerFrame>o.max)=o.max;             
            % assign to member (annd thereby save once!) 
            o.colorPerFrame = colPerFrame;           
         end
        
        
        function beforeFrame(o)            
            ix = mod(o.frame-1,o.nrFramesPreCalc)+1;
            thisColor = o.colorPerFrame(ix,:);     
            Screen('FillOval',o.window, thisColor, o.radius.*[-1 -1 1 1]);            
        end
    end
end