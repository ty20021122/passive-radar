clear;
clc;
close all;

%% Passive Radar - Single Stationary Target
% Step 1: Coordinates
% Step 2: Random Baseband Signal
% Step 3: Frequency Shift
% Step 4: Time Shift
% Step 5: Cross-Correlation
% Step 6: Divide into Cuts
% Step 7: CAF Processing
% Step 8: Range-Doppler Map


%% Step 1: Define Coordinates

c = 3e8;

RX = [0, 0];
TX = [-400, 300];
Target = [400, 300];

% Target is stationary
fd_target = 0;

% Propagation distances
d_direct = norm(TX - RX);

d_TX_Target = norm(TX - Target);

d_Target_RX = norm(Target - RX);

d_reflection = d_TX_Target + d_Target_RX;

% Bistatic excess range
bistatic_range = d_reflection - d_direct;

fprintf('\n===== Geometry =====\n');
fprintf('Direct path = %.2f m\n', d_direct);
fprintf('Reflection path = %.2f m\n', d_reflection);
fprintf('Bistatic range = %.2f m\n', bistatic_range);


% Figure 1: Coordinates

figure(1);

plot(RX(1), RX(2), 'bo', ...
    'MarkerSize', 10, 'LineWidth', 2);
hold on;

plot(TX(1), TX(2), 'ro', ...
    'MarkerSize', 10, 'LineWidth', 2);

plot(Target(1), Target(2), 'ko', ...
    'MarkerSize', 10, 'LineWidth', 2);

plot([TX(1), RX(1)], ...
     [TX(2), RX(2)], 'b--');

plot([TX(1), Target(1)], ...
     [TX(2), Target(2)], 'r--');

plot([Target(1), RX(1)], ...
     [Target(2), RX(2)], 'r--');

grid on;
axis equal;

xlabel('X Position (m)');
ylabel('Y Position (m)');
title('Figure 1: Passive Radar Geometry');

legend('RX', 'TX', 'Target', ...
       'Direct Path', 'Reflection Path');


%% Step 2: Generate Random Baseband Signal

fs = 12e6;

B = 8e6;

num_cuts = 10;

samples_per_cut = 120000;

N = num_cuts * samples_per_cut;

n = (0:N-1).';

t = n / fs;

rng(1);

random_signal = ...
    (randn(N,1) + 1j*randn(N,1))/sqrt(2);

% Band-limit the random signal

frequency_axis = (-N/2:N/2-1).' * fs/N;

S = fftshift(fft(random_signal));

S(abs(frequency_axis) > B/2) = 0;

baseband = ifft(ifftshift(S));

baseband = baseband / sqrt(mean(abs(baseband).^2));


% Figure 2: Random Baseband

figure(2);

plot(t(1:500)*1e6, real(baseband(1:500)));

grid on;

xlabel('Time (microseconds)');
ylabel('Amplitude');
title('Figure 2: Random Baseband Signal');


%% Step 3: Frequency Shift

% Physical carrier frequency
fc = 220.6e6;

% Digital frequency translation
% The physical carrier is represented separately
% using the complex baseband model.

f_shift = 0.5e6;

transmit_signal = baseband ...
    .* exp(1j*2*pi*f_shift*t);

fprintf('\nCarrier frequency = %.2f MHz\n', fc/1e6);


% Figure 3: Frequency Shift

S_before = fftshift(fft(baseband));

S_after = fftshift(fft(transmit_signal));

% Use fewer display points for plotting

display_index = 1:100:N;

figure(3);

plot(frequency_axis(display_index)/1e6, ...
    abs(S_before(display_index)), 'b');

hold on;

plot(frequency_axis(display_index)/1e6, ...
    abs(S_after(display_index)), 'r');

grid on;

xlabel('Frequency (MHz)');
ylabel('Magnitude');

title('Figure 3: Frequency Shift');

legend('Before Frequency Shift', ...
       'After Frequency Shift');


%% Step 4: Time Shift

% Propagation delays

tau_ref = d_direct / c;

tau_surv = d_reflection / c;

relative_delay = tau_surv - tau_ref;

% Convert to samples

ref_delay_samples = tau_ref * fs;

surv_delay_samples = tau_surv * fs;

relative_delay_samples = relative_delay * fs;

fprintf('\n===== Time Delay =====\n');

fprintf('Reference delay = %.2f samples\n', ...
    ref_delay_samples);

fprintf('Surveillance delay = %.2f samples\n', ...
    surv_delay_samples);

fprintf('Relative delay = %.2f samples\n', ...
    relative_delay_samples);


% This geometry gives integer sample delays.
% Verify before using the integer time shift.

if abs(ref_delay_samples-round(ref_delay_samples)) > 1e-8 || ...
   abs(surv_delay_samples-round(surv_delay_samples)) > 1e-8

    error('This time-shift code requires integer sample delays.');

end

ref_delay_samples = round(ref_delay_samples);

surv_delay_samples = round(surv_delay_samples);


% Non-circular time shift function

time_shift = @(x,k) ...
    [zeros(k,1); x(1:end-k)];


% Reference Signal

reference = time_shift( ...
    transmit_signal, ref_delay_samples);

reference = reference ...
    .* exp(-1j*2*pi*fc*tau_ref);


% Surveillance Signal

surveillance = time_shift( ...
    transmit_signal, surv_delay_samples);

surveillance = 0.8 * surveillance ...
    .* exp(-1j*2*pi*fc*tau_surv) ...
    .* exp(1j*2*pi*fd_target*t);


% Figure 4: Received Signals

figure(4);

plot(t(1:300)*1e6, real(reference(1:300)), ...
    'b');

hold on;

plot(t(1:300)*1e6, real(surveillance(1:300)), ...
    'r');

grid on;

xlabel('Time (microseconds)');
ylabel('Amplitude');

title('Figure 4: Reference and Surveillance Signals');

legend('Reference', 'Surveillance');


%% Step 5: Cross-Correlation

% Search bistatic range from 0 to 1200 m

max_range = 1200;

max_lag = ceil(max_range*fs/c);

lags = 0:max_lag;

num_lags = length(lags);

% Use a short signal section to verify delay

checkN = 40000;

correlation = complex(zeros(num_lags,1));

for i = 1:num_lags

    lag = lags(i);

    correlation(i) = sum( ...
        surveillance(1+lag:checkN) ...
        .* conj(reference(1:checkN-lag)));

end

% Find correlation peak

[~, peak_index] = max(abs(correlation));

estimated_delay = lags(peak_index);

estimated_range = estimated_delay*c/fs;

fprintf('\n===== Cross-Correlation =====\n');

fprintf('Detected delay = %d samples\n', ...
    estimated_delay);

fprintf('Estimated range = %.2f m\n', ...
    estimated_range);


% Figure 5: Cross-Correlation

figure(5);

plot(lags, abs(correlation), ...
    'b', 'LineWidth', 1.5);

hold on;

plot(estimated_delay, ...
    abs(correlation(peak_index)), ...
    'ro', 'MarkerSize', 9, 'LineWidth', 2);

grid on;

xlabel('Delay (Samples)');
ylabel('Correlation Magnitude');

title('Figure 5: Cross-Correlation');

legend('Cross-Correlation', 'Detected Peak');


%% Step 6: Divide Signals into 10 Cuts

reference_cuts = reshape( ...
    reference, samples_per_cut, num_cuts);

surveillance_cuts = reshape( ...
    surveillance, samples_per_cut, num_cuts);

% Store complex correlation results

correlation_cuts = complex( ...
    zeros(num_lags, num_cuts));


%% Step 7: Cross-Ambiguity Function (CAF)

% CAF(tau,fd) =
%
% sum_n surveillance(n)
%       * conj(reference(n-tau))
%       * exp(-1j*2*pi*fd*n/fs)
%
% For each delay:
% 1. Calculate the complex matched product
% 2. Process all 10 cuts
% 3. Preserve phase across cuts
% 4. Search positive and negative Doppler frequencies
%
% FFT efficiently evaluates the Doppler search.


doppler_max = 120;

doppler_full = ...
    (-N/2:N/2-1).' * fs/N;

doppler_mask = abs(doppler_full) <= doppler_max;

doppler_axis = doppler_full(doppler_mask);

num_doppler = length(doppler_axis);

CAF = complex(zeros(num_lags, num_doppler));


for i = 1:num_lags

    lag = lags(i);

    matched_signal = complex(zeros(N,1));

    for k = 1:num_cuts

        block_start = (k-1)*samples_per_cut + 1;

        block_end = k*samples_per_cut;

        block_indices = (block_start:block_end).';

        valid = block_indices(block_indices > lag);

        % Correlation products
        % Use full reference indices at cut boundaries.

        matched_signal(valid) = ...
            surveillance(valid) ...
            .* conj(reference(valid-lag));

        % Correlation result of this cut

        correlation_cuts(i,k) = ...
            sum(matched_signal(valid));

    end

    % CAF Doppler processing
    % FFT implements the frequency compensation sum.

    doppler_result = fftshift(fft(matched_signal));

    CAF(i,:) = doppler_result(doppler_mask).';

end


% Figure 6: Correlation Across Cuts

figure(6);

imagesc(1:num_cuts, lags, abs(correlation_cuts));

axis xy;

colorbar;

xlabel('Cut Number');
ylabel('Delay (Samples)');

title('Figure 6: Correlation Across 10 Cuts');


%% Step 8: Complete Range-Doppler Map

range_axis = lags*c/fs;

CAF_magnitude = abs(CAF);

CAF_normalised = ...
    CAF_magnitude / max(CAF_magnitude(:));

CAF_dB = 20*log10(CAF_normalised + 1e-12);


% Find the strongest CAF peak

[~, max_index] = max(CAF_magnitude(:));

[range_index, doppler_index] = ...
    ind2sub(size(CAF_magnitude), max_index);

detected_range = range_axis(range_index);

detected_doppler = doppler_axis(doppler_index);


% Figure 7: Complete Range-Doppler Map

figure(7);

imagesc(range_axis, doppler_axis, CAF_dB.');

axis xy;

colormap(parula);

colorbar;

caxis([-50 0]);

hold on;

% Theoretical target measurement

hExpected = plot(bistatic_range, fd_target, ...
    'wo', 'MarkerSize', 11, 'LineWidth', 2);

% Detected target measurement

hDetected = plot(detected_range, detected_doppler, ...
    'mx', 'MarkerSize', 11, 'LineWidth', 2);

xlabel('Bistatic Range (m)');
ylabel('Doppler Frequency (Hz)');

title('Figure 7: CAF Range-Doppler Map');

legend([hExpected, hDetected], ...
    'Expected Target', 'Detected Target');

xlim([0 1200]);

ylim([-120 120]);

grid on;


%% Final Results

fprintf('\n====================================\n');

fprintf('PASSIVE RADAR CAF RESULTS\n');

fprintf('====================================\n');

fprintf('Target Position = (400, 300) m\n');

fprintf('\nTheoretical Range = %.2f m\n', ...
    bistatic_range);

fprintf('Detected Range = %.2f m\n', ...
    detected_range);

fprintf('\nTheoretical Doppler = %.2f Hz\n', ...
    fd_target);

fprintf('Detected Doppler = %.2f Hz\n', ...
    detected_doppler);

fprintf('\nRange Error = %.2f m\n', ...
    abs(detected_range-bistatic_range));

fprintf('Doppler Error = %.2f Hz\n', ...
    abs(detected_doppler-fd_target));

fprintf('====================================\n');


%% Save Figures

saveas(figure(1), 'Figure1_Geometry.png');

saveas(figure(2), 'Figure2_Baseband.png');

saveas(figure(3), 'Figure3_FrequencyShift.png');

saveas(figure(4), 'Figure4_ReceivedSignals.png');

saveas(figure(5), 'Figure5_CrossCorrelation.png');

saveas(figure(6), 'Figure6_Cuts.png');

saveas(figure(7), 'Figure7_CAF_RangeDoppler.png');