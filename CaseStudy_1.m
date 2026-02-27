%% Matlab Homework 1 Script 
%% Introduction
clear all;close all; clc;

% * Author: Minh La
% * Class: ESE 351
% * Date: Created 15/1/2026

%% Parameters

R=1000; %Resistance(Ohm)
C=5 * 10^-6; %Capacitance =5uF
tau= R*C; %time constant
f_c= 1/(2*pi*tau); %Cutoff frequency
fs = 44100; %Sampling frequency
dt = 1/fs; % Sampling period
alpha = dt/tau; % Δt/τ 


%% Task 1: Deriving the  CT and DT LCCDE models for the RC circuit with 
%% resistive load
% Applying the KVL to the circuit
%    -x(t) + v_C(t) + v_R(t) = 0
%    x(t) = v_C(t) + v_R(t)
%
% 3. Component equations:
%    Resistor: v_R(t) = i(t)R = y(t)  (output voltage)
%    Capacitor: v_C(t) = (1/C) ∫ i(τ) dτ
%
% 4. Substitute component equations into KVL:
%    x(t) = (1/C) ∫ i(t) dt + i(t)R
%
% 5. Since y(t) = i(t)R ⇒ i(t) = y(t)/R:
%    x(t) = (1/C) ∫ [y(t)/R] dt + y(t)
%    x(t) = y(t) + (1/RC) ∫ y(t) dt
%
% 6. Differentiate both sides with respect to time:
%    dx(t)/dt = dy(t)/dt + (1/RC) y(t)
%
% 7. Rearrange to canonical LCCDE form:
%    dy(t)/dt + (1/RC) y(t) = dx(t)/dt
% Deriving DT LCCDE models
% 1. Approximate derivatives using forward difference:
%    dy/dt ≈ (y[n+1] - y[n])/Δt
%    dx/dt ≈ (x[n+1] - x[n])/Δt
%
% 2. Substitute into CT equation:
%    (y[n+1] - y[n])/Δt + (1/τ) y[n] = (x[n+1] - x[n])/Δt
%
% 3. Multiply both sides by Δt:
%    y[n+1] - y[n] + (Δt/τ) y[n] = x[n+1] - x[n]
%
% 4. Solve for y[n+1]:
%    y[n+1] = y[n] - (Δt/τ) y[n] + x[n+1] - x[n]
%
% 5. Factor y[n]:
%    y[n+1] = (1 - Δt/τ) y[n] + (x[n+1] - x[n])
%
% 6. DT LCCDE:
%    y[n+1] = (1 - α) y[n] + (x[n+1] - x[n])
%    where α = Δt/τ = Δt/(RC)

%% Task 2: MATLAB Implementation

%%2a

% Time vector
t_end = 15 * tau;
t = 0:dt:t_end;
N = length(t);

t0 = 2 * tau;
x = zeros(size(t));
x(t >= t0) = 1;

% Initialize outputs
y_cap = zeros(size(t));  % Capacitive load output
y_res = zeros(size(t));  % Resistive load output

for n=1:N-1
    % CAPACITIVE LOAD:
    % v_out[n+1] = (1 - Δt/RC) v_out[n] + (Δt/RC) v_in[n]
    y_cap(n+1) = (1 - alpha) * y_cap(n) + alpha * x(n);
    % RESISTIVE LOAD:
    % y[n+1] = (1 - α) y[n] + (x[n+1] - x[n])
    y_res(n+1) = (1 - alpha) * y_res(n) + (x(n+1) - x(n));
end

% Plot results
figure('Position', [100, 100, 1200, 500]);

% Capacitive load plot
subplot(1,2,1);
plot(t, x, 'k--', t, y_cap, 'b-', 'LineWidth', 1.5);
xlabel('Time (s)'); ylabel('Voltage (V)');
title('Capacitive Load: Eq.(4) Implementation');
legend('Input x(t)', 'Output y(t)'); grid on;
xlim([0, t_end]); ylim([-0.1, 1.2]);

% Resistive load plot
subplot(1,2,2);
plot(t, x, 'k--', t, y_res, 'r-', 'LineWidth', 1.5);
xlabel('Time (s)'); ylabel('Voltage (V)');
title('Resistive Load: DT LCCDE Implementation');
legend('Input x(t)', 'Output y(t)'); grid on;
xlim([0, t_end]); ylim([-1.1, 1.1]);

%%2b
A = 5;
frequencies = [10, 3200];
phases = [0, pi/2];

figure('Position', [100, 50, 1200, 800]);
% Initialize plot counter
plot_counter = 1;

% Loop through frequencies and phases
for f_idx = 1:length(frequencies)
    f = frequencies(f_idx);
    
    % Time for 15 periods
    t_sin_end = 15 * (1/f);
    t_sin = 0:dt:t_sin_end;
    
    for phi_idx = 1:length(phases)
        phi = phases(phi_idx);
        
        % Create sinusoidal input
        x_sin = A * cos(2*pi*f*t_sin - phi);
        
        % Initialize outputs
        y_cap_sin = zeros(size(t_sin));
        y_res_sin = zeros(size(t_sin));
        
        % Filters
        for n = 1:length(t_sin)-1
            y_cap_sin(n+1) = (1 - alpha) * y_cap_sin(n) + alpha * x_sin(n);
            y_res_sin(n+1) = (1 - alpha) * y_res_sin(n) + (x_sin(n+1) - x_sin(n));
        end
        
        % Plot capacitive load
        subplot(4, 2, plot_counter);
        plot(t_sin, x_sin, 'k--', t_sin, y_cap_sin, 'b-', 'LineWidth', 1.5);
        xlabel('Time (s)'); ylabel('Voltage (V)');
        if phi == 0
            title(sprintf('Capacitive: f = %d Hz, φ = 0', f));
        else
            title(sprintf('Capacitive: f = %d Hz, φ = π/2', f));
        end
        legend('Input', 'Output', 'Location', 'best');
        grid on;
        xlim([0, 3/f]); 
        
        subplot(4, 2, plot_counter+1);
        plot(t_sin, x_sin, 'k--', t_sin, y_res_sin, 'r-', 'LineWidth', 1.5);
        xlabel('Time (s)'); ylabel('Voltage (V)');
        if phi == 0
            title(sprintf('Resistive: f = %d Hz, φ = 0', f));
        else
            title(sprintf('Resistive: f = %d Hz, φ = π/2', f));
        end
        legend('Input', 'Output', 'Location', 'best');
        grid on;
        xlim([0, 3/f]);  
        
        plot_counter = plot_counter + 2;
    end
end

sgtitle('RC Circuit Sinusoidal Response Analysis');

%% Task 3: Answering the questions
% a. Yes, both RC circuits are time-invariant systems.
% For the delayed step unit (t0 = 2pi) the output response are delayed
% versions of the responses to a step at t=0, the shape of the response
% doesn't change with the timing of the input. To be more precise, R, C
% ,V=IR , i=C*dv/dt doesn't depend on time variable
% b. We have capacitive load at a low pass filter and resistive load at a
% high pass filter. This does checks out as capacitive load acts as open
% circuits as DC and short circuits at high frequency while capcitator
% short circuits at high frequency and open circuit at DC
% c.
close all;
load handel.mat;
audio = y;
original_fs = Fs; 
if size(audio, 2) > 1
    audio = audio(:, 1);
end

% Use audio's original sampling rate (8192 Hz)
fs_audio = original_fs;  % Use 8192 Hz for audio
dt_audio = 1/fs_audio;
alpha_audio = dt_audio / tau;  % Recalculate alpha for audio

% Take first 3 seconds
max_samples = 3 * fs_audio;
if length(audio) > max_samples
    audio = audio(1:max_samples);
end

% Normalize audio
audio = 0.8 * audio / max(abs(audio));

audio_low = zeros(size(audio));   % Low-pass result
audio_high = zeros(size(audio));  % High-pass result

% Apply filters with audio's alpha
for n = 1:length(audio)-1
    % Low-pass filter (capacitive load)
    audio_low(n+1) = (1 - alpha_audio) * audio_low(n) + alpha_audio * audio(n);
    % High-pass filter (resistive load)
    audio_high(n+1) = (1 - alpha_audio) * audio_high(n) + (audio(n+1) - audio(n));
end

% Normalize outputs
audio_low = 0.8 * audio_low / max(abs(audio_low));
audio_high = 0.8 * audio_high / max(abs(audio_high));

% Create a new figure for audio analysis
figure('Position', [100, 100, 1200, 800], 'Name', 'Audio Filtering', 'NumberTitle', 'off');

% Play audio with pauses
subplot(3,2,1);
sound(audio, fs_audio);
title('Playing: Original Audio');
xlabel('Status'); ylabel('');
text(0.5, 0.5, 'Original audio playing...', 'HorizontalAlignment', 'center', 'FontSize', 12);
axis off;
pause(4); 

subplot(3,2,3);
sound(audio_low, fs_audio);
title('Playing: Low-Pass Filtered');
xlabel('Status'); ylabel('');
text(0.5, 0.5, 'Low-pass audio playing...', 'HorizontalAlignment', 'center', 'FontSize', 12);
axis off;
pause(4);

subplot(3,2,5);
sound(audio_high, fs_audio);
title('Playing: High-Pass Filtered');
xlabel('Status'); ylabel('');
text(0.5, 0.5, 'High-pass audio playing...', 'HorizontalAlignment', 'center', 'FontSize', 12);
axis off;
pause(4);

% Create time vector for audio using audio's sampling rate
t_audio = (0:length(audio)-1)/fs_audio; 

% Plot waveforms
subplot(3,2,2);
plot(t_audio, audio, 'b-', 'LineWidth', 1);
title('Original Audio Waveform');
xlabel('Time (seconds)'); ylabel('Amplitude');
grid on; ylim([-1, 1]); xlim([0, t_audio(end)]);

subplot(3,2,4);
plot(t_audio, audio_low, 'r-', 'LineWidth', 1);
title('Low-Pass Filtered Waveform');
xlabel('Time (seconds)'); ylabel('Amplitude');
grid on; ylim([-1, 1]); xlim([0, t_audio(end)]);

subplot(3,2,6);
plot(t_audio, audio_high, 'g-', 'LineWidth', 1);
title('High-Pass Filtered Waveform');
xlabel('Time (seconds)'); ylabel('Amplitude');
grid on; ylim([-1, 1]); xlim([0, t_audio(end)]);

