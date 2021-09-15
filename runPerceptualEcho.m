function c = runPerceptualEcho(varargin)
%% EchoDriver EEG Experiment


% The luminance of a circle is changing randomly. EEG is 
% recorded to determine the correlation between stimulus and EEg at the same time.
% experiment involved random visual sequences (6.25 s duration) displayed 
% within a peripheral disc stimulus on a black background.

import neurostim.*; 
[run,c,settings] = nsGui.parse(varargin{:},...
                                'Panels',{'plugins.egi','plugins.eyelink'},...
                                'Modes',{'Behavior','Test'});
if ~run    
    return;
end


%% do we record eeg or not  

switch upper(settings.mode)            
	case 'BEHAVIOR'
     	nrTrialRepeats = 10;
        nrBlockRepeats = 15;
      	trialDuration= '@fixation.startTime.FIXATING +7500';
       	fixRequired=true;
        allowBlinks=true;
     	echoStart = '@fixation.startTime.FIXATING +800';
        backgroundColor = 0.1;
        minLumiance=0.1;
        maxLumiance=60;
  	case 'TEST'
     	nrTrialRepeats = 10;
        nrBlockRepeats = 10;
      	trialDuration= 6250;
       	fixRequired=false;
        allowBlinks=false;
     	echoStart = 0;
        backgroundColor = [0.1 0.1 0.1];% colors are in RGB scale because of our system
        minLumiance=0;
        maxLumiance=1;
    otherwise 
        error('Unknown Mode?')
 end        
        
%% Setup CIC and the stimuli.

c.screen.color.text = 50;
c.screen.color.background = backgroundColor;
if hasPlugin(c,'eye')
c.eye.backgroundColor = c.screen.color.background;
c.eye.clbTargetColor  = [255 0 0];
end
c.trialDuration = trialDuration ; 
c.iti           = 1000;
c.paradigm      = 'ECHO';


% echooDriver to creat stimulus modulation
% To leave some space for a diode in the NW corner, have to make it a bit
% smaller than full screen.% 0.5*sqrt(2) radius would be the whole width 
% flash
echoStimulus = perceptualEcho.echoDriver(c,'echo');
echoStimulus.min        = minLumiance;
echoStimulus.max        = maxLumiance; % it's for color of our stimulus; max=white, min=black
echoStimulus.X            =  0;
echoStimulus.Y            = 7.5; 
echoStimulus.on           = echoStart;
echoStimulus.radius       = 3.5;
echoStimulus.duration     = 6250;
echoStimulus.diode.on     = true;
echoStimulus.diode.location = 'nw';
echoStimulus.diode.size   = 0.01;
echoStimulus.diode.color  = 80;
echoStimulus.diode.whenOff = false;

% Red fixation point
fixBefore = neurostim.stimuli.fixation(c,'reddot');
fixBefore.overlay = true;                % to use colors in M-16 mode set this to true
fixBefore.color             = 1;
fixBefore.shape             = 'CIRC';        
fixBefore.size              = 0.25;
fixBefore.X                 = 0;
fixBefore.Y                 = 0;
fixBefore.on                = 0;

% Green fixation point
fixDuring = neurostim.stimuli.fixation(c,'stopdot');
fixDuring.overlay = true;                % to use colors in M-16 mode set this to true
fixDuring.color             = 2;
fixDuring.shape             = 'CIRC';        
fixDuring.size              = 0.25;
fixDuring.X                 = 0;
fixDuring.Y                 = 0;
fixDuring.on                = '@fixation.startTime.FIXATING';    


%% Behavioral control
fixStart = behaviors.fixate(c,'fixation');
fixStart.on              = 0;
fixStart.from            = '@fixation.startTime.FIXATING';  % Require fixation from the moment fixation starts (i.e. once you look at it, you have to stay).
fixStart.to              = '@echo.stopTime';   % Require fixation for this long
fixStart.X               = 0;
fixStart.Y               = 0; 
fixStart.tolerance       = 3;
fixStart.required        = fixRequired; %Require fixation
fixStart.allowBlinks     = allowBlinks;  
fixStart.successEndsTrial =false; % Set to false to get equal duration trials.


if hasPlugin(c,'egi')
    % The onset of these stimuli will be logged in Netstation 
    echoStimulus.onsetFunction  =@neurostim.plugins.egi.logOnset;
    echoStimulus.offsetFunction  =@neurostim.plugins.egi.logOffset; 
    fixDuring.onsetFunction =@neurostim.plugins.egi.logOnset;  
end




%% Define conditions and blockçs
tf=design('tf');           % Define a factorial with one factor
tf.randomization = 'RANDOMWITHOUTREPLACEMENT';
tf.retry ='RANDOM';
tfBlock=block('tfBlock',tf,'nrRepeats',nrTrialRepeats); 


%% Run the experiment
%c.addPropsToInform('starstim.amplitude','starstim.frequency','starstim.duration','starstim.status','startstim.z')


c.run(tfBlock,'nrRepeats',nrBlockRepeats);



end