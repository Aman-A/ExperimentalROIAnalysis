function t2 = estThreshScaling(t1,pw1,tau_ch,pw2)
% Estimate threshold at different pulse width given threshold at one pulse
% width, estimate threshold at different pulse width with assumed chronaxie
% (using Weiss equation) -> threshold = rheobase*(1 + tau_ch/pw)
f = pw2/pw1; % pw factor
t2_t1_ratio = (pw1 + tau_ch/f)/(pw1 + tau_ch); % t2/t1
t2 = t1*t2_t1_ratio; 
fprintf('Threshold with PW2 (%g) is %.3fx of threshold at PW1 (%g)  -> %.3f\n',...
        pw2,t2_t1_ratio,pw1,t2);
end