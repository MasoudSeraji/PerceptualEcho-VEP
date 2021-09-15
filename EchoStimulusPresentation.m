% I will run several trials of an experiment in which stimulus luminance
% is randomly modulated.
% The sequences shown are saved in observer-specific data
% structures (append mode).

EEG_Mode = 0; %if 1, we send triggers (using the function outlpt1 for Windows)
bgdcolor = 'black';
Screen('Preference', 'SkipSyncTests', 1);
trialnumber = 96;
PixelPerDegree = 1080/35; %
refreshrate = 100;
gamma = 2.13; %we manually correct the luminance sequence

%% Get subject info
subname = input('Enter the subject code (default: RV) ->','s');
if isempty(subname); subname = 'RV'; end;


%% Look for a subject-specific file. If it exists, open it, if
% not, create it.
stimfile = ['./' subname '_' bgdcolor '_stim.mat'];

if exist(stimfile,'file')==2
    load(stimfile);
    currenttrialnumber = size(stims,2);
else
    currenttrialnumber = 0;
    %initialize what must be
    stims = [];
    missing_frames = {};
end;

%% Prepare sequences
times = [0:1/refreshrate:6.25]; times = times(1:end-1);
framenumber = length(times);
stims2 = rand(framenumber,trialnumber);
stimfft = fft(stims2,[],1);
stimfft= stimfft ./ abs(stimfft); %flatten the spectrum
stims2 = ifft(stimfft,[],1);
stims2 = (stims2-repmat(mean(stims2,1),[size(stims2,1) 1]))./repmat(std(stims2,[],1),[size(stims2,1) 1]); %z-score each trial
stims2 = round(127.5+127.5*stims2/1.7); %compress/stretch fluctuations by a factor of 1.7 to make it mostly fit between 0 and 255 
stims2(stims2<0)=0; stims2(stims2>255)=255;

times = [0:1/refreshrate:6.25]; times = times(1:end-1);

stims = [stims stims2];

%gammacorrect
originalstims = stims;
% stims = GammaCorrect(stims,0,255,1/gamma);

%% Now run the experiment
try
    %% Open a Psychtoolbox screen and initialize
    AssertOpenGL;
    screens=Screen('Screens');
    screenNumber=max(screens);
    
    % Find the color values which correspond to white and black
    white=WhiteIndex(screenNumber);
    black=BlackIndex(screenNumber);
    
    % Round gray to integral number, to avoid roundoff artifacts with some
    % graphics cards:
    gray=round((white+black)/2);
    
    % Open a double buffered fullscreen window and select a gray background
    % color:
    [w, rect]=Screen('OpenWindow',screenNumber, eval(bgdcolor));
    HideCursor;
    %% Check frame rate for compatibility with stored luminance sequences
%     frameRate=Screen('FrameRate',screenNumber);
%     % If MacOSX does not know the frame rate the 'FrameRate' will return 0.
%     % That usually means we run on a flat panel with 60 Hz fixed refresh
%     % rate:
%     if frameRate == 0
%         frameRate=60;
%     end
%     if frameRate ~= refreshrate
%         error('The screen refresh %d is not equal to the expected value %d\n',round(frameRate),round(refreshrate));
%     end;
    
    %% Use realtime priority for better timing precision:
    priorityLevel=MaxPriority(w);
    Priority(priorityLevel);
    
    %% prepare disk, fixation rectangles
    diskrect = OffsetRect(CenterRect(SetRect(0,0,7*PixelPerDegree,7*PixelPerDegree),rect),0,-7.5*PixelPerDegree);
    fixationrect = OffsetRect(CenterRect(SetRect(0,0,0.1*PixelPerDegree,0.1*PixelPerDegree),rect),0,0*PixelPerDegree);
    
    %% open screen (for instructions)
    Screen('FillRect', w , eval(bgdcolor), rect);
    Screen('DrawText', w, ['FIXATE the central dot.'], 20, 20, 255-eval(bgdcolor));
    Screen('Flip', w, [], 1);
    pause(1); KbWait;
    if EEG_Mode
        %send blockstart trigger
        outlpt1(254); pause(0.002); outlpt1(0);
    end;
    
    %% Each trial
    esc = 0;
    for trial=currenttrialnumber+1:size(stims,2)
        %% Draw inter-trial screen
        Screen('FillRect', w , eval(bgdcolor), rect);
        Screen('FillOval', w , 255-eval(bgdcolor), fixationrect);
        Screen('Flip', w, [], 1);
        
        missed_frames = [];
                
        %% User-initiated start, then wait a random time
        pause(0.4);
        KbWait;
        rand_wait = 0.2+0.3*rand(1);
        start_rand_wait = GetSecs;
        
        %% draw first frame and initialize timer
        Screen('FillOval',w,stims(1,trial),diskrect);
        while GetSecs-start_rand_wait < rand_wait-(0.5/refreshrate); end;
        Screen('Flip', w, [], 1);
        start_time = GetSecs;
        if EEG_Mode
            %send start trigger
            outlpt1(100); pause(0.002); outlpt1(0);
        end;
        last_frame = 1;
        
        
        %% Each frame
        while GetSecs-start_time <= times(end)
            % Quickly check for possible keyboard responses
            [keyIsDown, secs, keyCode, deltaSecs] = KbCheck;
            
            % If response: Escape?
            if keyIsDown
                if keyCode(KbName('esc'))
                    esc = 1;
                end;
            end;
            
            % Check timer: it's time to display what frame?
            current_time = GetSecs - start_time;
            frame = find(times>current_time , 1, 'first');
            
            % If a frame has been skipped, raise a flag
            if frame > last_frame + 1
                missed_frames = [missed_frames last_frame+1:frame-1];
            end;
            
            % Draw disk
            Screen('FillOval',w,stims(frame,trial),diskrect);
            
            % Flip
            Screen('Flip', w, [], 1);
            last_frame = frame;
        end;
        if EEG_Mode
            %send end trigger
            outlpt1(101); pause(0.002); outlpt1(0);
        end;
        %% save trial data: missed frames
        missing_frames{trial} = missed_frames;
        
        if esc; break; end;
    end
    if EEG_Mode
        %send blockend trigger
        outlpt1(255); pause(0.002); outlpt1(0);
    end;
    
    stims = originalstims; %save the non-gamma-corrected values
    
    %% if we exited prematurely, reshape the structures in consequence
    if esc
        stims = stims(:,1:trial);
    end;
    %% Write all info on disk
    save(stimfile,'stims', 'times', 'refreshrate');
    
    %% Proper end to the experiment
    Priority(0);
    ShowCursor;
    Screen('Close');
    Screen('CloseAll');
catch
    %this "catch" section executes in case of an error in the "try" section
    %above.  Importantly, it closes the onscreen window if its open.
    ShowCursor;
    Screen('CloseAll');
    Priority(0);
    psychrethrow(psychlasterror);
end %try..catch..