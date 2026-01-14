% Cross-strapping 1 - Part A: Simulation without Repair
% Course: Reliability of Systems
clc; clear; close all;

%% 1. Παράμετροι Συστήματος & Προσομοίωσης
MTTF = 27;          % Mean Time To Failure (ώρες)
MTTR = 12;          % Δεν χρησιμοποιείται στο Μέρος Α, αλλά δίνεται
DutyCycle = 1;      % Συνεχής λειτουργία
Tc = 200;           % Χρόνος μελέτης εξαρτημάτων
Ts = 30;            % Χρόνος μελέτης συστήματος
N = 10000;          % Αριθμός επαναλήψεων Monte Carlo (αυξημένο για ακρίβεια)

lambda = 1 / MTTF;  % Ρυθμός αποτυχίας (θεωρητικός)

fprintf('--- Έναρξη Προσομοίωσης (N=%d) ---\n', N);

%% 2. Προσομοίωση Monte Carlo (Vectorized)
% Γεννούμε τυχαίους χρόνους βλάβης για N επαναλήψεις και 4 εξαρτήματα.
% Χρησιμοποιούμε τον αντίστροφο μετασχηματισμό: T = -MTTF * ln(rand)
% Στήλες 1,2: Εξαρτήματα C1, C2 (Πρώτη Βαθμίδα)
% Στήλες 3,4: Εξαρτήματα C3, C4 (Δεύτερη Βαθμίδα)
% rand(N, 4) παράγει ομοιόμορφη κατανομή στο (0,1)
FailTimes = -MTTF * log(rand(N, 4)); 

%% 3. Λογική Συστήματος (Cross-strapping 1)
% Το σύστημα είναι: (C1 OR C2) AND (C3 OR C4)
% Χρόνος βλάβης 1ης παράλληλης βαθμίδας = max(T_c1, T_c2)
% Χρόνος βλάβης 2ης παράλληλης βαθμίδας = max(T_c3, T_c4)
% Χρόνος βλάβης Συστήματος (σειρά) = min(T_block1, T_block2)

Block1_Life = max(FailTimes(:, 1), FailTimes(:, 2));
Block2_Life = max(FailTimes(:, 3), FailTimes(:, 4));
System_Life = min(Block1_Life, Block2_Life);

%% 4. Υπολογισμοί Αξιοπιστίας (Πειραματικά)

% α) Για τα εξαρτήματα στον χρόνο Tc
% Παίρνουμε την πρώτη στήλη ως δείγμα για "ένα εξάρτημα"
survived_components = sum(FailTimes(:, 1) > Tc);
R_comp_exp = survived_components / N;
lambda_comp_exp = -log(R_comp_exp) / Tc; % Λύνοντας το R = exp(-lambda*t)

% β) Για το σύστημα στον χρόνο Ts
survived_system = sum(System_Life > Ts);
R_sys_exp = survived_system / N;
% Ο ρυθμός αποτυχίας συστήματος δεν είναι σταθερός, αλλά υπολογίζουμε
% μια "ισοδύναμη" τιμή για τον χρόνο Ts
lambda_sys_exp = -log(R_sys_exp) / Ts; 

%% 5. Θεωρητικοί Υπολογισμοί (για σύγκριση)
% R_component = exp(-lambda * t)
R_comp_theo = exp(-lambda * Tc);

% R_system = (1 - (1-R)^2) * (1 - (1-R)^2) = [1 - (1 - exp(-t/MTTF))^2]^2
R_comp_at_Ts = exp(-lambda * Ts);
R_sys_theo = (1 - (1 - R_comp_at_Ts)^2)^2;

% --- Πρόσθετοι Υπολογισμοί για λ και MTTF ---

% 1. Για Εξαρτήματα
% Πειραματικό MTTF (Μέσος όρος των τυχαίων χρόνων που γεννήσαμε)
MTTF_exp_val = mean(FailTimes(:)); 
% Πειραματικό λ (από τον τύπο R = exp(-lambda*t) => lambda = -ln(R)/t)
lambda_comp_calculated = -log(R_comp_exp) / Tc;

% 2. Για Σύστημα
% Πειραματικό λ συστήματος (Ισοδύναμο λ στο χρόνο Ts)
lambda_sys_calculated = -log(R_sys_exp) / Ts;

fprintf('\n--- ΕΠΙΠΛΕΟΝ ΜΕΤΡΙΚΕΣ ---\n');
fprintf('Εξάρτημα MTTF: Θεωρ=%.2f, Πειρ=%.2f\n', MTTF, MTTF_exp_val);
fprintf('Εξάρτημα λ:    Θεωρ=%.4f, Πειρ=%.4f\n', lambda, lambda_comp_calculated);
fprintf('Σύστημα λ:     Θεωρ=%.4f, Πειρ=%.4f (στο χρόνο Ts)\n', -log(R_sys_theo)/Ts, lambda_sys_calculated);
%% 6. Εκτύπωση Αποτελεσμάτων
fprintf('\n--- Αποτελέσματα για ΕΞΑΡΤΗΜΑΤΑ (t = %d h) ---\n', Tc);
fprintf('Θεωρητική Αξιοπιστία:  %.4f\n', R_comp_theo);
fprintf('Πειραματική Αξιοπιστία: %.4f\n', R_comp_exp);
fprintf('Σφάλμα: %.2f%%\n', abs(R_comp_theo - R_comp_exp)/R_comp_theo * 100);

fprintf('\n--- Αποτελέσματα για ΣΥΣΤΗΜΑ (t = %d h) ---\n', Ts);
fprintf('Θεωρητική Αξιοπιστία:  %.4f\n', R_sys_theo);
fprintf('Πειραματική Αξιοπιστία: %.4f\n', R_sys_exp);
fprintf('Σφάλμα: %.2f%%\n', abs(R_sys_theo - R_sys_exp)/R_sys_theo * 100);

%% 7. Γραφική Παράσταση (Reliability vs Time)
t_plot = 0:0.5:100; % Χρονικός άξονας 0 έως 100 ώρες
R_sim_curve = zeros(size(t_plot));
R_theo_curve = zeros(size(t_plot));

for i = 1:length(t_plot)
    t = t_plot(i);
    % Πειραματική καμπύλη συστήματος
    R_sim_curve(i) = sum(System_Life > t) / N;
    
    % Θεωρητική καμπύλη συστήματος
    r_c = exp(-lambda * t);
    R_theo_curve(i) = (1 - (1 - r_c)^2)^2;
end

figure('Position', [100, 100, 800, 500]);
plot(t_plot, R_theo_curve, 'b-', 'LineWidth', 2); hold on;
plot(t_plot, R_sim_curve, 'r--', 'LineWidth', 2);
xline(Ts, 'k:', 'LineWidth', 1.5);
yline(R_sys_exp, 'k:', 'LineWidth', 1.5);
grid on;
legend('Θεωρητική Καμπύλη', 'Πειραματική (Monte Carlo)', ['Χρόνος Μελέτης Ts=' num2str(Ts)], 'Location', 'SouthWest');
xlabel('Χρόνος (ώρες)');
ylabel('Αξιοπιστία R(t)');
title('Αξιοπιστία Συστήματος Cross-strapping 1 (χωρίς επιδιόρθωση)');
% Αποθήκευση εικόνας για το LaTeX
saveas(gcf, 'reliability_plot.png');
fprintf('\nΤο διάγραμμα αποθηκεύτηκε ως "reliability_plot.png".\n');