% main.m
% ================================================================================
% This script builds three models for a fuzzy-based task-to-thread mapping in
% OpenMP using three controllers, as follows, through a multi-queue system.
% Controller 1: It is provided for the allocation phase to select a queue for each
% task.
% Controller 2: It is provided for the dispatching phase to select a ready task
% from the queue with an idle thread.
% Controller 3: It is similar to Controller 2, with the difference that the
% IF-THEN rules are different.
% ================================================================================
% Copyright 2024 Instituto Superior de Engenharia do Porto
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%              http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
% ================================================================================
%% Create the screen and variables
clear all
clc

%% Add the 'functions' folder including the fuzzy functions to the workspace
addpath(genpath('functions'))

%% Specify shape factor (sf) and type of the membership function
%% 't' for triangular membership, and 'b' for bell-shaped membership
% Number of tasks
num_of_task_sf = 6;
num_of_task_type = 'i';

% Total execution time
tot_exe_time_sf = 116000000;
tot_exe_time_type = 'i';

% Execution time
exe_time_sf = 40000000;
exe_time_type = 'i';

% Waiting time
wait_time_sf = 70000000;
wait_time_type = 'i';

% Selection rate
sel_rate_sf = 100;
sel_rate_type = 'b';

%% Determine membership function for the inputs and outputs
% Number of tasks
u_num_of_task = 2:0.08:10;
mu_num_of_task_feeble = fuzzifysn(u_num_of_task, 2, num_of_task_type, num_of_task_sf);
mu_num_of_task_few = fuzzifysn(u_num_of_task, 4, num_of_task_type, num_of_task_sf);
mu_num_of_task_normal = fuzzifysn(u_num_of_task, 6, num_of_task_type, num_of_task_sf);
mu_num_of_task_many = fuzzifysn(u_num_of_task, 8, num_of_task_type, num_of_task_sf);
mu_num_of_task_lots = fuzzifysn(u_num_of_task, 10, num_of_task_type, num_of_task_sf);

% Total execution time
u_tot_exe_time = 0:2320000:232000000;
mu_tot_exe_time_verysmall = fuzzifysn(u_tot_exe_time, 0, tot_exe_time_type, tot_exe_time_sf);
mu_tot_exe_time_small = fuzzifysn(u_tot_exe_time, 58000000, tot_exe_time_type, tot_exe_time_sf);
mu_tot_exe_time_mean = fuzzifysn(u_tot_exe_time, 116000000, tot_exe_time_type, tot_exe_time_sf);
mu_tot_exe_time_large = fuzzifysn(u_tot_exe_time, 174000000, tot_exe_time_type, tot_exe_time_sf);
mu_tot_exe_time_verylarge = fuzzifysn(u_tot_exe_time, 232000000, tot_exe_time_type, tot_exe_time_sf);

% Execution time
u_exe_time = 0:800000:80000000;
mu_exe_time_extremelyslow = fuzzifysn(u_exe_time, 0, exe_time_type, exe_time_sf);
mu_exe_time_slow = fuzzifysn(u_exe_time, 20000000, exe_time_type, exe_time_sf);
mu_exe_time_average = fuzzifysn(u_exe_time, 40000000, exe_time_type, exe_time_sf);
mu_exe_time_fast = fuzzifysn(u_exe_time, 60000000, exe_time_type, exe_time_sf);
mu_exe_time_extremelyfast = fuzzifysn(u_exe_time, 80000000, exe_time_type, exe_time_sf);

% Waiting time
u_wait_time = 0:1450000:145000000;
mu_wait_time_veryshort = fuzzifysn(u_wait_time, 0, wait_time_type, wait_time_sf);
mu_wait_time_short = fuzzifysn(u_wait_time, 36250000, wait_time_type, wait_time_sf);
mu_wait_time_mediocre = fuzzifysn(u_wait_time, 72500000, wait_time_type, wait_time_sf);
mu_wait_time_long = fuzzifysn(u_wait_time, 108750000, wait_time_type, wait_time_sf);
mu_wait_time_verylong = fuzzifysn(u_wait_time, 145000000, wait_time_type, wait_time_sf);

% Selection rate
u_sel_rate = 0:0.01:1;
mu_sel_rate_verylow = fuzzifysn(u_sel_rate, 0, sel_rate_type, sel_rate_sf);
mu_sel_rate_low = fuzzifysn(u_sel_rate, 0.25, sel_rate_type, sel_rate_sf);
mu_sel_rate_medium = fuzzifysn(u_sel_rate, 0.5, sel_rate_type, sel_rate_sf);
mu_sel_rate_high = fuzzifysn(u_sel_rate, 0.75, sel_rate_type, sel_rate_sf);
mu_sel_rate_veryhigh = fuzzifysn(u_sel_rate, 1, sel_rate_type, sel_rate_sf);

%% Show membership function of the inputs and outputs
% Controller 1
figure(1)
subplot(3,1,1)
hold on
plot(u_num_of_task,mu_num_of_task_feeble,'-k','LineWidth',3)
plot(u_num_of_task,mu_num_of_task_few,'-.b','LineWidth',3)
plot(u_num_of_task,mu_num_of_task_normal,':r','LineWidth',3)
plot(u_num_of_task,mu_num_of_task_many,'--g','LineWidth',3)
plot(u_num_of_task,mu_num_of_task_lots,'-m','LineWidth',3)
legend('Feeble','Few','Normal','Many','Lots','Location','North','Orientation','Horizontal')
xlabel('Number of tasks')
ylabel('Degree (\mu)')
hold off

subplot(3,1,2)
hold on
plot(u_tot_exe_time,mu_tot_exe_time_verysmall,'-k','LineWidth',3)
plot(u_tot_exe_time,mu_tot_exe_time_small,'-.b','LineWidth',3)
plot(u_tot_exe_time,mu_tot_exe_time_mean,':r','LineWidth',3)
plot(u_tot_exe_time,mu_tot_exe_time_large,'--g','LineWidth',3)
plot(u_tot_exe_time,mu_tot_exe_time_verylarge,'-m','LineWidth',3)
legend('Very Small','Small','Mean','Large','Very Large','Location','North','Orientation','Horizontal')
xlabel('Total execution time (ns)')
ylabel('Degree (\mu)')
hold off

subplot(3,1,3)
hold on
plot(u_sel_rate,mu_sel_rate_verylow,'-k','LineWidth',3)
plot(u_sel_rate,mu_sel_rate_low,'-.b','LineWidth',3)
plot(u_sel_rate,mu_sel_rate_medium,':r','LineWidth',3)
plot(u_sel_rate,mu_sel_rate_high,'--g','LineWidth',3)
plot(u_sel_rate,mu_sel_rate_veryhigh,'-m','LineWidth',3)
legend('Very Low','Low','Medium','High','Very High','Location','North','Orientation','Horizontal')
xlabel('Selection rate')
ylabel('Degree (\mu)')
hold off

% Controllers 2 and 3
figure(2)
subplot(3,1,1)
hold on
plot(u_exe_time,mu_exe_time_extremelyslow,'-k','LineWidth',3)
plot(u_exe_time,mu_exe_time_slow,'-.b','LineWidth',3)
plot(u_exe_time,mu_exe_time_average,':r','LineWidth',3)
plot(u_exe_time,mu_exe_time_fast,'--g','LineWidth',3)
plot(u_exe_time,mu_exe_time_extremelyfast,'-m','LineWidth',3)
legend('Extremely Slow','Slow','Average','Fast','Extremely Fast','Location','North','Orientation','Horizontal')
xlabel('Execution time (ns)')
ylabel('Degree (\mu)')
hold off

subplot(3,1,2)
hold on
plot(u_wait_time,mu_wait_time_veryshort,'-k','LineWidth',3)
plot(u_wait_time,mu_wait_time_short,'-.b','LineWidth',3)
plot(u_wait_time,mu_wait_time_mediocre,':r','LineWidth',3)
plot(u_wait_time,mu_wait_time_long,'--g','LineWidth',3)
plot(u_wait_time,mu_wait_time_verylong,'-m','LineWidth',3)
legend('Very Short','Short','Mediocre','Long','Very Long','Location','North','Orientation','Horizontal')
xlabel('Waiting time (ns)')
ylabel('Degree (\mu)')
hold off

subplot(3,1,3)
hold on
plot(u_sel_rate,mu_sel_rate_verylow,'-k','LineWidth',3)
plot(u_sel_rate,mu_sel_rate_low,'-.b','LineWidth',3)
plot(u_sel_rate,mu_sel_rate_medium,':r','LineWidth',3)
plot(u_sel_rate,mu_sel_rate_high,'--g','LineWidth',3)
plot(u_sel_rate,mu_sel_rate_veryhigh,'-m','LineWidth',3)
legend('Very Low','Low','Medium','High','Very High','Location','North','Orientation','Horizontal')
xlabel('Selection rate')
ylabel('Degree (\mu)')
hold off

%% Build the models using the fuzzy controllers
% Model 1 using Controller 1
mu_AB = fuzzyand(mu_num_of_task_feeble, mu_tot_exe_time_verysmall);
R1 = rulemakem(mu_AB, mu_sel_rate_veryhigh);

mu_AB = fuzzyand(mu_num_of_task_feeble, mu_tot_exe_time_small);
R2 = rulemakem(mu_AB, mu_sel_rate_veryhigh);

mu_AB = fuzzyand(mu_num_of_task_feeble, mu_tot_exe_time_mean);
R3 = rulemakem(mu_AB, mu_sel_rate_high);

mu_AB = fuzzyand(mu_num_of_task_feeble, mu_tot_exe_time_large);
R4 = rulemakem(mu_AB, mu_sel_rate_medium);

mu_AB = fuzzyand(mu_num_of_task_feeble, mu_tot_exe_time_verylarge);
R5 = rulemakem(mu_AB, mu_sel_rate_low);

mu_AB = fuzzyand(mu_num_of_task_few, mu_tot_exe_time_verysmall);
R6 = rulemakem(mu_AB, mu_sel_rate_veryhigh);

mu_AB = fuzzyand(mu_num_of_task_few, mu_tot_exe_time_small);
R7 = rulemakem(mu_AB, mu_sel_rate_high);

mu_AB = fuzzyand(mu_num_of_task_few, mu_tot_exe_time_mean);
R8 = rulemakem(mu_AB, mu_sel_rate_medium);

mu_AB = fuzzyand(mu_num_of_task_few, mu_tot_exe_time_large);
R9 = rulemakem(mu_AB, mu_sel_rate_medium);

mu_AB = fuzzyand(mu_num_of_task_few, mu_tot_exe_time_verylarge);
R10 = rulemakem(mu_AB, mu_sel_rate_low);

mu_AB = fuzzyand(mu_num_of_task_normal, mu_tot_exe_time_verysmall);
R11 = rulemakem(mu_AB, mu_sel_rate_high);

mu_AB = fuzzyand(mu_num_of_task_normal, mu_tot_exe_time_small);
R12 = rulemakem(mu_AB, mu_sel_rate_medium);

mu_AB = fuzzyand(mu_num_of_task_normal, mu_tot_exe_time_mean);
R13 = rulemakem(mu_AB, mu_sel_rate_medium);

mu_AB = fuzzyand(mu_num_of_task_normal, mu_tot_exe_time_large);
R14 = rulemakem(mu_AB, mu_sel_rate_low);

mu_AB = fuzzyand(mu_num_of_task_normal, mu_tot_exe_time_verylarge);
R15 = rulemakem(mu_AB, mu_sel_rate_low);

mu_AB = fuzzyand(mu_num_of_task_many, mu_tot_exe_time_verysmall);
R16 = rulemakem(mu_AB, mu_sel_rate_high);

mu_AB = fuzzyand(mu_num_of_task_many, mu_tot_exe_time_small);
R17 = rulemakem(mu_AB, mu_sel_rate_medium);

mu_AB = fuzzyand(mu_num_of_task_many, mu_tot_exe_time_mean);
R18 = rulemakem(mu_AB, mu_sel_rate_low);

mu_AB = fuzzyand(mu_num_of_task_many, mu_tot_exe_time_large);
R19 = rulemakem(mu_AB, mu_sel_rate_low);

mu_AB = fuzzyand(mu_num_of_task_many, mu_tot_exe_time_verylarge);
R20 = rulemakem(mu_AB, mu_sel_rate_verylow);

mu_AB = fuzzyand(mu_num_of_task_lots, mu_tot_exe_time_verysmall);
R21 = rulemakem(mu_AB, mu_sel_rate_high);

mu_AB = fuzzyand(mu_num_of_task_lots, mu_tot_exe_time_small);
R22 = rulemakem(mu_AB, mu_sel_rate_medium);

mu_AB = fuzzyand(mu_num_of_task_lots, mu_tot_exe_time_mean);
R23 = rulemakem(mu_AB, mu_sel_rate_low);

mu_AB = fuzzyand(mu_num_of_task_lots, mu_tot_exe_time_large);
R24 = rulemakem(mu_AB, mu_sel_rate_verylow);

mu_AB = fuzzyand(mu_num_of_task_lots, mu_tot_exe_time_verylarge);
R25 = rulemakem(mu_AB, mu_sel_rate_verylow);

TR1 = totalrule(R1, R2, R3, R4, R5, R6, R7, R8, R9, R10, R11, R12, R13, R14, R15, R16, R17, R18, R19, R20, R21, R22, R23, R24, R25);
writematrix(TR1, 'output/model1.dat')
disp('Model 1 was created.')

% Model 2 using Controller 2
mu_AB = fuzzyand(mu_exe_time_extremelyslow, mu_wait_time_veryshort);
R1 = rulemakem(mu_AB, mu_sel_rate_medium);

mu_AB = fuzzyand(mu_exe_time_extremelyslow, mu_wait_time_short);
R2 = rulemakem(mu_AB, mu_sel_rate_medium);

mu_AB = fuzzyand(mu_exe_time_extremelyslow, mu_wait_time_mediocre);
R3 = rulemakem(mu_AB, mu_sel_rate_high);

mu_AB = fuzzyand(mu_exe_time_extremelyslow, mu_wait_time_long);
R4 = rulemakem(mu_AB, mu_sel_rate_veryhigh);

mu_AB = fuzzyand(mu_exe_time_extremelyslow, mu_wait_time_verylong);
R5 = rulemakem(mu_AB, mu_sel_rate_veryhigh);

mu_AB = fuzzyand(mu_exe_time_slow, mu_wait_time_veryshort);
R6 = rulemakem(mu_AB, mu_sel_rate_low);

mu_AB = fuzzyand(mu_exe_time_slow, mu_wait_time_short);
R7 = rulemakem(mu_AB, mu_sel_rate_low);

mu_AB = fuzzyand(mu_exe_time_slow, mu_wait_time_mediocre);
R8 = rulemakem(mu_AB, mu_sel_rate_medium);

mu_AB = fuzzyand(mu_exe_time_slow, mu_wait_time_long);
R9 = rulemakem(mu_AB, mu_sel_rate_high);

mu_AB = fuzzyand(mu_exe_time_slow, mu_wait_time_verylong);
R10 = rulemakem(mu_AB, mu_sel_rate_veryhigh);

mu_AB = fuzzyand(mu_exe_time_average, mu_wait_time_veryshort);
R11 = rulemakem(mu_AB, mu_sel_rate_low);

mu_AB = fuzzyand(mu_exe_time_average, mu_wait_time_short);
R12 = rulemakem(mu_AB, mu_sel_rate_medium);

mu_AB = fuzzyand(mu_exe_time_average, mu_wait_time_mediocre);
R13 = rulemakem(mu_AB, mu_sel_rate_medium);

mu_AB = fuzzyand(mu_exe_time_average, mu_wait_time_long);
R14 = rulemakem(mu_AB, mu_sel_rate_high);

mu_AB = fuzzyand(mu_exe_time_average, mu_wait_time_verylong);
R15 = rulemakem(mu_AB, mu_sel_rate_high);

mu_AB = fuzzyand(mu_exe_time_fast, mu_wait_time_veryshort);
R16 = rulemakem(mu_AB, mu_sel_rate_verylow);

mu_AB = fuzzyand(mu_exe_time_fast, mu_wait_time_short);
R17 = rulemakem(mu_AB, mu_sel_rate_low);

mu_AB = fuzzyand(mu_exe_time_fast, mu_wait_time_mediocre);
R18 = rulemakem(mu_AB, mu_sel_rate_low);

mu_AB = fuzzyand(mu_exe_time_fast, mu_wait_time_long);
R19 = rulemakem(mu_AB, mu_sel_rate_medium);

mu_AB = fuzzyand(mu_exe_time_fast, mu_wait_time_verylong);
R20 = rulemakem(mu_AB, mu_sel_rate_medium);

mu_AB = fuzzyand(mu_exe_time_extremelyfast, mu_wait_time_veryshort);
R21 = rulemakem(mu_AB, mu_sel_rate_verylow);

mu_AB = fuzzyand(mu_exe_time_extremelyfast, mu_wait_time_short);
R22 = rulemakem(mu_AB, mu_sel_rate_verylow);

mu_AB = fuzzyand(mu_exe_time_extremelyfast, mu_wait_time_mediocre);
R23 = rulemakem(mu_AB, mu_sel_rate_low);

mu_AB = fuzzyand(mu_exe_time_extremelyfast, mu_wait_time_long);
R24 = rulemakem(mu_AB, mu_sel_rate_medium);

mu_AB = fuzzyand(mu_exe_time_extremelyfast, mu_wait_time_verylong);
R25 = rulemakem(mu_AB, mu_sel_rate_medium);

TR2 = totalrule(R1, R2, R3, R4, R5, R6, R7, R8, R9, R10, R11, R12, R13, R14, R15, R16, R17, R18, R19, R20, R21, R22, R23, R24, R25);
writematrix(TR2, 'output/model2.dat')
disp('Model 2 was created.')

% Model 3 using Controller 3
mu_AB = fuzzyand(mu_exe_time_extremelyslow, mu_wait_time_veryshort);
R1 = rulemakem(mu_AB, mu_sel_rate_verylow);

mu_AB = fuzzyand(mu_exe_time_extremelyslow, mu_wait_time_short);
R2 = rulemakem(mu_AB, mu_sel_rate_verylow);

mu_AB = fuzzyand(mu_exe_time_extremelyslow, mu_wait_time_mediocre);
R3 = rulemakem(mu_AB, mu_sel_rate_low);

mu_AB = fuzzyand(mu_exe_time_extremelyslow, mu_wait_time_long);
R4 = rulemakem(mu_AB, mu_sel_rate_medium);

mu_AB = fuzzyand(mu_exe_time_extremelyslow, mu_wait_time_verylong);
R5 = rulemakem(mu_AB, mu_sel_rate_medium);

mu_AB = fuzzyand(mu_exe_time_slow, mu_wait_time_veryshort);
R6 = rulemakem(mu_AB, mu_sel_rate_verylow);

mu_AB = fuzzyand(mu_exe_time_slow, mu_wait_time_short);
R7 = rulemakem(mu_AB, mu_sel_rate_low);

mu_AB = fuzzyand(mu_exe_time_slow, mu_wait_time_mediocre);
R8 = rulemakem(mu_AB, mu_sel_rate_low);

mu_AB = fuzzyand(mu_exe_time_slow, mu_wait_time_long);
R9 = rulemakem(mu_AB, mu_sel_rate_medium);

mu_AB = fuzzyand(mu_exe_time_slow, mu_wait_time_verylong);
R10 = rulemakem(mu_AB, mu_sel_rate_medium);

mu_AB = fuzzyand(mu_exe_time_average, mu_wait_time_veryshort);
R11 = rulemakem(mu_AB, mu_sel_rate_low);

mu_AB = fuzzyand(mu_exe_time_average, mu_wait_time_short);
R12 = rulemakem(mu_AB, mu_sel_rate_low);

mu_AB = fuzzyand(mu_exe_time_average, mu_wait_time_mediocre);
R13 = rulemakem(mu_AB, mu_sel_rate_medium);

mu_AB = fuzzyand(mu_exe_time_average, mu_wait_time_long);
R14 = rulemakem(mu_AB, mu_sel_rate_medium);

mu_AB = fuzzyand(mu_exe_time_average, mu_wait_time_verylong);
R15 = rulemakem(mu_AB, mu_sel_rate_high);

mu_AB = fuzzyand(mu_exe_time_fast, mu_wait_time_veryshort);
R16 = rulemakem(mu_AB, mu_sel_rate_low);

mu_AB = fuzzyand(mu_exe_time_fast, mu_wait_time_short);
R17 = rulemakem(mu_AB, mu_sel_rate_medium);

mu_AB = fuzzyand(mu_exe_time_fast, mu_wait_time_mediocre);
R18 = rulemakem(mu_AB, mu_sel_rate_medium);

mu_AB = fuzzyand(mu_exe_time_fast, mu_wait_time_long);
R19 = rulemakem(mu_AB, mu_sel_rate_high);

mu_AB = fuzzyand(mu_exe_time_fast, mu_wait_time_verylong);
R20 = rulemakem(mu_AB, mu_sel_rate_veryhigh);

mu_AB = fuzzyand(mu_exe_time_extremelyfast, mu_wait_time_veryshort);
R21 = rulemakem(mu_AB, mu_sel_rate_medium);

mu_AB = fuzzyand(mu_exe_time_extremelyfast, mu_wait_time_short);
R22 = rulemakem(mu_AB, mu_sel_rate_medium);

mu_AB = fuzzyand(mu_exe_time_extremelyfast, mu_wait_time_mediocre);
R23 = rulemakem(mu_AB, mu_sel_rate_high);

mu_AB = fuzzyand(mu_exe_time_extremelyfast, mu_wait_time_long);
R24 = rulemakem(mu_AB, mu_sel_rate_veryhigh);

mu_AB = fuzzyand(mu_exe_time_extremelyfast, mu_wait_time_verylong);
R25 = rulemakem(mu_AB, mu_sel_rate_veryhigh);

TR3 = totalrule(R1, R2, R3, R4, R5, R6, R7, R8, R9, R10, R11, R12, R13, R14, R15, R16, R17, R18, R19, R20, R21, R22, R23, R24, R25);
writematrix(TR3, 'output/model3.dat')
disp('Model 3 was created.')

%% Show membership graph of the inputs and outputs based on the models
% Controller 1
figure(3)
surf(u_num_of_task,u_tot_exe_time,TR1,'EdgeColor','none')
colorbar
colormap('Jet')
xlabel('Number of tasks')
ylabel('Total execution time (ns)')
zlabel('Degree (\mu)')

% Controller 2
figure(4)
surf(u_exe_time,u_wait_time,TR2,'EdgeColor','none')
colorbar
colormap('Jet')
xlabel('Execution time (ns)')
ylabel('Waiting time (ns)')
zlabel('Degree (\mu)')

% Controller 3
figure(5)
surf(u_exe_time,u_wait_time,TR3,'EdgeColor','none')
colorbar
colormap('Jet')
xlabel('Execution time (ns)')
ylabel('Waiting time (ns)')
zlabel('Degree (\mu)')
