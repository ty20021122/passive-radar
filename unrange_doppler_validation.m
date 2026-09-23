clear;
clc;
close all;

%% Passive Radar - Range-Doppler Validation Test
% Second test using different delay and Doppler values.
% The purpose is to check whether the detected peak moves
% to the expected position.

rng(1);

%% Parameters

Fs = 200e3;              % Sampling frequency = 200 kHz
N = 2048;                % Number of samples

delay_true = 35;         % Known delay = 35 samples
doppler_true = -1500;    % Known Doppler shift = -1500 Hz

target_amplitude = 0.8;

n = 0:N-1;
t = n / Fs;


%% Step 1: Generate reference signal

bits = randi([0 1], 1, N);

reference = 2 * bits - 1;


%% Step 2: Generate surveillance signal

noise_level = 0.05;

surveillance = noise_level * ...
    (randn(1, N) + 1j * randn(1, N));


% Generate Doppler shift

doppler_signal = ...
    exp(1j * 2 * pi * doppler_true * t);


% Add delayed and Doppler-shifted target signal

surveillance(delay_true+1:end) = ...
    surveillance(delay_true+1:end) + ...
    target_amplitude * ...
    reference(1:end-delay_true) .* ...
    doppler_signal(delay_true+1:end);


%% Step 3: Plot reference and surveillance signals

figure;

sample_display = 1:150;

plot(sample_display, ...
    real(reference(sample_display)), ...
    'LineWidth', 1.2);

hold on;

plot(sample_display, ...
    real(surveillance(sample_display)), ...
    'LineWidth', 1.2);

grid on;

xlabel('Sample Number');
ylabel('Amplitude');

title('Reference and Surveillance Signals');

legend('Reference Signal', ...
       'Surveillance Signal');


%% Step 4: Define delay and Doppler search

max_delay = 80;

delay_axis = 0:max_delay;

doppler_axis = -3000:50:3000;


%% Step 5: Calculate Range-Doppler Map

range_doppler_map = zeros( ...
    length(doppler_axis), ...
    length(delay_axis));


for i = 1:length(doppler_axis)

    current_doppler = doppler_axis(i);

    % Compensate for the Doppler frequency being tested

    compensated_signal = ...
        surveillance .* ...
        exp(-1j * 2 * pi * current_doppler * t);


    for d = 0:max_delay

        reference_part = ...
            reference(1:N-d);

        surveillance_part = ...
            compensated_signal(d+1:N);

        range_doppler_map(i, d+1) = ...
            abs(sum( ...
            conj(reference_part) .* ...
            surveillance_part));

    end

end


%% Step 6: Find strongest peak

[max_value, max_index] = ...
    max(range_doppler_map(:));

[doppler_index, delay_index] = ...
    ind2sub(size(range_doppler_map), ...
    max_index);


estimated_delay = ...
    delay_axis(delay_index);

estimated_doppler = ...
    doppler_axis(doppler_index);


%% Step 7: Display results

fprintf('\n');

fprintf('----- Range-Doppler Validation Test -----\n');

fprintf('True delay       = %d samples\n', ...
    delay_true);

fprintf('Estimated delay  = %d samples\n', ...
    estimated_delay);

fprintf('True Doppler      = %.0f Hz\n', ...
    doppler_true);

fprintf('Estimated Doppler = %.0f Hz\n', ...
    estimated_doppler);

fprintf('-----------------------------------------\n');


%% Step 8: Normalise Range-Doppler Map

range_doppler_dB = ...
    20 * log10( ...
    range_doppler_map / ...
    max(range_doppler_map(:)) + eps);


%% Step 9: Plot Range-Doppler Map

figure;

imagesc(delay_axis, ...
    doppler_axis, ...
    range_doppler_dB);

axis xy;

xlabel('Delay (samples)');
ylabel('Doppler Frequency (Hz)');

title('Range-Doppler Validation Test');

colorbar;

caxis([-40 0]);

hold on;

plot(estimated_delay, ...
    estimated_doppler, ...
    'rx', ...
    'MarkerSize', 12, ...
    'LineWidth', 2);


%% Step 10: Delay correlation after Doppler compensation

best_compensated_signal = ...
    surveillance .* ...
    exp(-1j * 2 * pi * estimated_doppler * t);


delay_correlation = ...
    zeros(1, length(delay_axis));


for d = 0:max_delay

    reference_part = ...
        reference(1:N-d);

    surveillance_part = ...
        best_compensated_signal(d+1:N);

    delay_correlation(d+1) = ...
        abs(sum( ...
        conj(reference_part) .* ...
        surveillance_part));

end


%% Step 11: Plot delay correlation

figure;

plot(delay_axis, ...
    delay_correlation, ...
    'LineWidth', 1.5);

grid on;

xlabel('Delay (samples)');
ylabel('Correlation');

title('Delay Correlation after Doppler Compensation');

hold on;

plot(estimated_delay, ...
    delay_correlation(delay_index), ...
    'rx', ...
    'MarkerSize', 12, ...
    'LineWidth', 2);