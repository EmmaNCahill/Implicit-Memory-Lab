close all
clear all

f = waitbar(0,'Please wait...','Name','Plotting...');
pause(1.5)


warning('off','MATLAB:table:ModifiedAndSavedVarnames' )
global events SRats end_phase Nphase 

%see the ReadMe for informations on how to use this script
%
%please put the name of your file for freezing here : 
file_freezing='freezing_trying.xlsx';
color_f='b';
%
%please put the name of your file for vocalizations here:
file_USV='USV_test.xlsx';
color_USV='r';
%
%please put the number of phases in the experiment (3, 5 or 7)
Nphase=5;
%
%please fill the vector witht the endtime in minute of every phase
%0 if phase doesn't exist end_phase=[5,6,11,12,17];
end_phase=[5,6,11,12,17];
%
%please fill the vector (in Excel file order) with the numbers of the rats you are studying
SRats={'2' '8' '4' '14' '16' '18' '19'};
%
%please fill the array with the name of your phase (corresponding to the
%name of the Events in file_USV)
events={'preCS','CS1','ISI1','CS2','ISI2'};

%--------------------------------------------------------------------------
%
%disp('Make sure you saved your Excel files before starting')

%test if phases coherant 
if [1,Nphase] ~= size(events)
    error('You must have the same number of events names than the number of phases')
end 
if [1,Nphase] ~= size(end_phase)
    error('You must have the same number of phases in end_phase than in Nphase')
end 

%test if valid vector 
if size(end_phase)~=[1,8]
    error('end_phase size invalid, make sure it has 8 elements')
end

[z,NRat]=size(SRats);
%test if rat to study 
if NRat==0
    error('No rat to study, fill vector SRats')
end 

%%vocalizations 
%size depends on the number of rats: one cell = start and end for one rat
phases_USV=cell(1,Nphase);
for i=1:Nphase
    phases_USV{1,i}=cell(1,NRat);
end 

%put the values for each rat in one cell of the correponding phase
%read in order of the SRats vector

for n=1:NRat
    waitbar(0.025+n*0.025,f,join(['Reading vocalizations data for rat ',SRats{n}]));
    pause(0.5)
    [phases_USV] = readUSV(n,file_USV,phases_USV); 
    
end 

%%freezing 
waitbar(.80,f,'Reading freezing data...');
pause(1)
[A,phases_freezing]=readFreez(file_freezing);
%disp('Freezing data read')

%%plotting in the same window all the phases 
    %subplot(#ROW #COLUMN #zone)
    %different plotting depending on the number of phases 
    
        %disp('Plot in preparation')
    waitbar(1,f,'Plot in preparation');
    pause(1)
    
    for i=1:Nphase
        val=strcat(num2str(1),num2str(Nphase),num2str(i));
        val=str2double(val);
        subplot(val)
        plot_both(phases_freezing{1,i},phases_USV{1,i},events{1,i},color_f,color_USV)
    end 
                %set position and size of graph window
                %'position',[x0,y0,width,height]
            set(gcf,'position',[100 300 1200 200]);
    
close(f)

%==========================================================================

function res = plot_both(phase_freez,phase_USV,name,color_f,color_USV)
global events SRats end_phase Nphase 
% performs plotting one after the other: superposition of the datas
%A: matrix containing Excel file for freezing 
%phase_freez: vector containing lign number of event in the phase for
%             all rats 
%phase_USV: cell array with 1cell=1rat=matrix[[Tstart][Tend]] in the phase
%           phase_USV={    Ratx    }{     Raty   }
%                     {[start][end]}{[start][end]}
%                     {[ ... ][...]}{[ ... ][...]}
%name: string of name of the phase 
%SRats: vector of #Rats

    %plot_USV(phase_freez,name,'b')
    plot_multiple(phase_freez,name,true,color_f);
    plot_multiple(phase_USV,name,false,color_USV);

end
 
function [phases_USV] = readUSV(n,file,phases_USV)
global events SRats end_phase Nphase 
%read one sheet at a time from the Excel USV file 
%by using this function for every rat, we obtain cell arrays for every
%   phase containing start/end times negative USV for every rat
%n: current rat from the for
    clear T
    TGlobal=readtable(file,'Sheet',SRats{n});
    T=TGlobal{:,{'Event','StartTime','EndTime','GroupLabel'}}; %only keep the interesting columns 
    [m,o]=size(TGlobal);    
    
    for k=1:m
  
        %only interested in negative USVs 
        if strcmp(T{k,4},'Neg')

            %need to convert times in decimale to be at same scale than videos
            %conversion in minutes 
            T{k,2}=str2double(regexp(T{k,2},':','split'))*[0;1;1/60]; 
            T{k,3}=str2double(regexp(T{k,3},':','split'))*[0;1;1/60]; 

            %add values depending on which phase they happen in 
            err=false;
            for i=1:Nphase
                if strcmp(T{k,1},events{1,i})
                    %cell for phase i and matrix in this cell for rat n:
                    %add values for start and end 
                    phases_USV{1,i}{1,n}=[phases_USV{1,i}{1,n};T{k,2},T{k,3}];
                    err=false;
                    break 
                else 
                    err=true;
                end 
            end
            if err
                warning('There is a difference between names in USV_file and your Event vector, double check that it is on purpose');
                disp(join(['In the file, you wrote:',T{k,1}]))
            end
            
        end
        
    end

end

function [A,phases_freezing] = readFreez(file_freezing)
global events SRats end_phase Nphase 
[z,NRat]=size(SRats);
%open and analyse the freezing Excel file

    A=readcell(file_freezing);
    [sizeA,n]=size(A);
    
    phases_freezing=cell(1,Nphase);
    for i=1:Nphase
    phases_freezing{1,i}=cell(1,NRat);
    end
    
    %for every line of A 
    for k=1:sizeA 
        
        err_p=false;
        err_r=false;

        %going through all the possible phases 
        for i=1:Nphase
            
            %going through all the possible rats for every phase 
            for l=1:NRat
                if and(strcmp(num2str(A{k,1}),SRats{l}),strcmp(num2str(A{k,3}),num2str(events{1,i})))
                    phases_freezing{1,i}{1,l}=[phases_freezing{1,i}{1,l};A{k,4},A{k,5}];
                    err_p=false;
                    err_r=false;
                    break
                else
                    if ~strcmp(num2str(A{k,3}),num2str(events{1,i}))
                        err_p=true;
                    end 
                    if ~strcmp(num2str(A{k,1}),SRats{l})
                        err_r=true;
                    end 
                end 
                 
            end
            
            %to also break from this loop as we already stored the
            %value
            if and(~err_p,~err_r)
                break
            end
             
        end
        
       if err_p           
           warning('There is a difference between phases names in freezing_file and your Event vector. ');
           disp('The reason could be that you''re storing freezing for phases that you don''t plot. ');
           disp(join(['In the file, you wrote:',num2str(A{k,3})]))
       end
       if err_r 
           warning('There is a difference between rat names in freezing_file and your SRats vector. ');
           disp('The reason could be that you''re storing freezing for rats that you don''t plot. ');
           disp(join(['In the file, you wrote:',num2str(A{k,1})]))
       end 
           
    end
end 

function res = plot_multiple(phase,name,freezing,color)
global events SRats end_phase Nphase 

    [z,NRat]=size(SRats);

    %initialization at empty  
    startTimes=cell(1,NRat); 
    endTimes=cell(1,NRat);
    lineNames={};
       
    
    if freezing
        %add the scale //of the experiment for the phase beeing plotted
        for i=1:Nphase
            if strcmp(name,events{1,1})
                scale=end_phase(1)-2; %specific to preCS
                break
            elseif strcmp(name,events{1,i})
                scale=end_phase(i-1);
                break
            end 
        end 
    end 

    %goes through the all phase : if empty for every rat
    empty=true;
    
    for currentRat=1:NRat
        
        if strcmp(name,events{1,1})
            lineNames{1,currentRat}=join(['Rat ',SRats{currentRat}]);
        else 
            lineNames{1,currentRat}='';
        end 

        %test if the phase is empty for all the rats
        if ~isempty(phase{1,currentRat})
            empty=false; 
        end 
        
    end 
    
    if ~empty
       
         for currentRat=1:NRat 
            
             if freezing 
                %if the corresponding matrix is not empty (if the rat vocalized)
                if ~isempty(phase{1,currentRat})
                    startTimes{1,currentRat}=transpose(phase{1,currentRat}(:,1))/60+[scale];  
                    endTimes{1,currentRat}=transpose(phase{1,currentRat}(:,2))/60+[scale]; 
                %else no modification and start and end still empty vectors 
                end 
            
            else 
                %if the corresponding matrix is not empty (if the rat vocalized)
                if ~isempty(phase{1,currentRat})
                    startTimes{1,currentRat}=transpose(phase{1,currentRat}(:,1));  
                    endTimes{1,currentRat}=transpose(phase{1,currentRat}(:,2)); 
                %else no modification and start and end still empty vectors 
                end 
            end 
            
         end 
        
    end
  
    %'FaceAlpha': transparency from 0 to 1
        patchHndls = timeline(lineNames,startTimes,endTimes,'lineSpacing',.1,'facecolor',color,'LineStyle','none','FaceAlpha',0.5);
        title(name) 
                
        %different axis depending on the phase 
     %default: end_phase_=[20,21,26,27,32,33,38];
     for i=1:Nphase 
         if strcmp(name,events{1,1})
             axis([0 end_phase(1) 0 NRat+0.75])
             break
         elseif strcmp(name,events{1,i})
             axis([end_phase(i-1) end_phase(i) 0 NRat+0.75])
             break
         end 
     end 
     
end 

function [patchHndls] = timeline(lineNames,startTimes,endTimes,varargin)
%
% timeline.m--Draws horizontal timelines.
%
% PATCHHNDLS = TIMELINE(LINENAMES,STARTTIMES,ENDTIMES), with lineNames,
% startTimes and endTimes all being cell arrays of length n, draws n
% horizontal timelines in the current axes. The name of each timeline
% appears as a label on the y-axis. Each element of the startTimes and
% endTimes cell arrays is itself an array, so each timeline can start and
% stop either once or many times.
%
% ... = TIMELINE(...,'LINESPACING',LINESPACING), with lineSpacing a number
% between 0 and 1, places adjacent timelines the specified fraction of the
% line widths apart.
%
% ... = TIMELINE(...,patchArg1,patchArg2,...) passes the specified
% arguments directly to the patch command when drawing the timelines.
%
% Syntax: patchHndls = timeline(lineNames,startTimes,endTimes,<'lineSpacing',lineSpacing>,<patchArgs>)
%
% e.g.,   % Set up some dummy data for demonstration purposes.
%         lineNames={'Salinometer 1' 'Salinometer 2' 'Salinometer 3'};
%         startTimes={now-[800 500 100],now-600,now-[900 800 300 200]};
%         endTimes={startTimes{1}+[200 300 300],startTimes{2}+300,startTimes{3}+[80 400 50 250]};
%         % Call timeline.m.
%         patchHndls = timeline(lineNames,startTimes,endTimes,'lineSpacing',.1,'facecolor','b');
%         datetick('keeplimits'); title('Salinometer Deployments');
%         set(gcf,'position',[300 300 706 159]);

% Developed in Matlab 7.12.0.635 (R2011a) on GLNX86
% for the VENUS project (http://venus.uvic.ca/).
% Kevin Bartlett (kpb@uvic.ca), 2012-01-31 11:34
%-------------------------------------------------------------------------

p = inputParser;
p.KeepUnmatched=true;
p.FunctionName = mfilename;
p.addOptional('lineSpacing',1/4, @isnumeric);

try
    p.parse(varargin{:});
catch me
    disp([mfilename '.m--Parsing of input arguments failed; check argument names and values. Error message from inputParser follows:']);
    rethrow(me);
end

patchArgsStruct = p.Unmatched;
lineSpacing = p.Results.lineSpacing;

if lineSpacing<0 || lineSpacing>=1
    error([mfilename '.m--Line spacing must be between 0 and 1.']);
end

fieldNames = fieldnames(patchArgsStruct);
if ~ismember('edgecolor',lower(fieldNames))
   patchArgsStruct.edgeColor = 'k';
end 

if ~ismember('facecolor',lower(fieldNames))
    % Patch face colour not specified; use default.
   faceColor = 'r';
else
    % Patch face colour specified; extract in a variable and remove from
    % list of arguments to patch().
    for iField=1:length(fieldNames)
        thisFieldName = fieldNames{iField};
        if strcmpi(thisFieldName,'facecolor')
            faceColor = patchArgsStruct.(thisFieldName);
            patchArgsStruct = rmfield(patchArgsStruct,thisFieldName);
        end 
    end
end 

% Assemble a cell array of patch() arguments.
fieldNames = fieldnames(patchArgsStruct);
patchArgs = cell(1,2*length(fieldNames));
for iField=1:length(fieldNames)
    thisFieldName = fieldNames{iField};
    thisField = patchArgsStruct.(thisFieldName);
    patchArgs{(2*iField)-1} = thisFieldName;
    patchArgs{(2*iField)} = thisField;
end

numLines = length(lineNames);
set(gca,'ydir','reverse');

LINE_HEIGHT = 1;
upperLeftCornerY = (lineSpacing + LINE_HEIGHT)*[0:(numLines-1)];
set(gca,'ylim',[0 max(upperLeftCornerY)+LINE_HEIGHT])
patchHndls = cell(1,numLines);

for iLine = 1:numLines
    thisLineName = lineNames{iLine};
    thisLineStartTimes = startTimes{iLine};
    thisLineEndTimes = endTimes{iLine};    
    thisULy = upperLeftCornerY(iLine);
    numPatches = length(thisLineStartTimes);
    thisLinePatchHndls = nan(1,numPatches);
    
    for iPatch = 1:numPatches
        thisPatchStartTime = thisLineStartTimes(iPatch);
        thisPatchEndTime = thisLineEndTimes(iPatch);
        thisPatchX = [thisPatchStartTime thisPatchEndTime thisPatchEndTime thisPatchStartTime thisPatchStartTime];
        thisPatchY = [thisULy thisULy thisULy+LINE_HEIGHT thisULy+LINE_HEIGHT thisULy];
        %thisLinePatchHndls(iPatch) = patch(thisPatchX,thisPatchY,'r','edgecolor','k');
        thisLinePatchHndls(iPatch) = patch(thisPatchX,thisPatchY,faceColor,patchArgs{:});
    end % for each patch
    
    patchHndls{iLine} = thisLinePatchHndls;

end % for each timeline

set(gca,'ytick',upperLeftCornerY+0.5*LINE_HEIGHT,'yticklabel',lineNames);
axis('tight');
box on;
set(gca,'ygrid','on');
end 
