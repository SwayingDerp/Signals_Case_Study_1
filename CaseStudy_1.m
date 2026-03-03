clear all; close all; clc

%% Part 1: Equalizer Design Specifications

% Sampling parameters
fs = 44100;  % Standard audio sampling rate (Hz)
dt = 1/fs;

% Define 5 frequency bands with center frequencies and bandwidths
% Band 1: Bass (center: 60 Hz)
% Band 2: Low-mid (center: 250 Hz)  
% Band 3: Mid (center: 1000 Hz)
% Band 4: High-mid (center: 4000 Hz)
% Band 5: Treble (center: 16000 Hz)

center_freqs = [60, 250, 1000, 4000, 16000];
Q = 1.5;
bandwidths = center_freqs / Q;

fprintf('=== 5-BAND EQUALIZER DESIGN ===\n');
fprintf('Band\tCenter Freq\tBandwidth\tFrequency Range\n');
fprintf('----\t-----------\t---------\t---------------\n');
for i = 1:5
    f_low = max(20, center_freqs(i) - bandwidths(i)/2);
    f_high = min(20000, center_freqs(i) + bandwidths(i)/2);
    fprintf('Band %d\t%.0f Hz\t\t%.0f Hz\t\t%.0f - %.0f Hz\n', ...
        i, center_freqs(i), bandwidths(i), f_low, f_high);
end
fprintf('\n');

%% Part 2: Design Bandpass Filters for Each Band

% Each bandpass filter is created by cascading:
% - A high-pass filter (cutoff = low frequency edge)
% - A low-pass filter (cutoff = high frequency edge)

R = 1000;  % Base resistance (Ohms)
filters = struct();  % Store filter parameters

% Calculate filter responses for visualization
f_axis = logspace(log10(20), log10(20000), 1000);
H_bands = zeros(5, length(f_axis));

figure('Position', [100, 100, 1200, 500]);

for i = 1:5
    % Calculate band edges
    f_low = max(20, center_freqs(i) - bandwidths(i)/2);
    f_high = min(20000, center_freqs(i) + bandwidths(i)/2);
    
    % Design high-pass section (resistive load configuration)
    % f_c = 1/(2πRC) for cutoff frequency
    C_hp = 1/(2*pi*f_low*R);
    tau_hp = R * C_hp;
    alpha_hp = dt/tau_hp;  % For digital implementation
    
    % Design low-pass section (capacitive load configuration)
    C_lp = 1/(2*pi*f_high*R);
    tau_lp = R * C_lp;
    alpha_lp = dt/tau_lp;
    
    % Store filter parameters
    filters(i).center = center_freqs(i);
    filters(i).f_low = f_low;
    filters(i).f_high = f_high;
    filters(i).alpha_hp = alpha_hp;
    filters(i).alpha_lp = alpha_lp;
    filters(i).C_hp = C_hp;
    filters(i).C_lp = C_lp;
    
    % Calculate continuous-time frequency response for visualization
    w = 2*pi*f_axis;
    s = 1j*w;
    
    % High-pass: H_hp(s) = s/(s + 1/τ)
    % Low-pass: H_lp(s) = (1/τ)/(s + 1/τ)
    H_hp = s ./ (s + 1/tau_hp);
    H_lp = (1/tau_lp) ./ (s + 1/tau_lp);
    
    % Bandpass = high-pass cascaded with low-pass
    H_bands(i,:) = H_hp .* H_lp;
    
    % Plot individual band responses
    subplot(2, 3, i);
    semilogx(f_axis, 20*log10(abs(H_bands(i,:)) + eps), 'LineWidth', 2);
    hold on;
    
    % Mark -3dB points and center frequency
    [~, idx_low] = min(abs(f_axis - f_low));
    [~, idx_high] = min(abs(f_axis - f_high));
    [~, idx_center] = min(abs(f_axis - center_freqs(i)));
    
    plot(f_axis(idx_low), 20*log10(abs(H_bands(i,idx_low))), 'ro', 'MarkerSize', 8);
    plot(f_axis(idx_high), 20*log10(abs(H_bands(i,idx_high))), 'ro', 'MarkerSize', 8);
    plot(center_freqs(i), 20*log10(abs(H_bands(i,idx_center))), 'gs', 'MarkerSize', 8);
    
    xlabel('Frequency (Hz)');
    ylabel('Magnitude (dB)');
    title(sprintf('Band %d: Center = %.0f Hz', i, center_freqs(i)));
    grid on;
    xlim([20, 20000]);
    ylim([-40, 5]);
    
    % Add annotations
    text(center_freqs(i), -5, sprintf('%.0f Hz', center_freqs(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 9);
    legend('Response', '-3dB points', 'Center', 'Location', 'southwest');
end

% Show equalizer block diagram
subplot(2, 3, 6);
axis off;
text(0.1, 0.9, 'EQUALIZER ARCHITECTURE:', 'FontWeight', 'bold', 'FontSize', 12);
text(0.1, 0.8, 'Input signal x[n] →', 'FontSize', 11);
for i = 1:5
    text(0.15, 0.8 - i*0.1, sprintf('├─ Band %d Filter (%.0f Hz) → Gain G%d →', i, center_freqs(i), i), 'FontSize', 11);
end
text(0.1, 0.2, '↓ Sum all bands → Output y[n]', 'FontSize', 11);
text(0.1, 0.1, sprintf('Gain range: -15 dB to +15 dB per band'), 'FontSize', 10, 'FontAngle', 'italic');

%% Part 3: Equalizer Processing Function

% Create a flexible equalizer function that handles different sampling rates
process_equalizer = @(x, gains_db, current_fs) process_5band_eq_adaptive(x, filters, gains_db, current_fs);

%% Part 4: Test the equalizer with different gain settings

% Test with a sweep signal to verify equalizer response
t_test = 0:1/fs:2;  % 2 seconds
f_sweep = logspace(log10(20), log10(20000), length(t_test));
x_test = sin(2*pi*cumsum(f_sweep)*dt)';

% Test with different gain settings

% Case 1: Flat response (all gains 0 dB) - Unity Preset
gains_unity = [0, 0, 0, 0, 0];
y_unity = process_equalizer(x_test, gains_unity, fs);

% Case 2: Bass Boost
gains_bass = [9, 6, 0, 0, 0];  % dB
y_bass = process_equalizer(x_test, gains_bass, fs);

% Case 3: Treble Boost
gains_treble = [0, 0, 0, 6, 9];  % dB
y_treble = process_equalizer(x_test, gains_treble, fs);

fprintf('Test signals processed with different EQ settings\n\n');

% Plot frequency responses
figure('Position', [100, 650, 1200, 400]);

% Compute overall frequency response for each gain setting
H_overall = zeros(3, length(f_axis));
for i = 1:5
    H_overall(1,:) = H_overall(1,:) + 10^(gains_unity(i)/20) * H_bands(i,:);
    H_overall(2,:) = H_overall(2,:) + 10^(gains_bass(i)/20) * H_bands(i,:);
    H_overall(3,:) = H_overall(3,:) + 10^(gains_treble(i)/20) * H_bands(i,:);
end

subplot(1, 3, 1);
semilogx(f_axis, 20*log10(abs(H_overall(1,:))), 'b', 'LineWidth', 2);
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
title('Unity (Flat Response)');
grid on; xlim([20, 20000]); ylim([-20, 20]);
yline(0, 'k--');

subplot(1, 3, 2);
semilogx(f_axis, 20*log10(abs(H_overall(2,:))), 'r', 'LineWidth', 2);
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
title('Bass Boost');
grid on; xlim([20, 20000]); ylim([-20, 20]);
yline(0, 'k--');

subplot(1, 3, 3);
semilogx(f_axis, 20*log10(abs(H_overall(3,:))), 'g', 'LineWidth', 2);
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
title('Treble Boost');
grid on; xlim([20, 20000]); ylim([-20, 20]);
yline(0, 'k--');

sgtitle('Overall Equalizer Frequency Response with Different Gain Settings');

%% Part 5: Analysis and Summary

fprintf('\n=== EQUALIZER DESIGN SUMMARY ===\n');
fprintf('Number of bands: 5\n');
fprintf('Band center frequencies: ');
fprintf('%.0f ', center_freqs);
fprintf('Hz\n');
fprintf('Quality factor (Q): %.1f\n', Q);
fprintf('Gain range: -15 dB to +15 dB per band\n');
fprintf('\nEach band implemented as cascaded high-pass and low-pass RC filters:\n');
fprintf('  High-pass: y[n+1] = (1-α) y[n] + (x[n+1] - x[n])\n');
fprintf('  Low-pass:  y[n+1] = (1-α) y[n] + α x[n]\n');
fprintf('\nEQ settings tested:\n');
fprintf('  1. Unity (Flat): [0, 0, 0, 0, 0] dB\n');
fprintf('  2. Bass Boost: [9, 6, 0, 0, 0] dB\n');
fprintf('  3. Treble Boost: [0, 0, 0, 6, 9] dB\n');

%% Helper Function: 5-Band Equalizer (Adaptive for different fs)
function y = process_5band_eq_adaptive(x, filters, gains_db, current_fs)
    % Process input through 5-band equalizer with adaptive sampling rate
    % x: input signal (column vector)
    % filters: structure with filter parameters (designed for fs=44100)
    % gains_db: 5-element vector of gains in dB
    % current_fs: sampling rate of the input signal
    
    dt = 1/current_fs;
    y = zeros(size(x));
    
    % Process each band
    for band = 1:5
        % Convert dB gain to linear
        gain_linear = 10^(gains_db(band)/20);
        
        % Initialize band output
        y_band = zeros(size(x));
        
        % Get filter parameters and adapt alpha for current sampling rate
        % The RC time constants remain the same, but alpha = dt/tau changes
        alpha_hp = dt / (filters(band).C_hp * 1000);  % R=1000
        alpha_lp = dt / (filters(band).C_lp * 1000);
        
        % Ensure alpha is valid (should be <= 1 for stability)
        alpha_hp = min(alpha_hp, 0.99);
        alpha_lp = min(alpha_lp, 0.99);
        
        % Apply high-pass filter (resistive load configuration)
        y_hp = zeros(size(x));
        y_hp(1) = x(1);  % Initialize
        for n = 1:length(x)-1
            y_hp(n+1) = (1 - alpha_hp) * y_hp(n) + (x(n+1) - x(n));
        end
        
        % Apply low-pass filter to high-pass output (capacitive load)
        y_band(1) = y_hp(1);
        for n = 1:length(x)-1
            y_band(n+1) = (1 - alpha_lp) * y_band(n) + alpha_lp * y_hp(n);
        end
        
        % Apply gain and add to output
        y = y + gain_linear * y_band;
    end
    
    % Normalize to prevent clipping
    if max(abs(y)) > 1
        y = y / max(abs(y)) * 0.95;
    end
end
