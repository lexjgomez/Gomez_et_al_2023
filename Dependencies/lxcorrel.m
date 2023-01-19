% diffs = xcorrel(x, y, binsize, timewindow, preevent)
% Crosscorrelation of two timestamp datasets
% Input is two vectors of timestamps (x and y), and perameters for your
% histogram.
%
% x = first time series vector (in seconds). This is your trigger (in spike2)
% y = second time series vector (in seconds)
% binsize = the size of each bin (in the histogram), in milliseconds
% timewindow = the window if time you want to compare the timewindows (in
% seconds)
% preevent = the window of time you want to be from before t = 0 (in
% seconds)
%
% This delivers 5 values
% .count is a vector of the counts per bin, in spikes per second
% .edges is a vector of the ENDING time of each bin.
% .countsps is the histogram data in spikes per second
% .maxcorrel is the value of the counts that is the maximum
% .maxtime is the time that the max occurs at
% .meantomax is the ratio of the max bin to the mean bin
% .mediantomax is the ratio of the max bin to the median bin
% .baseline is the BL of the PETH, based on 1/2 of the preevent


function diffs = lxcorrel(x, y, binsize, timewindow, preevent)
edges = -preevent:(binsize/1000):(timewindow-preevent);
bins = length(edges)-1;
difference = [];
mtx = zeros(length(x),bins);
for i1 = 1:length(x)
    difference = [difference, y-x(i1)];
    mtx(i1,:) = histcounts(y-x(i1),edges); 
end
diffs.raw = mtx;
diffs.rawlogical = mtx > 0;
[diffs.count, xcorredges] = histcounts(difference,edges);
diffs.edges = xcorredges(2:end);
diffs.countsps = (diffs.count / length(x)) * (1/(binsize/1000));
[diffs.maxcorrel, index] = max(diffs.count);
diffs.maxtime = xcorredges(index);
diffs.meantomax = max(diffs.count)/mean(diffs.count);
diffs.mediantomax = max(diffs.count)/median(diffs.count);
diffs.baseline = mean(diffs.count(1:((preevent/2)*100)));



