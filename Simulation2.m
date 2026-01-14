% Cross-strapping 1 - Part B: Simulation WITH Repair
% Course: Reliability of Systems
clc; clear; close all;

%% 1. Παράμετροι Συστήματος
MTTF = 27;           % Mean Time To Failure (hours)
MTTR = 12;           % Mean Time To Repair (hours)
T_sim = 1000;        % Χρόνος προσομοίωσης για τα στατιστικά (αρκετά μεγάλος για εγκυρότητα)
dt = 0.1;            % Χρονικό βήμα (λεπτομέρεια προσομοίωσης)
N = 100;             % Αριθμός επαναλήψεων Monte Carlo (για μέσους όρους)

% Θεωρητική Διαθεσιμότητα (Availability) Εξαρτήματος
A_comp_theo = MTTF / (MTTF + MTTR);

fprintf('--- Έναρξη Προσομοίωσης με Επιδιόρθωση (N=%d) ---\n', N);

%% 2. Προσομοίωση Monte Carlo (Στατιστική Ανάλυση)
% Πίνακες για αποθήκευση των μετρικών κάθε επανάληψης
results_A_sys = zeros(N, 1);
results_MTBF_sys = zeros(N, 1);
results_MUT_sys = zeros(N, 1);
results_MTTR_sys = zeros(N, 1);

time_axis = 0:dt:T_sim;
num_steps = length(time_axis);

for i = 1:N
    % Γεννήτρια καταστάσεων για τα 4 εξαρτήματα (1=Λειτουργία, 0=Βλάβη)
    % C_states είναι πίνακας [num_steps x 4]
    C_states = generate_component_history(4, time_axis, MTTF, MTTR);
    
    % Λογική Cross-strapping 1: (C1 OR C2) AND (C3 OR C4)
    Block1 = C_states(:,1) | C_states(:,2);
    Block2 = C_states(:,3) | C_states(:,4);
    System_State = Block1 & Block2;
    
    % Υπολογισμός Μετρικών για αυτή την επανάληψη
    [A, MUT, MTTR_val, MTBF] = calculate_metrics(System_State, dt);
    
    results_A_sys(i) = A;
    results_MUT_sys(i) = MUT;
    results_MTTR_sys(i) = MTTR_val;
    results_MTBF_sys(i) = MTBF;
end

% Μέσοι όροι από όλες τις επαναλήψεις
Exp_A = mean(results_A_sys);
Exp_MUT = mean(results_MUT_sys);
Exp_MTTR = mean(results_MTTR_sys);
Exp_MTBF = mean(results_MTBF_sys);

%% 3. Θεωρητικοί Υπολογισμοί (για επαλήθευση)
% R_block = 1 - (1 - R_comp)^2 => A_block = 1 - (1 - A_comp)^2
A_block_theo = 1 - (1 - A_comp_theo)^2;
% A_sys = A_block * A_block (σειρά)
A_sys_theo = A_block_theo * A_block_theo;

%% 4. Εκτύπωση Αποτελεσμάτων
fprintf('\n--- Αποτελέσματα ΣΥΣΤΗΜΑΤΟΣ (Μέσοι Όροι) ---\n');
fprintf('Availability (A):  Θεωρ = %.4f | Πειρ = %.4f (Σφάλμα: %.2f%%)\n', ...
    A_sys_theo, Exp_A, abs(A_sys_theo - Exp_A)/A_sys_theo*100);
fprintf('MTBF (h):          Πειρ = %.2f\n', Exp_MTBF);
fprintf('MUT (h):           Πειρ = %.2f\n', Exp_MUT);
fprintf('MTTR (h):          Πειρ = %.2f\n', Exp_MTTR);
fprintf('(Έλεγχος: MUT+MTTR = %.2f)\n', Exp_MUT + Exp_MTTR);

%% 5. Δημιουργία Γραφήματος (Gantt Chart) - Ζητούμενο 4
% Τρέχουμε μία μικρή προσομοίωση (π.χ. 100 ώρες) μόνο για το γράφημα
T_plot = 100;
t_plot_axis = 0:dt:T_plot;
C_plot = generate_component_history(4, t_plot_axis, MTTF, MTTR);
S_plot = (C_plot(:,1) | C_plot(:,2)) & (C_plot(:,3) | C_plot(:,4));

figure('Position', [100, 100, 1000, 600]);
hold on;
% Χρώματα
colors = {'b', 'b', 'm', 'm', 'r'}; % C1, C2, C3, C4, System
labels = {'C1', 'C2', 'C3', 'C4', 'SYSTEM'};
y_positions = [1, 2, 3, 4, 5.5]; % Θέσεις στον άξονα Υ

% Σχεδίαση γραμμών
for k = 1:4
    % Σχεδιάζουμε γραμμή μόνο εκεί που είναι "1" (Λειτουργία)
    draw_gantt_line(t_plot_axis, C_plot(:,k), y_positions(k), colors{k}, 4);
end
% Σχεδίαση Συστήματος (πιο παχιά γραμμή)
draw_gantt_line(t_plot_axis, S_plot, y_positions(5), colors{5}, 8);

% Μορφοποίηση
ylim([0 7]);
yticks(y_positions);
yticklabels(labels);
xlabel('Χρόνος (ώρες)');
title('Χρονοδιάγραμμα Λειτουργίας (Gantt Chart) - Cross-strapping 1');
grid on;
saveas(gcf, 'gantt_chart.png');
fprintf('\nΤο διάγραμμα αποθηκεύτηκε ως "gantt_chart.png".\n');


%% --- ΒΟΗΘΗΤΙΚΕΣ ΣΥΝΑΡΤΗΣΕΙΣ ---

function states = generate_component_history(num_comps, t_axis, mttf, mttr)
    % Δημιουργεί το ιστορικό λειτουργίας για κάθε εξάρτημα
    steps = length(t_axis);
    states = zeros(steps, num_comps);
    dt = t_axis(2) - t_axis(1);
    
    for j = 1:num_comps
        current_t = 0;
        is_working = true; % Ξεκινάμε λειτουργικοί
        
        while current_t < t_axis(end)
            if is_working
                duration = -mttf * log(rand()); % Χρόνος μέχρι βλάβη
                state_val = 1;
            else
                duration = -mttr * log(rand()); % Χρόνος επισκευής
                state_val = 0;
            end
            
            % Μετατροπή χρόνου σε δείκτες πίνακα
            start_idx = floor(current_t / dt) + 1;
            end_idx = floor((current_t + duration) / dt) + 1;
            
            if start_idx > steps, break; end
            if end_idx > steps, end_idx = steps; end
            
            states(start_idx:end_idx, j) = state_val;
            
            current_t = current_t + duration;
            is_working = ~is_working; % Εναλλαγή κατάστασης
        end
    end
end

function [A, MUT, MTTR, MTBF] = calculate_metrics(state_vector, dt)
    % Υπολογίζει τις μετρικές από ένα διάνυσμα καταστάσεων (0/1)
    total_time = length(state_vector) * dt;
    total_up_time = sum(state_vector) * dt;
    
    % Availability
    A = total_up_time / total_time;
    
    % Βρίσκουμε τις μεταβάσεις (edges)
    % diff = 1 (από 0 σε 1 -> Repair finished)
    % diff = -1 (από 1 σε 0 -> Failure)
    d = diff([0; state_vector; 0]); % Padding για να πιάσουμε άκρα
    
    ups = find(d == 1);   % Indices where UP starts
    downs = find(d == -1); % Indices where UP ends
    
    num_failures = length(downs) - 1; % Αφαιρούμε το padding τέλους αν ήταν UP
    
    % Μήκη διαστημάτων λειτουργίας (Up durations)
    up_durations = (downs - ups) * dt;
    
    % Μήκη διαστημάτων βλάβης (Down durations)
    % Ο χρόνος μεταξύ τέλους ενός UP και αρχής επόμενου UP
    if length(ups) > 1
        down_durations = (ups(2:end) - downs(1:end-1)) * dt;
    else
        down_durations = 0;
    end
    
    if isempty(up_durations)
        MUT = 0; MTTR = 0; MTBF = 0;
    else
        MUT = mean(up_durations);
        if isempty(down_durations) || sum(down_durations)==0
             MTTR = 0; % Δεν χάλασε ποτέ ή δεν πρόλαβε να φτιαχτεί
        else
             MTTR = mean(down_durations);
        end
        MTBF = MUT + MTTR; 
    end
end

function draw_gantt_line(t, state, y_pos, col, width)
    % Σχεδιάζει μια διακεκομμένη γραμμή όπου state == 1
    % Χρησιμοποιούμε NaN για να σπάσουμε τη γραμμή στα κενά
    
    plot_y = state * y_pos;
    plot_y(plot_y == 0) = NaN; % Κρύβουμε τα σημεία που είναι 0
    
    plot(t, plot_y, 'Color', col, 'LineWidth', width);
end