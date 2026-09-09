%% Passive Radar - 20 Sample Delay Test
clear;
clc;
close all;

%% Generate reference signal
N = 1000;
reference = randn(1, N);

%% Generate surveillance signal with 20-sample delay
delay = 20;
surveillance = [zeros(1, delay), reference(1:end-delay)];

%% Cross-correlation
[c, lags] = xcorr(surveillance, reference);

%% Find correlation peak
[~, index] = max(abs(c));
estimated_delay = lags(index);

fprintf('Estimated delay = %d samples\n', estimated_delay);

%% Plot correlation result
figure;
plot(lags, abs(c));
xlabel('Delay (samples)');
ylabel('Correlation');
title('Cross-Correlation between Reference and Surveillance Signals');
grid on;

hold on;
plot(estimated_delay, abs(c(index)), 'ro');