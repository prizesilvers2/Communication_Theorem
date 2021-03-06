clear;


FFTsize = 1024;
ncp = 72;
ncp0 = 8;
NsymPSS = 62;                                                       %Num. of PSS seq.
NsymSSS = 62;                                                       %Num. of SSS seq.
NsymZeroPadding = 5;                                                %Num. of 0-padding around SSs
Nslot = 20;                                                         %Num. of slots
NOFDMsym = 7;                                                       %Num. of OFDM symbols in a slot


x = load('rxdump006.dat');
xReal = convertToReal(x);  
Nsym = length(xReal);
rx_data = xReal;

%1-1. PSS detection
%finding maximal NID2 and timing
%filling up :: max_Nid, max_timing
%metric value array ( metric(NID2 trial index, timing) )

max_timing0 = -1;
max_metric0_f = -100000;

max_timing1 = -1;
max_metric1_f = -100000;

max_timing2 = -1;
max_metric2_f = -100000;


for testNid = 0
        seq_PSS = gen_PSS(testNid); % - generate PSS sequence
        %mapping to RE
        sym_receive = zeros(1,FFTsize); 
        sym_receive(FFTsize - NsymPSS/2  +1 : FFTsize) = seq_PSS(1:31); 
        sym_receive(2 : 2 + NsymPSS/2 - 1) = seq_PSS(32:62);
        symifft = ifft(sym_receive);
        
        % cross correlation between the generated wave and the rx_demod
        
        for testTiming = 1 : Nsym - FFTsize
            max_PSS0(testNid+1,testTiming) = abs( dot(symifft, rx_data(testTiming : testTiming + FFTsize -1)));
        end 
        
            A_0 = [];
            B_0 = [];
            C_0 = [];
            A_0 = max_PSS0(1, 1:76288) ;
            B_0 = max_PSS0(1, 76288+1: 152576);
            C_0= A_0 + B_0 ;
            [i, j] = max(C_0);
            k = j+76800 ;
        
            PSS0 = i;
            
            if max_PSS0(1, j) > max_PSS0(1, k)
                max_timing0 = j;
            else
                max_timing0 = k;
            end
     
end

            
 
for testNid = 1
        seq_PSS = gen_PSS(testNid); % - generate PSS sequence
        %mapping to RE
        sym_receive = zeros(1,FFTsize); 
        sym_receive(FFTsize - NsymPSS/2  +1 : FFTsize) = seq_PSS(1:31); 
        sym_receive(2 : 2 + NsymPSS/2 - 1) = seq_PSS(32:62);
        symifft = ifft(sym_receive);
        
        % cross correlation between the generated wave and the rx_demod
        
        for testTiming = 1 : Nsym - FFTsize
            max_PSS1(testNid+1,testTiming) = abs( dot(symifft, rx_data(testTiming : testTiming + FFTsize -1)));
        end 
        
            A_1 = [];
            B_1 = [];
            C_1 = [];
            A_1 = max_PSS1(2, 1:76288) ;
            B_1 = max_PSS1(2, 76288+1: 152576);
            C_1= A_1 + B_1 ;
            [l, m] = max(C_1);
            n = m+76800 ;
            
            PSS1 = l;
            
            if max_PSS1(2, m) > max_PSS1(2, n)
                max_timing1 = m;
            else
                max_timing1 = n;
            end
       
end


for testNid = 2
        seq_PSS = gen_PSS(testNid); % - generate PSS sequence
        %mapping to RE
        sym_receive = zeros(1,FFTsize); 
        sym_receive(FFTsize - NsymPSS/2  +1 : FFTsize) = seq_PSS(1:31); 
        sym_receive(2 : 2 + NsymPSS/2 - 1) = seq_PSS(32:62);
        symifft = ifft(sym_receive);
        
        % cross correlation between the generated wave and the rx_demod
        
        for testTiming = 1 : Nsym - FFTsize
            max_PSS2(testNid+1,testTiming) = abs( dot(symifft, rx_data(testTiming : testTiming + FFTsize -1)));
        end 
        
            A_2 = [];
            B_2 = [];
            C_2 = [];
            A_2 = max_PSS2(3, 1:76288) ;
            B_2 = max_PSS2(3, 76288+1: 152576);
            C_2= A_2 + B_2 ;
            [p,q] = max(C_2);
            r = q+76800 ;
        
            PSS2 = p;
            
            if max_PSS2(3, q) > max_PSS2(3, r)
                max_timing2 = q;
            else
                max_timing2 = r;
            end
            
end

            

if (PSS0 > PSS1)&& (PSS0 > PSS2)
    estimatedNID2 = 0;
    estimated_timing_offset = max_timing0 ;
end

if (PSS1> PSS0)&& (PSS1 > PSS2)
    estimatedNID2 = 1;
    estimated_timing_offset = max_timing1 ;
end

if (PSS2> PSS0)&& (PSS2 > PSS1)
    estimatedNID2 = 2;
    estimated_timing_offset = max_timing2 ;
end


figure(1);
plot(abs(max_PSS0(1,:)) );
hold on;
plot(abs(max_PSS1(2,:)),'r');
plot(abs(max_PSS2(3,:)),'g');
hold off;

%1-2. boundary calculation
%filling up :: slotBoundary ////////

%SSS detection
max_seq = 1;
max_metric = -100000;
max_Nid = 0;

%2-1. symbol selection & compensation
SSSsym = rx_data(estimated_timing_offset - FFTsize - ncp  : estimated_timing_offset - ncp -1);  %SSS OFDM symbol boundary calculation

%2-2. frequency offset compensation (optional)



%3. FFT implementation
SSSsymf = fft(SSSsym, FFTsize);


%4-1. subcarrier selection & equalization
SSSrx = [];
SSSrx= [SSSsymf(FFTsize - NsymSSS/2  +1 : FFTsize) SSSsymf(2 : 2 + NsymPSS/2 - 1)];   %SSS symbol selection

%4-2. SSS detection
for testNid = 0 : 167
    % - generate the original SSS sequence
    seq_SSS = gen_SSS(testNid,estimatedNID2);
    
     % - correlation and find the maximal sequence index
    for seq = 1 : 2
        max_value = abs( dot(SSSrx, seq_SSS(seq,:)));  
        if max_metric <  max_value
            max_metric = max_value;
            max_Nid = testNid;
            max_seq = seq;
        end
     end
end

NID1 = max_Nid
NID2 = estimatedNID2
estimatedNID = NID1*3 + NID2

%4-3. Frame boundary calculation
%filling up : frameBoundary
if max_seq == 1
    estimated_timing_offset = estimated_timing_offset - ((NOFDMsym-2)*(FFTsize+ncp) + (ncp+ncp0+FFTsize) + ncp);
    if estimated_timing_offset < 0
       frameBoundary = estimated_timing_offset+(Nslot)*((FFTsize+ncp)*7+ncp0);
   else
       frameBoundary = estimated_timing_offset ;
   end
else
    estimated_timing_offset = estimated_timing_offset - ((NOFDMsym*10)+(NOFDMsym-1))*FFTsize - ((ncp*11*(NOFDMsym-1))+(ncp+ncp0)*11 + (FFTsize+ncp)*7 +ncp0);
     if estimated_timing_offset < 0
       frameBoundary = estimated_timing_offset+(Nslot)*((FFTsize+ncp)*7+ncp0);
   else
       frameBoundary = estimated_timing_offset ;
   end
end    


