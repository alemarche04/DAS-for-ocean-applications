function draw_lines_tx_plot(p1, p2, p3, p4)

% --- Line 1 ---
x1a = p1(1); y1a = p1(2);
x1b = p2(1); y1b = p2(2);

% --- Line 2 ---
x2a = p3(1); y2a = p3(2);
x2b = p4(1); y2b = p4(2);

% --- Get lines parameters (y = m*x + q) ---
m1 = (y1b - y1a) / (x1b - x1a);
q1 = y1a - m1 * x1a;

m2 = (y2b - y2a) / (x2b - x2a);
q2 = y2a - m2 * x2a;

% --- Point of interception ---
x_int = (q2 - q1) / (m1 - m2);
y_int = m1 * x_int + q1;
fprintf('Point of interception: Time = %.2f s, Distance = %.2f m\n', x_int, y_int);

% --- Plot ---
x_range = xlim;

% Line 1
y1_start = m1*x_range(1) + q1;
y1_end   = m1*x_range(2) + q1;

% Line 2
y2_start = m2*x_range(1) + q2;
y2_end   = m2*x_range(2) + q2;

plot(x_range, [y1_start, y1_end], 'w--', 'LineWidth', 1)
plot(x_range, [y2_start, y2_end], 'w--', 'LineWidth', 1)

end