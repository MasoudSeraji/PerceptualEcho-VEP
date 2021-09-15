function c = runVEP(varargin)
%% 
% Steady State EEG Experiment
% The luminance of a blank screen is modulated sinusoidally, with or
% without concurrent tACS stimulation. EEG is recorded to determine 
% the steady state following of the evoked responses.
%
%
% BK - Feb 2016


%TODO  
% Add stimulation


import neurostim.*; 
[run,c,settings] = nsGui.parse(varargin{:},...
                                'Panels',{'plugins.egi','plugins.eyelink'},...
                                'Modes', {'Behavior'; 'EEG';'TEST'});
if ~run    
    return;
end



%% do we record eeg or not  


switch upper(settings.mode)            
    case 'EEG'
     
        nrTrialRepeats = 25;
        nrBlockRepeats = 10;
        trialDuration= Inf;
        fixRequired=true;
        allowBlinks=false;
        flickerStart = '@fixation.startTime.FIXATING+800';
     	dotColor = 1;
      	flickerColor = 60;
        backgroundColor = 1; 
    case 'BEHAVIOR'
     	nrTrialRepeats = 5;
        nrBlockRepeats = 1; 
      	trialDuration= Inf;
       	fixRequired=true;
        allowBlinks=false;
        flickerStart = '@fixation.startTime.FIXATING+800';
     	dotColor = 1;
      	flickerColor = 60;
        backgroundColor = 1;
  	case 'TEST'
     	nrTrialRepeats = 5;
        nrBlockRepeats = 1;
      	trialDuration= 4000;
       	fixRequired=false;
        allowBlinks=true;
     	flickerStart = 0;
    	dotColor = [1 0 0];
      	flickerColor = [1 1 1];
        backgroundColor = [0.1 0.1 0.1];
    otherwise 
        error('Unknown Mode?')
end        
        
%% Setup CIC and the stimuli.

c.screen.color.text = 50;
c.screen.color.background = backgroundColor;
% c.eye.backgroundColor = c.screen.color.background;
% c.eye.clbTargetColor  = [255 0 0];
% c.addPropsToInform('flicker.frequency');


c.trialDuration = trialDuration ; 
c.iti           =500;
c.paradigm      = 'VEP';


% Convpoly to create the luminance modulation
% To leave some space for a diode in the NW corner, have to make it a bit
% smaller than full screen.% 0.5*sqrt(2) radius would be the whole width 
% flash
flick = neurostim.stimuli.convPoly(c,'flicker');
flick.radius       = 0.18*0.5*sqrt(2)*c.screen.width;
flick.angle        = 45; % Rotate around z-axis to make a rectangle matching the screen
flick.X            =  0;
flick.Y            = 0; 
flick.nSides       = 4;
flick.filled       = true;
flick.color        = flickerColor; % cd/m2
flick.phase        = 0;
flick.amplitude    = 0.5;
flick.frequency    = 0;
flick.on           = flickerStart;
flick.duration     = 1000;
flick.diode.on     = true;
flick.diode.location = 'nw';
flick.diode.size   = 0.01;
flick.diode.color  = 80;


% Red fixation point
fixDuring = neurostim.stimuli.fixation(c,'reddot');
fixDuring.overlay = true;                % to use colors in M-16 mode set this to true
fixDuring.color             = dotColor;
fixDuring.shape             = 'CIRC';        
fixDuring.size              = 0.25;
fixDuring.X                 = 0;
fixDuring.Y                 = 0;
fixDuring.on                = 0;    


%% Behavioral control %Test
fix = behaviors.fixate(c,'fixation');
fix.on              = 0;
fix.from            = '@fixation.startTime.FIXATING';  % Require fixation from the moment fixation starts (i.e. once you look at it, you have to stay).
fix.to              = '@flicker.stopTime + 1000';   % Require fixation for this long
fix.X               = 0;
fix.Y               = 0; 
fix.tolerance       = 3;
fix.required        = fixRequired; %Require fixation
fix.allowBlinks     = allowBlinks;  
fix.successEndsTrial = true; % Set to false to get equal duration trials.

if hasPlugin(c,'egi')
    % The onset of these stimuli will be logged in Netstation 
    flick.onsetFunction  =@neurostim.plugins.egi.logOnset;  
    fixDuring.onsetFunction =@neurostim.plugins.egi.logOnset;  
end


%% Define conditions and blockçs
tf=design('tf');           % Define a factorial with one factor
tf.fac1.flicker.X    = [-7 7];
tf.randomization = 'RANDOMWITHOUTREPLACEMENT';
tf.retry ='RANDOM';
tfBlock=block('tfBlock',tf,'nrRepeats',nrTrialRepeats); 


%% Run the experiment

c.run(tfBlock,'nrRepeats',nrBlockRepeats);

end

