function saveBmodeFull(RData)
label = evalin('base','saveLabel');
c = evalin('base','c');
nr = evalin('base','PHASED_B.nRay');
angles = evalin('base','bmodeAngles');
origin = evalin('base','origin');
Trans = evalin('base', 'Trans');
Receive = evalin('base', 'Receive');
txFocus = evalin('base', 'PHASED_B.focusMM');
rcv_i = evalin('base','paGuideRcvStart');

persistent nframeBmode
if isempty(nframeBmode); nframeBmode = 0; end
dir = './data/';
if exist(dir,'file')~=7; mkdir(dir); end
name = ['bmode_' label '_' datestr(now,'yyyymmdd_HHMMSS') '_' num2str(nframeBmode)];
path = [dir name];

numRcvSamples = Receive(rcv_i+1).endSample-Receive(rcv_i+1).startSample+1;
tmp = RData(1:(numRcvSamples*nr),[1:32 97:128],1);
tmp_rf = reshape(tmp,[numRcvSamples,nr,64]);
tmp_rf = permute(tmp_rf,[1 3 2]);
rf{1} = tmp_rf;
clear tmp tmp_rf

tmp = RData(1:(numRcvSamples*nr),[1:32 97:128],2);
tmp_rf = reshape(tmp,[numRcvSamples,nr,64]);
tmp_rf = permute(tmp_rf,[1 3 2]);
rf{2} = tmp_rf;
clear tmp tmp_rf

lambda=c/Trans.frequency/1e6;
rfdata.c = c;
rfdata.numRcvChannels = 64;
rfdata.numXmtRxEvents = nr;
rfdata.elementSpacingMM = Trans.spacingMm;
rfdata.XMTspacingMM = rfdata.elementSpacingMM;
rfdata.samplingRateMHz = Trans.frequency*Receive(1).samplesPerWave;
rfdata.frequencyMHz = Trans.frequency;
rfdata.timeZero = -(SFormat(1).startDepth+...
                    Trans.lensCorrection*2+...
                    TW(1).peak)*Receive(1).samplesPerWave;
rfdata.focus = txFocus*lambda;
rfdata.theta=SFormat(1).theta+(0:nr-1)*SFormat(1).rayDelta;
rfdata.vs=-SFormat.radius*lambda;
%Correct time zero for each event to the last (closest) element fired
rfdata.t0_var=zeros(1,128);
for i=1:nr
    rfdata.t0_var(i)=max(TX(i).Delay)*lambda;
end

if strcmpi(label,'db') || strcmpi(label,'')
    disp('[DEBUG MODE] No file saved.')
else
    disp(['Saving B-mode frame to ' path]);
    save([path '.mat'],'rf','rfdata');
    figure(2)
    print('-dpng',[path '_verasonics.png'])
    disp(['B-mode data saved to ' path]);
end

nframeBmode = nframeBmode+1;
