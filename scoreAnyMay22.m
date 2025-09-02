%Credit to
%http://wiki.stdout.org/matlabcookbook/Collecting%20data/Getting%20time-sen
%sitive%20keyboard%20input/
%for the difficult parts of this script.

%This is version May2022

%clearvars -except kc 
KbName('UnifyKeyNames')

%Things to do
%put your file name here
workingfilename='ENCtest.xlsx'; 
%make sure it is empty and it has enough open sheets to record all your data
%
%put here the number of parameters you would like to score 
NKeys=3;
%every parameters data (start and end times) will be written in one sheet
%corresponding to the number of the key you pressed
%
%Name what you are recording in order of the keys.
%example: if F1 pressing correponds to freezing, then first name in 'keys' is 'freezing'
behaviours={'freezing','groom','wiggle'};
%
%indicate if you are recording behavior in specific phase for eg (CS)
descriptor=true;
%that will add a column to your file with the number of the phase 
%
%indicate time of the experiment to record in seconds 
%input the countDown timer you would like before it records
totTime=30;
countDown=3;
%
%==========================================================================
%fill the upper part depending on you experiment 
Screen('Preference',  'Verbosity',  0);  
Screen('Preference',  'SkipSyncTests',1);  
Screen('Preference',  'VisualDebugLevel',0);

[a,b]=size(behaviours);
if [1,NKeys]~=[a,b]
    error('NKeys=% which should be equal to size of ''behaviours'' which is %',NKeys,b);
end

rat_current=input('Which rat is being observed? (Write name in apostrophies): Rat ');   
if descriptor
    CSname=input('Which phase is this? or any descriptor (Write name in apostrophies): ');
end

disp(join(['Recording for ',num2str(totTime),' seconds']))

% Key codes to wait for
kc=cell(NKeys,3);
for i=1:NKeys
    kc{i,1}   = KbName(join(['F',num2str(i)]));%first column=num key
    kc{i,2}   = num2str(i);%second column=number in str
    kc{i,3}   = behaviours{1,i};
end 

% Start saying that each key was down so that we don't accidentally intercept
% keypresses held over from before we entered this function.
keysWereDown = ones(1,256);
inLoop   = 1;

for i=1:NKeys
    disp(join(['Press F',kc{i,2},' for ',kc{i,3},', recorded in sheet ',kc{i,2}]))
end 

fs = 8000;
T = 0.25; %  seconds duration
t = 0:(1/fs):T;       
f = 200; %frequency
a = 0.5; %volume (amplitude)
y = a*sin(2*pi*f*t);
sound(y, fs);

text='Press enter to start ';
if countDown~=0
    text=join([text,'with a count down of ',num2str(countDown), ' seconds']);
end 
nothing=input(text);

% Tell matlab command window to stop listening to KB input

ListenChar(2);

if countDown ~= 0
    for i=1:countDown
        current=countDown-(i-1);
        fprintf(join([num2str(current),' ']))
        pause(1)
    end 
end 

fprintf('Trial Started \n')
tic
elapsedtime=toc;

nextstarttime=cell(1,NKeys);
nextstarttime(1,:)={1};

starttimes=cell(1,NKeys);
starttimes(1,:)={totTime};

endtimes=cell(1,NKeys);
endtimes(1,:)={totTime};

nextendtime=cell(1,NKeys);
nextendtime(1,:)={1};

firstloop=1;

ListenChar(2);

while elapsedtime<=totTime %inLoop


    % We want keysAreDown, which contains the state of every key
    [keyIsDown ctime keysAreDown] = KbCheck();

    % The newly released keys are ones that were down but now are not
    keysReleased = (keysAreDown==0) & (keysWereDown==1);
    % The newly pressed keys are ones that were not down but now are
    keysPressed  = (keysAreDown==1) & (keysWereDown==0);
    % Check any of the target keys were pressed 
    for i=1:NKeys
        
        if any(keysPressed(kc{i,1}))
            disp(join(['F',kc{i,2},' pressed - ',kc{i,3}]))
            starttimes{1,i}(nextstarttime{1,i})=toc;
            nextstarttime{1,i}=(length(starttimes{1,i}))+1;
        end 
        
    end
    
    
    % It would mistakenly register releases on the first iteration, so we'll
    % ignore releases on the first interation.
    % (keysWereDown will be all ones on the first iteration because we initalized it above)
    if ~all(keysWereDown)
        
        for i=1:NKeys
            if any(keysReleased(kc{i,1}))
                endtimes{1,i}(nextendtime{1,i})=toc;
                nextendtime{1,i}=(length(endtimes{1,i}))+1;
                
            end
        end 
        
    end


if elapsedtime>(totTime-0.15)
    sound(y, fs);
end

    % Record which keys were down in this iteration
    keysWereDown = keysAreDown;
    elapsedtime=toc;
    pause(0.0001) %Needed for Matlab v7.9
end
% Tell matlab command window to listen to KB input again
ListenChar(1);
fprintf('Trial Finished \n')
   %If the user is slow to release the enter key this can sometimes be
  %recorded as releasing the a key. If this is the case, an a release time
  %will have been recorded before an a start time. This if statement
  %removes this erroneous endtime.  
for i=1:NKeys
    
    if starttimes{1,i}(1) > endtimes{1,i}(1) 
        endtimes{1,i}=endtimes{1:i}(2:end); %remove the first element
    end  

    lengthstarttimes=length(starttimes{1,i});
    lengthendtimes=length(endtimes{1,i});

    if lengthstarttimes > lengthendtimes
        endtimes{1,i}(lengthstarttimes)=totTime;
    end
    
end

for i=1:NKeys
    clear ratsummarymat
    bouts=endtimes{1,i}-starttimes{1,i};
    [k,l]=size(bouts);
    allfreezing=sum(bouts);
    workingfilecontents=readcell(workingfilename,'Sheet',str2double(kc{i,2}));
    
    %if it's the first time you fill it: just from A1 
    if ~isempty(workingfilecontents)
        
         if ~descriptor
            ratsummarymat=cell(l,5);
            ratsummarymat(:,1)={rat_current};
            ratsummarymat(:,2)=kc(i,3)';
            ratsummarymat(:,3)=num2cell(starttimes{1,i}');
            ratsummarymat(:,4)=num2cell(endtimes{1,i}');
            ratsummarymat(:,5)=num2cell(bouts');
            clear workingfilecontents
            workingfilecontents= readcell(workingfilename,'Sheet',str2double(kc{i,2}),'Range','A:E');
            workingfilecontents(cellfun(@(workingfilecontents) any(ismissing(workingfilecontents)),workingfilecontents)) = [];
            [n,NElem]=size(workingfilecontents);
            if n==1
                workingfilecontents=reshape(workingfilecontents,NElem/5,5);
            end 
            workingfilecontents= [workingfilecontents;ratsummarymat];
            
         else 
            ratsummarymat=cell(l,6);
            ratsummarymat(:,1)={rat_current};
            ratsummarymat(:,2)=kc(i,3)';
            ratsummarymat(:,3)={CSname};
            ratsummarymat(:,4)=num2cell(starttimes{1,i}');
            ratsummarymat(:,5)=num2cell(endtimes{1,i}');
            ratsummarymat(:,6)=num2cell(bouts');
            clear workingfilecontents
            workingfilecontents= readcell(workingfilename,'Sheet',str2double(kc{i,2}),'Range','A:F','UseExcel',true);
            workingfilecontents(cellfun(@(workingfilecontents) any(ismissing(workingfilecontents)),workingfilecontents)) = [];
            [n,NElem]=size(workingfilecontents);
            if n==1
                workingfilecontents=reshape(workingfilecontents,NElem/6,6);
            end 
            workingfilecontents= [workingfilecontents;ratsummarymat];
            
         end 
         
         
    %if already some writing: take into account the columns with data and
    %not the rest such as potential graphs and means...
    else
        
        if ~descriptor
            
            %need 4 columns
            ratsummarymat=cell(l,5)
            ratsummarymat(:,1)={rat_current};
            ratsummarymat(:,2)=kc(i,3)';
            ratsummarymat(:,3)=num2cell(starttimes{1,i}');
            ratsummarymat(:,4)=num2cell(endtimes{1,i}');
            ratsummarymat(:,5)=num2cell(bouts');
            clear workingfilecontents
            workingfilecontents= readcell(workingfilename,'Sheet',str2double(kc{i,2}));
            workingfilecontents= [workingfilecontents;ratsummarymat];
        
        else
            
            %need 5 columns 
            ratsummarymat=cell(l,6);
            ratsummarymat(:,1)={rat_current};
            ratsummarymat(:,2)=kc(i,3)';
            ratsummarymat(:,3)={CSname};
            ratsummarymat(:,4)=num2cell(starttimes{1,i}');
            ratsummarymat(:,5)=num2cell(endtimes{1,i}');
            ratsummarymat(:,6)=num2cell(bouts');
            clear workingfilecontents
            workingfilecontents= readcell(workingfilename,'Sheet',str2double(kc{i,2}));
            workingfilecontents= [workingfilecontents;ratsummarymat];
        
        end
        
    end
 
    writecell(workingfilecontents,workingfilename,'Sheet',str2double(kc{i,2}))
    disp(join(['Data for key F',kc{i,2},' successfully recorded on sheet ', kc{i,2}]))
    clear workingfilecontents 
end 