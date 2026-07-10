function simulation1()
%% Simulation 1: The effect of convergence
% 使用论文 Table 3 的参数, 复现 Table 4 的结果

clc; close all;
rng(42);

N = 1000;
phi_c1 = 0.5;
eps_val = 1e-5;
lb = [0, 0, 0, 0];
ub = [4, 1, 2, 1];
n_wolves = 15;
max_iter = 150;
N_RUNS = 10;

%% 参考信号 (公式38)
yr = zeros(1, N);
for k = 1:N
    if k <= 300
        yr(k) = 0.5 * (-1)^round(k/500);
    elseif k <= 700
        yr(k) = 0.5*sin(k*pi/100) + 0.3*cos(k*pi/50);
    else
        yr(k) = 0.5 * (-1)^round(k/500);
    end
end

%% Step 1: 用论文 Table 3 的参数直接仿真
fprintf('============================================================\n');
fprintf('  Simulation 1: The effect of convergence\n');
fprintf('============================================================\n\n');

% Table 3 参数
Kp = 0.0898; Ti = 3.2169; Td = 0.4081;
params_mfac = [1, 1, 0.1, 0.6];
params_gwo  = [0.3878, 0.0056, 1, 0.4292];
params_igwo = [0.1111, 0.3474, 0.4936, 1];

fprintf('仿真中 (使用 Table 3 参数)...\n');
y_pid  = run_pid(yr, N, Kp, Ti, Td);
[y_mfac,  ~] = run_dmfac(yr, N, params_mfac, phi_c1, eps_val, false);
[y_gwo,   ~] = run_dmfac(yr, N, params_gwo,  phi_c1, eps_val, true);
[y_igwo,  ~] = run_dmfac(yr, N, params_igwo, phi_c1, eps_val, true);

%% Step 2: 跑 GWO/IGWO 优化, 只为出收敛曲线 (多次运行)
fprintf('GWO 优化中 (%d runs)...\n', N_RUNS);
best_curve_gwo = []; best_s_gwo = inf;
for r = 1:N_RUNS
    [~, s, c] = gwo_opt(yr, N, lb, ub, n_wolves, max_iter, ...
                         false, r*17+3, phi_c1, eps_val);
    if s < best_s_gwo
        best_s_gwo = s; best_curve_gwo = c;
    end
end
fprintf('  GWO  best fitness = %.4f\n', best_s_gwo);

fprintf('IGWO 优化中 (%d runs)...\n', N_RUNS);
best_curve_igwo = []; best_s_igwo = inf;
for r = 1:N_RUNS
    [~, s, c] = gwo_opt(yr, N, lb, ub, n_wolves, max_iter, ...
                          true, r*31+7, phi_c1, eps_val);
    if s < best_s_igwo
        best_s_igwo = s; best_curve_igwo = c;
    end
end
fprintf('  IGWO best fitness = %.4f\n', best_s_igwo);

%% Step 3: IAE / ITAE (复现 Table 4)
iae_pid  = sum(abs(yr - y_pid));
iae_mfac = sum(abs(yr - y_mfac));
iae_gwo  = sum(abs(yr - y_gwo));
iae_igwo = sum(abs(yr - y_igwo));

k_vec = 1:N;
itae_pid  = sum(k_vec .* abs(yr - y_pid));
itae_mfac = sum(k_vec .* abs(yr - y_mfac));
itae_gwo  = sum(k_vec .* abs(yr - y_gwo));
itae_igwo = sum(k_vec .* abs(yr - y_igwo));

fprintf('\n============================================================\n');
fprintf('  Table 4: Performance Comparison\n');
fprintf('============================================================\n');
fprintf('%-10s %12s %12s %12s %12s\n', 'Index', 'IGWO-DMFAC', 'GWO-DMFAC', 'MFAC', 'PID');
fprintf('%s\n', repmat('-', 1, 60));
fprintf('%-10s %12.3f %12.3f %12.3f %12.3f\n', 'IAE',  iae_igwo, iae_gwo, iae_mfac, iae_pid);
fprintf('%-10s %12.3f %12.3f %12.3f %12.3f\n', 'ITAE', itae_igwo, itae_gwo, itae_mfac, itae_pid);

%% Step 4: 绘图

% Figure 5: 全局跟踪
figure('Position', [50 50 900 500]);
hold on; grid on;
plot(1:N, yr,     'k--', 'LineWidth', 1.5, 'DisplayName', 'Expected Value');
plot(1:N, y_pid,  '-.', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.0, 'DisplayName', 'PID');
plot(1:N, y_mfac, '-.', 'Color', [0.90 0.32 0.00], 'LineWidth', 1.2, 'DisplayName', 'MFAC');
plot(1:N, y_gwo,  '-',  'Color', [0.08 0.40 0.75], 'LineWidth', 1.2, 'DisplayName', 'GWO-DMFAC');
plot(1:N, y_igwo, '-',  'Color', [0.73 0.11 0.11], 'LineWidth', 1.8, 'DisplayName', 'IGWO-DMFAC');
xlabel('Step (k)'); ylabel('Control Performance');
legend('Location', 'best', 'FontSize', 9);
xlim([0 N]);
saveas(gcf, 'fig5.fig');
saveas(gcf, 'fig5.png');

% Figure 6: 局部放大
figure('Position', [50 50 900 500]);
hold on; grid on;
idx = 280:400;
plot(idx, yr(idx),     'k--', 'LineWidth', 2,   'DisplayName', 'Expected Value');
plot(idx, y_pid(idx),  '-.', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.2, 'DisplayName', 'PID');
plot(idx, y_mfac(idx), '-.', 'Color', [0.90 0.32 0.00], 'LineWidth', 1.5, 'DisplayName', 'MFAC');
plot(idx, y_gwo(idx),  '-',  'Color', [0.08 0.40 0.75], 'LineWidth', 1.5, 'DisplayName', 'GWO-DMFAC');
plot(idx, y_igwo(idx), '-',  'Color', [0.73 0.11 0.11], 'LineWidth', 2.0, 'DisplayName', 'IGWO-DMFAC');
xlabel('Step (k)'); ylabel('Control Performance');
legend('Location', 'best', 'FontSize', 9);
saveas(gcf, 'fig6.fig');
saveas(gcf, 'fig6.png');

% Figure 7: 收敛曲线
figure('Position', [50 50 700 400]);
hold on; grid on;
plot(1:max_iter, best_curve_gwo,  '-', 'Color', [0.90 0.32 0.00], 'LineWidth', 1.8, 'DisplayName', 'GWO');
plot(1:max_iter, best_curve_igwo, '-', 'Color', [0.08 0.40 0.75], 'LineWidth', 1.8, 'DisplayName', 'IGWO');
xlabel('Iteration'); ylabel('Fitness');
legend('Location', 'northeast', 'FontSize', 10);
xlim([1 max_iter]);
saveas(gcf, 'fig7.fig');
saveas(gcf, 'fig7.png');

fprintf('\n[完成]\n');
end

%% ============================================================
%  子函数
%% ============================================================

function y_next = sys1(y, u, k)
    if k <= 500
        y_next = y(k) / (1 + y(k)^2) + u(k)^3;
    else
        if k < 3
            y_next = y(k) / (1 + y(k)^2) + u(k)^3;
        else
            num = y(k)*y(k-1)*y(k-2)*u(k-1)*(y(k-2)-1) + u(k);
            den = 1 + y(k-1)^2 + y(k-2)^2;
            y_next = num / den;
        end
    end
    y_next = max(-500, min(500, y_next));
end

function [y, u] = run_dmfac(yr, N, params, phi_c1, eps_val, use_desat)
    eta = params(1); mu = params(2); lam = params(3); rho = params(4);
    y = zeros(1, N+1);
    u = zeros(1, N+1);
    phi = phi_c1;

    for k = 2:N
        e_k = yr(k) - y(k);
        dy  = y(k) - y(k-1);
        if k >= 3, du = u(k-1) - u(k-2); else, du = u(k-1); end

        if abs(du) > eps_val
            phi = phi + eta * du / (mu + du^2) * (dy - phi * du);
        end
        if abs(phi) < eps_val || abs(du) <= eps_val || sign(phi) ~= sign(phi_c1)
            phi = phi_c1;
        end

        if use_desat
            u_up = 2; zeta_val = 0.5;
            if sign(e_k) ~= sign(y(k)) || u(k-1) < u_up
                theta = zeta_val * (u_up - u(k-1));
            else
                theta = 1;
            end
        else
            theta = 1;
        end

        u(k) = u(k-1) + rho * phi / (lam + abs(phi)^2) * e_k * theta;
        u(k) = max(-500, min(500, u(k)));
        y(k+1) = sys1(y, u, k);
    end
    y = y(1:N);
    u = u(1:N);
end

function y = run_pid(yr, N, Kp, Ti, Td)
    y = zeros(1, N+1);
    u = zeros(1, N+1);
    e_sum = 0;
    e_prev = 0;
    for k = 2:N
        e_k = yr(k) - y(k);
        e_sum = e_sum + e_k;
        u(k) = Kp * (e_k + e_sum / Ti + Td * (e_k - e_prev));
        u(k) = max(-500, min(500, u(k)));
        e_prev = e_k;
        y(k+1) = sys1(y, u, k);
    end
    y = y(1:N);
end

function [best_pos, best_score, curve] = gwo_opt(yr, N, lb, ub, ...
            n_wolves, max_iter, improved, seed, phi_c1, eps_val)
    rng(seed);
    dim = length(lb);
    positions = lb + (ub - lb) .* rand(n_wolves, dim);
    alpha_pos = zeros(1,dim); alpha_score = inf;
    beta_pos  = zeros(1,dim); beta_score  = inf;
    delta_pos = zeros(1,dim); delta_score = inf;
    curve = zeros(1, max_iter);

    for it = 1:max_iter
        for j = 1:n_wolves
            positions(j,:) = max(lb, min(ub, positions(j,:)));
            [y_sim, u_sim] = run_dmfac(yr, N, positions(j,:), phi_c1, eps_val, true);
            du_abs = abs(diff([0, u_sim]));
            f = sum(abs(yr - y_sim) + 10 * du_abs);
            if isnan(f) || isinf(f), f = 1e10; end

            if f < alpha_score
                delta_score = beta_score;  delta_pos = beta_pos;
                beta_score  = alpha_score; beta_pos  = alpha_pos;
                alpha_score = f;           alpha_pos = positions(j,:);
            elseif f < beta_score
                delta_score = beta_score;  delta_pos = beta_pos;
                beta_score  = f;           beta_pos  = positions(j,:);
            elseif f < delta_score
                delta_score = f;           delta_pos = positions(j,:);
            end
        end

        if improved
            a = 2 * (1 - sin(pi/2 * (it-1) / max_iter));
        else
            a = 2 - 2 * (it-1) / max_iter;
        end

        for j = 1:n_wolves
            for d = 1:dim
                r1=rand; r2=rand;
                X1 = alpha_pos(d) - (2*a*r1-a)*abs(2*r2*alpha_pos(d)-positions(j,d));
                r1=rand; r2=rand;
                X2 = beta_pos(d)  - (2*a*r1-a)*abs(2*r2*beta_pos(d)-positions(j,d));
                r1=rand; r2=rand;
                X3 = delta_pos(d) - (2*a*r1-a)*abs(2*r2*delta_pos(d)-positions(j,d));
                positions(j,d) = (X1+X2+X3)/3;
            end
            positions(j,:) = max(lb, min(ub, positions(j,:)));
        end
        curve(it) = alpha_score;

        if mod(it, 50) == 0
            fprintf('  iter %d/%d, best = %.4f\n', it, max_iter, alpha_score);
        end
    end
    best_pos = alpha_pos;
    best_score = alpha_score;
end
