function amps = getThreshLadderSettings(expected_thresh,per_step_size,num_steps)
% expected_thresh: Expected threshold amplitude
% per_step_size: step size as percentage (%)
% num_steps: number of amplitude steps in ladder

step_size = expected_thresh*per_step_size/100; 
start_amp = expected_thresh-step_size*num_steps/2;
amps = start_amp:step_size:(start_amp + step_size*(num_steps-1));
fprintf('Start amp = %.4f, step size = %.4f, num_steps = %g, end amp = %.4f\n',...
    start_amp,step_size,num_steps,amps(end))